defmodule DeerStorageWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      {DeerStorageWeb.MetricsStorage, metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Time Metrics
      summary("deer_storage.repo.query.total_time", unit: {:native, :millisecond}),
      summary("deer_storage.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("deer_storage.repo.query.query_time", unit: {:native, :millisecond}),
      summary("deer_storage.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("deer_storage.repo.query.idle_time", unit: {:native, :millisecond}),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # LV
      summary("phoenix.live_view.mount.stop.duration",
        tags: [:view],
        tag_values: fn metadata ->
          Map.put(metadata, :view, "#{inspect(metadata.socket.view)}")
        end,
        unit: {:native, :millisecond}
      ),
      summary("phoenix.live_view.handle_params.stop.duration",
        tags: [:view],
        tag_values: fn metadata ->
          Map.put(metadata, :view, "#{inspect(metadata.socket.view)}")
        end,
        unit: {:native, :millisecond}
      ),
      summary("phoenix.live_view.handle_event.stop.duration",
        tags: [:view, :event],
        tag_values: fn metadata ->
          Map.put(metadata, :view, "#{inspect(metadata.socket.view)}")
        end,
        unit: {:native, :millisecond}
      )
    ]
  end

  defp periodic_measurements do
    []
  end
end
