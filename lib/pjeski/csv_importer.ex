defmodule Pjeski.CsvImporter do
  def run!(subscription, path) do
    stream = path |> File.stream! |> CSV.decode

    headers = Enum.take(stream, 1)
    records_stream = Stream.drop(stream, 1)

    Enum.map(records_stream, fn {:ok, raw_fields_list} -> IO.inspect raw_fields end)
  end
end
