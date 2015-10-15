# Use [CargoSense/ex_statsd](https://github.com/CargoSense/ex_statsd) instead. Package exstatsd is abandoned

------------------------

# ExStatsD
An Elixir ports client for [StatsD](https://github.com/etsy/statsd)

## Installation

First, add ExStatsD to your mix.exs application and dependencies:

~~~elixir
def application do
  [applications: [:exstatsd]]
end

def deps do
  [{:exstatsd, "~> 0.1.5"}]
end
~~~

Then, update your dependencies:

~~~bash
$ mix deps.get
~~~

## Usage

1. Counting API: `ExStatsD.increment("foo.bar")` / `ExStatsD.decrement("foo.bar")`
2. Gauges API: `ExStatsD.gauge(:atom_key, 999)`
3. Timing API: `ExStatsD.timing("time_in_ms", 350)`

## Config

Add following lines to your `config/#{Mix.env}.exs`, can override default configs:

~~~elixir
config :exstatsd,
  host: "127.0.0.1",
  port: 8125,
  timeout: 5000
~~~

* timeout: Change the report interval for Counting API, default is 5s

## TO-DO

* [x] Support Counting API
* [x] Support Gauges API
* [x] Support Timing API
* [ ] Support Sampling
