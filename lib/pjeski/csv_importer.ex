defmodule Pjeski.CsvImporter do
  require Logger

  import Ecto.Query, warn: false
  import PjeskiWeb.Gettext
  import Pjeski.Subscriptions.Subscription, only: [append_table: 3, deer_changeset: 2]

  alias Phoenix.PubSub
  alias Pjeski.Subscriptions
  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.Repo

  def run!(pid, subscription, user, path, filename, random_name, remove_file? \\ false) do
    Gettext.put_locale(user.locale)

    log_info pid, gettext("Starting importer for file named '%{filename}'...", filename: filename)

    stream = path |> File.stream! |> CSV.decode
    assigns = %{caller_pid: pid, subscription: subscription, user: user, records_stream: Stream.drop(stream, 1), filename: filename, random_name: random_name}

    initial_map = case Enum.take(stream, 1) do
                [ok: headers] -> {:ok, Map.merge(assigns, %{headers: headers})}
                [error: message] -> {:error, message}
              end

    Repo.transaction(fn ->
      result = initial_map
      |> lock_and_update_subscription
      |> prepare_table_data
      |> prepare_records
      |> insert_records_and_notify_subscribers
      |> rename_subscription_table_to_filename

      case result do
        {:ok, _} ->
          log_info pid, gettext("Successfully imported '%{filename}'", filename: filename)

          :ok
        {:error, msg} ->
          log_error(pid, filename, msg)
          Repo.rollback(msg)
      end
    end, timeout: 100_000)
  after
    if remove_file?, do: File.rm!(path)
  end

  defp lock_and_update_subscription({:error, _} = result), do: result
  defp lock_and_update_subscription({:ok, %{subscription: %{id: subscription_id}, headers: headers, random_name: random_name} = assigns}) do
    subscription_changeset = Repo.one!(from s in Subscription, where: s.id == ^subscription_id, lock: "FOR UPDATE")
    |> change_subscription
    |> append_table(random_name, headers)

    case subscription_changeset.valid? do
      true -> {:ok, Map.merge(assigns, %{subscription: Repo.update!(subscription_changeset)})}
      false -> {:error, subscription_changeset.errors}
    end
  end

  defp prepare_table_data({:error, _} = result), do: result
  defp prepare_table_data({:ok, %{subscription: %{deer_tables: deer_tables}, random_name: random_name} = assigns}) do
    table = Enum.find(deer_tables, fn %{name: name} -> name == random_name end)
    ordered_ids = table.deer_columns |> Enum.map(fn dc -> dc.id end)

    {:ok, Map.merge(assigns, %{table_id: table.id, columns_ids: ordered_ids})}
  end

  defp prepare_records({:error, _} = result), do: result
  defp prepare_records({:ok, %{records_stream: stream, subscription: %{deer_records_per_table_limit: limit} = subscription, user: user, table_id: table_id, columns_ids: columns_ids} = assigns}) do
    timestamp = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    {result, _count} = Enum.reduce(stream, {[], 0}, fn item, {list, count} ->
      if count < limit do
        case item do
          {:ok, fields_list} ->
            case prepare_record_map(fields_list, columns_ids, table_id, subscription.id, user.id, timestamp) do
              {:ok, attrs} -> {list ++ [attrs], count + 1}
              {:error, errors} -> throw gettext("Validation failed: %{errors}", errors: errors)
            end
          {:error, message} -> throw gettext("CSV parser error: %{message}", message: message)
        end
      else
        throw gettext("Too many records: Limit is %{limit}", limit: limit)
      end
    end)

    {:ok, Map.merge(assigns, %{records_maps: result})}
  catch
    err -> {:error, err}
  end


  defp insert_records_and_notify_subscribers({:error, _} = result), do: result
  defp insert_records_and_notify_subscribers({:ok, %{caller_pid: pid, records_maps: records_maps, subscription: subscription, table_id: table_id, filename: filename} = assigns}) do
    maps_chunks = Enum.chunk_every(records_maps, 1000)

    total_inserted_count = Enum.reduce(maps_chunks, 0, fn chunk, acc ->
      {inserted_count, _} = Repo.insert_all("deer_records", chunk)

      acc + inserted_count
    end)

    log_info pid, gettext("Inserted %{count} records from file '%{filename}'", count: total_inserted_count, filename: filename)

    GenServer.cast(DeerCache.RecordsCountsCache, {:increment, table_id, total_inserted_count})
    PubSub.broadcast Pjeski.PubSub, "subscription:#{subscription.id}", {:subscription_updated, subscription}

    {:ok, assigns}
  end

  defp rename_subscription_table_to_filename({:error, _} = result), do: result
  defp rename_subscription_table_to_filename({:ok, %{subscription: %{deer_tables: deer_tables} = subscription, filename: filename, random_name: random_name} = assigns}) do
    target_table_id = Enum.find(deer_tables, fn dt -> dt.name == random_name end).id

    name = case String.length(filename) do
                 len when len > 50 -> String.slice(filename, 0..46) <> "..." # 50 characters
                 _len -> filename # LV will not allow files without .csv extension, so skip handling files with name having less than 3 characters
               end

    {:ok, new_subscription} = Subscriptions.update_deer_table!(subscription, target_table_id, %{name: name})

    {:ok, Map.merge(assigns, %{subscription: new_subscription})}
  end

  def prepare_record_map(fields_list, columns_ids, table_id, subscription_id, user_id, timestamp) do
    deer_fields = Enum.zip(fields_list, columns_ids) |> Enum.map(fn {content, column_id} ->
      if String.length(content) > 200, do: throw "Found field with more than 200 characters"

      %{content: content, deer_column_id: column_id}
    end)

    {:ok, %{deer_table_id: table_id,
            deer_fields: deer_fields,
            subscription_id: subscription_id,
            inserted_at: timestamp,
            updated_at: timestamp,
            created_by_user_id: user_id,
            updated_by_user_id: user_id}}
  catch
    err -> {:error, err}
  end

  defp change_subscription(subscription), do: deer_changeset(subscription, %{})

  defp log_error(pid, filename, msg) when is_binary(msg) do
    if unquote(Mix.env != :test), do: Logger.error "CSV import #{filename}: " <> msg
    GenServer.cast(pid, {:csv_importer_error, "#{filename}: #{msg}"})
  end

  defp log_error(pid, filename, [validation_error | _]) when is_tuple(validation_error) do
    if unquote(Mix.env != :test), do: Logger.error "CSV import #{filename}: Subscription limits validation failed"
    GenServer.cast(pid, {:csv_importer_error, gettext("Your database limits don't allow to import file named '%{filename}'.", filename: filename)})
  end

  defp log_error(pid, filename, _) do
    if unquote(Mix.env != :test), do: Logger.error "CSV import #{filename}: Unknown error"
    GenServer.cast(pid, {:csv_importer_error, gettext("Unknown error occurred when importing '%{filename}'.", filename: filename)})
  end

  defp log_info(pid, msg) do
    if unquote(Mix.env != :test), do: Logger.info(msg)
    GenServer.cast(pid, {:csv_importer_info, msg})
  end
end
