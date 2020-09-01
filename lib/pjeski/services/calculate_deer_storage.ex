defmodule Pjeski.Services.CalculateDeerStorage do
  @uploaded_files_dir File.cwd! <> "/uploaded_files"

  def run! do
    stats = Enum.reduce(subscriptions_ids(), %{}, fn subscription_id, results ->
      id = String.to_integer(subscription_id)

      Map.merge(results, %{id => calculate_subscription_directory(subscription_id)})
    end)

    compact_stats_to_subscription_level(stats)
  end

  defp subscriptions_ids do
    case File.ls(@uploaded_files_dir) do
      {:ok, subscriptions_ids} -> subscriptions_ids
      {:error, :enoent} -> []
    end
  end

  defp calculate_subscription_directory(subscription_id) do
    calculate_records_directories(
      subscription_id,
      File.ls!(@uploaded_files_dir <> "/#{subscription_id}")
    )
  end

  defp calculate_records_directories(subscription_id, records_ids) do
    Enum.reduce(records_ids, %{}, fn record_id, results ->
      id = String.to_integer(record_id)
      files = File.ls!(@uploaded_files_dir <> "/#{subscription_id}/#{record_id}")
      total_kilobytes = Enum.map(files, fn filename -> kilobytes(subscription_id, record_id, filename) end) |> Enum.sum
      total_files = length(files)

      Map.merge(results, %{id => %{total_files: total_files, total_kilobytes: total_kilobytes}})
    end)
  end

  defp kilobytes(subscription_id, record_id, filename) do
    bytes = File.stat!(@uploaded_files_dir <> "/#{subscription_id}/#{record_id}/#{filename}").size

    ceil(bytes / 1024)
  end

  defp compact_stats_to_subscription_level(all_stats) do
    Enum.map(all_stats, fn {subscription_id, stats} ->
      total_stats = Enum.reduce(stats, %{files: 0, kilobytes: 0}, fn {_id, record_stats}, %{files: total_subscription_files, kilobytes: total_subscription_kilobytes} ->
        %{
          files: total_subscription_files + record_stats.total_files,
          kilobytes: total_subscription_kilobytes + record_stats.total_kilobytes
        }
      end)

      [subscription_id, total_stats]
    end)
  end
end
