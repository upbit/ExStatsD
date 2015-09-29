defmodule ExStatsD do
  use ExActor.GenServer, export: :exstatsd

  @statsd_ets_name        :exstatsd
  @default_statsd_host    :'127.0.0.1'
  @default_statsd_port    8125
  @default_statsd_timeout 5000

  ## Counting: increment/1, decrement/1
  def increment(key), do: update_count(key, 1)
  def decrement(key), do: update_count(key, -1)

  # Update counter plus with value
  def update_count(key, value) do
    case :ets.lookup(@statsd_ets_name, key) do
      [] -> :ets.insert(@statsd_ets_name, {key, value}); value
      _ -> :ets.update_counter(@statsd_ets_name, key, value)
    end
  end

  ## Gauges: gauge/2
  defcast gauge(key, value), state: %{:socket => socket, :host => host, :port => port} = state do
    build_message(key, value, :gauges) |> send_statsd_message(socket, host, port)
    new_state(state)
  end

  ## Timing: timing/2
  defcast timing(key, value_ms), state: %{:socket => socket, :host => host, :port => port} = state do
    build_message(key, value_ms, :timing) |> send_statsd_message(socket, host, port)
    new_state(state)
  end


  ##
  ##  GenServer functions
  ##

  defstart start_link, gen_server_opts: [name: :exstatsd] do
    @statsd_ets_name = :ets.new(@statsd_ets_name, [:named_table, :set, :public])
    {:ok, timer_ref} = :timer.send_interval(config_timeout, :statsd_timeout)
    {:ok, socket} = :gen_udp.open(0, [:binary])
    initial_state(%{:socket => socket, :host => config_host, :port => config_port, :timer_ref => timer_ref})
  end

  # Send ETS counter to StatsD
  defhandleinfo :statsd_timeout, state: %{:socket => socket, :host => host, :port => port} do
    :ets.foldl(fn({key, _}, nil) ->
      counter = :ets.update_counter(@statsd_ets_name, key, 0)
      case counter do
        0 -> :nothing_to_do
        _ ->
          # set key counter to 0 and send last counter to StatsD
          :ets.update_counter(@statsd_ets_name, key, {2, 1, counter, 0})
          build_message(key, counter, :counting) |> send_statsd_message(socket, host, port)
      end
      nil
    end, nil, @statsd_ets_name)
    noreply
  end

  defcast stop, state: %{:socket => socket, :timer_ref => timer_ref} do
    true = :ets.delete(@statsd_ets_name)
    {:ok, _} = :timer.cancel(timer_ref)
    :gen_udp.close(socket)
    stop_server(:normal)
  end

  # priv
  def config(key) do
    Application.get_env(:exstatsd, key)
  end

  # Add following lines to your config/*.exs to config ElixirStatsd
  #
  #     config :exstatsd,
  #       host: "127.0.0.1",
  #       port: 8125,
  #       timeout: 5000
  defp config_host do
    case config(:host) do
      nil -> @default_statsd_host
      host -> host |> to_string |> String.to_atom
    end
  end
  defp config_port, do: config(:port) || @default_statsd_port
  defp config_timeout, do: config(:timeout) || @default_statsd_timeout

  # https://github.com/etsy/statsd/blob/master/docs/metric_types.md
  defp build_message(key, value, :counting), do: do_build_message(key, value, "c")
  defp build_message(key, value, :gauges), do: do_build_message(key, value, "g")
  defp build_message(key, value, :timing), do: do_build_message(key, value, "ms")
  defp build_message(key, value, :sets), do: do_build_message(key, value, "s")
  #defp build_message(key, value, :sampling, sampling), do: do_build_message(key, value, "c|@#{sampling}")
  #defp build_message(key, value, :timing, threshold), do: do_build_message(key, value, "ms|@#{threshold}")
  defp do_build_message(key, value, suffix), do: "#{to_string(key)}:#{to_string(value)}|#{suffix}"

  # Send udp packet to StatsD: https://github.com/etsy/statsd
  defp send_statsd_message(message, socket, host, port) do
    case :gen_udp.send(socket, host, port, message) do
      :ok -> :ok
      error -> error
    end
  end
end
