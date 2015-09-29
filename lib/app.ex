defmodule ExStatsD.App do
  use Application
  def start(_type, _args), do: ExStatsD.App.Sup.start_link

  defmodule Sup do
    use Supervisor
    def start_link, do: Supervisor.start_link(__MODULE__, [])

    def init([]) do
      children = [
        worker(ExStatsD, [])
      ]
      supervise(children, strategy: :one_for_one)
    end
  end
end
