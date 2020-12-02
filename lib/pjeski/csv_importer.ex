defmodule Pjeski.CsvImporter do
  import Ecto.Query, warn: false
  import Pjeski.Subscriptions.Subscription, only: [append_table: 3, deer_changeset: 2]

  alias Phoenix.PubSub
  alias Pjeski.Subscriptions
  alias Pjeski.Subscriptions.Subscription
  alias Pjeski.DeerRecords.DeerRecord
  alias Pjeski.Repo

  def run!(subscription, user, path, filename) do
    stream = path |> File.stream! |> CSV.decode
    [ok: headers] = Enum.take(stream, 1)

    Repo.transaction(fn ->
      result = %{subscription: subscription, user: user, headers: headers, records_stream: Stream.drop(stream, 1), filename: filename}
      |> generate_random_name_for_transaction
      |> lock_and_update_subscription
      |> prepare_table_data
      |> consume_records
      |> insert_records_and_notify_subscribers
      |> rename_subscription_table_to_filename

      case result do
        {:ok, _} -> :ok
        {:error, msg} -> Repo.rollback(msg)
      end
    end)

    # broadcast count for new table's records // TODO: CHECK IF TRANSACTION IS VISIBLE
  end

  defp generate_random_name_for_transaction(assigns), do: Map.merge(assigns, %{random_name: :crypto.strong_rand_bytes(20) |> Base.url_encode64 |> binary_part(0, 20)})

  defp lock_and_update_subscription(%{subscription: %{id: subscription_id}, headers: headers, random_name: random_name} = assigns) do
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

  defp consume_records({:error, _} = result), do: result
  defp consume_records({:ok, %{records_stream: stream, subscription: %{deer_records_per_table_limit: limit} = subscription, user: user, table_id: table_id, columns_ids: columns_ids} = assigns}) do
    timestamp = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    {result, _count} = Enum.reduce(stream, {[], 0}, fn item, {list, count} ->
      if count < limit do
        case item do
          {:ok, fields_list} ->
            case validate_and_return_raw_map(fields_list, columns_ids, table_id, subscription, user.id, timestamp) do
              {:ok, attrs} -> {list ++ [attrs], count + 1}
              {:error, errors} -> throw "Validation failed: #{errors}"
            end
          {:error, message} -> throw "CSV parser error: #{message}"
        end
      else
        throw "Too many records: Limit is #{limit}"
      end
    end)

    {:ok, Map.merge(assigns, %{records_maps: result})}
  catch
    err -> {:error, err}
  end


  defp insert_records_and_notify_subscribers({:error, _} = result), do: result
  defp insert_records_and_notify_subscribers({:ok, %{records_maps: records_maps, subscription: subscription, table_id: table_id} = assigns}) do
    maps_chunks = Enum.chunk_every(records_maps, 1000)

    total_inserted_count = Enum.reduce(maps_chunks, 0, fn chunk, acc ->
      {inserted_count, _} = Repo.insert_all("deer_records", chunk)

      acc + inserted_count
    end)

    GenServer.cast(DeerCache.RecordsCountsCache, {:increment, table_id, total_inserted_count})
    PubSub.broadcast Pjeski.PubSub, "subscription:#{subscription.id}", {:subscription_updated, subscription}

    {:ok, assigns}
  end

  defp rename_subscription_table_to_filename({:error, _} = result), do: result
  defp rename_subscription_table_to_filename({:ok, %{subscription: %{deer_tables: deer_tables} = subscription, filename: filename, random_name: random_name} = assigns}) do
    target_table_id = Enum.find(deer_tables, fn dt -> dt.name == random_name end).id
    {:ok, new_subscription} = Subscriptions.update_deer_table!(subscription, target_table_id, %{name: filename})

    {:ok, Map.merge(assigns, %{subscription: new_subscription})}
  end

  def validate_and_return_raw_map(fields_list, columns_ids, table_id, subscription, user_id, timestamp) do
    deer_fields = Enum.zip(fields_list, columns_ids) |> Enum.map(fn {content, column_id} -> %{content: content, deer_column_id: column_id} end)
    attrs = %{deer_table_id: table_id, deer_fields: deer_fields, subscription_id: subscription.id, inserted_at: timestamp, updated_at: timestamp, created_by_user_id: user_id, updated_by_user_id: user_id}

    changeset = DeerRecord.changeset(%DeerRecord{}, attrs, subscription)

    case changeset.valid? do
      true -> {:ok, attrs}
      false -> {:error, changeset.errors}
    end
  end

  defp change_subscription(subscription), do: deer_changeset(subscription, %{})
end
