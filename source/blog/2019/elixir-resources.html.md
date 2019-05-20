---
title: Elixir resources
subtitle: to help with transition to Elixir
category: hacking
tags: linux
date: 2019-05-17
---

We are planning introducing Elixir into our toolbox. This page summarizes key resources we have user / are using for learning Elixir and pushing it to production. Feel free to propose changes via [pull-request](https://github.com/bobek/bobek.cz/blob/master/source/blog/2019/elixir-resources.html.md).

# Deployment & Containers/Kubernetes

Motivation is to be able to deploy apps leveraging OTP to k8s (containers). Especially important piece of having a support for OTP is to be able to use things like long-running `GenServer` processes, migrate state etc.

## Main resources

* [Elixir OTP applications on Kubernetes](https://engineering.dollarshaveclub.com/elixir-otp-applications-on-kubernetes-9944636b8609)
* [ElixirConf 2018 - Docker and OTP Friends or Foes - Daniel Azuma](https://www.youtube.com/watch?v=nLApFANtkHs)
  * Source code is [available](https://github.com/ElixirSeattle/tanx)
  * Support [blogpost](https://daniel-azuma.com/articles/talks/elixirconf-2018)
* [Graceful shutdown on Kubernetes with signals & Erlang OTP 20](https://medium.com/@ellispritchard/graceful-shutdown-on-kubernetes-with-signals-erlang-otp-20-a22325e8ae98)
* Completely alternative approach with [Lasp](https://lasp-lang.readme.io)

## Key components

* **Establishing Erlang cluster** - [libcluster](https://hex.pm/packages/libcluster)
  * [Connecting Elixir Nodes with libcluster, locally and on Kubernetes](https://www.poeticoding.com/connecting-elixir-nodes-with-libcluster-locally-and-on-kubernetes/)
  * [graceful-stop library](https://github.com/botsquad/graceful_stop)
  * [k8s traffic endpoint (Plug)](https://github.com/Financial-Times/k8s_traffic_plug)
* **Moving/Restarting/Monitoring Processes** - [Horde Supervisor](https://hexdocs.pm/horde/Horde.Supervisor.html)
  * Nice intro articles - [Introducing Horde — a distributed Supervisor in Elixir](https://medium.com/@derek.kraan2/introducing-horde-a-distributed-supervisor-in-elixir-4be3259cc142) and [Getting started with Horde’s distributed Supervisor / Registry](https://medium.com/@derek.kraan2/getting-started-with-hordes-distributed-supervisor-registry-f3017208e1ce)
  * [main repo](https://github.com/derekkraan/horde)
* **Sharing process state / date across nodes** - [CRDT](https://github.com/derekkraan/delta_crdt_ex)
* **Service discovery** - [Horde Registry](https://hexdocs.pm/horde/Horde.Registry.html)

# Distributed systems / data-types

* [Using Rust to Scale Elixir for 11 Million Concurrent Users](https://blog.discordapp.com/using-rust-to-scale-elixir-for-11-million-concurrent-users-c6f19fc029d3)
  * Rust implementation of `SortedSet` which is then used by Elixir backend
* [An Adventure in Distributed Programming](https://slides.com/qqwy/an-adventure-in-distributed-programming#/) by Wiebe-Marten Wijnja
  * Open-source [chat application](https://github.com/ResiliaDev/Planga/)
  * Intro into distributed systems (CAP, byzantine fault). Rundown of [Mnesia](http://erlang.org/doc/man/mnesia.html), [Cassandra](http://cassandra.apache.org/), [CouchDB](http://couchdb.apache.org/) and [Riak](https://riak.com/). They are working on [Ecto adapter for Riak](https://github.com/Qqwy/elixir_riak_ecto3).
* [Building Resilient Systems with Stacking](https://speakerdeck.com/keathley/building-resilient-elixir-systems) by Chris Keathley
  * Recording from [ElixrConf EU 2019](https://www.youtube.com/watch?v=lg7M0h9eoug)
    * Overview of techniques which helps in building more resilient systems. Refers to [How Complex Systems Fail](https://web.mit.edu/2.75/resources/random/How%20Complex%20Systems%20Fail.pdf)
    * **Circuit brakers**: Recommended implementation is [fuse](https://github.com/jlouis/fuse).
    * **Configuration:** Should avoid use of `mix configs`, instead he pointed to his project [Vapor](https://github.com/keathley/vapor). Example of usage (from the talk, chech project for other one):

        ```elixir
        defmodule Jenga.Application do
          use Application

          def start(_type, _args) do
            config = [
                port: "PORT",
                db_url: "DB_URL",
            ]

            children = [
                {Jenga.Config, config},
            ]

            opts = [strategy: :one_for_one, name: Jenga.Supervisor]
            Supervisor.start_link(children, opts)
          end
        end

        defmodule Jenga.Config do
            use GenServer

            def start_link(desired_config) do
                GenServer.start_link(__MODULE__, desired_config, name: __MODULE__)
            end

            def init(desired) do
                :jenga_config = :ets.new(:jenga_config, [:set, :protected, :named_table])
                case load_config(:jenga_config, desired) do
                :ok ->
                    {:ok, %{table: :jenga_config, desired: desired}}
                :error ->
                    {:stop, :could_not_load_config}
                end
            end

            defp load_config(table, config, retry_count \\ 0)
            defp load_config(_table, [], _), do: :ok
            defp load_config(_table, _, 10), do: :error
            defp load_config(table, [{k, v} | tail], retry_count) do
                case System.get_env(v) do
                nil ->
                    load_config(table, [{k, v} | tail], retry_count + 1)
                value ->
                    :ets.insert(table, {k, value})
                    load_config(table, tail, retry_count)
                end
            end
        end
        ```

    * **Monitoring:** you can use Erlang's [alarms](http://erlang.org/doc/man/alarm_handler.html). Example from the talk, which takes database as dependency and if not reachable will raise an alarm:

        ```elixir
        defmodule Jenga.Database.Watchdog do
        use GenServer

        def init(:ok) do
            schedule_check()
            {:ok, %{status: :degraded, passing_checks: 0}}
        end

        def handle_info(:check_db, state) do
            status = Jenga.Database.check_status()
            state = change_state(status, state)
            schedule_check()
            {:noreply, state}
        end

        defp change_state(result, %{status: status, passing_checks: count}) do
            case {result, status, count} do
            {:ok, :connected, count} ->
                if count == 3 do
                :alarm_handler.clear_alarm(@alarm_id)
                end
                %{status: :connected, passing_checks: count + 1}

            {:ok, :degraded, _} ->
                %{status: :connected, passing_checks: 0}

            {:error, :connected, _} ->
                :alarm_handler.set_alarm({@alarm_id, "We cannot connect to the database”})
                %{status: :degraded, passing_checks: 0}
                {:error, :degraded, _} ->
                    %{status: :degraded, passing_checks: 0}
            end
        end
        end
        ```

        Then  alarm handle can be added:

        ```elixir
        defmodule Jenga.Application do
          use Application

          def start(_type, _args) do
            config = [
                port: "PORT",
                db_url: "DB_URL",
            ]

            :gen_event.swap_handler(
                :alarm_handler,
                {:alarm_handler, :swap},
                {Jenga.AlarmHandler, :ok}
            )

            children = [
                {Jenga.Config, config},
                Jenga.Database.Supervisor,
            ]

            opts = [strategy: :one_for_one, name: Jenga.Supervisor]
            Supervisor.start_link(children, opts)
          end
        end

        defmodule Jenga.AlarmHandler do
          require Logger

          def init({:ok, {:alarm_handler, _old_alarms}}) do
            Logger.info("Installing alarm handler")
            {:ok %{}}
          end

          def handle_event({:set_alarm, :database_disconnected}, alarms) do
            # Do something with the alarm rising (e.g. notify monitoring)
            Logger.error("Database connection lost")
            {:ok, alarms}
          end

          def handle_event({:clear_alarm, :database_disconnected}, alarms) do
            # Do something with the alarm being cleared (e.g. notify monitoring)
            Logger.error("Database connection recovered")
            {:ok, alarms}
          end

          def handle_event(event, state) do
            Logger.info("Unhandled alarm event: #{inspect(event)}")
            {:ok, state}
          end
        end

        ```