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
* [An Adventure in Distributed Programming](https://slides.com/qqwy/an-adventure-in-distributed-programming#/)
  * Open-source [chat application](https://github.com/ResiliaDev/Planga/)
  * Intro into distributed systems (CAP, byzantine fault). Rundown of [Mnesia](http://erlang.org/doc/man/mnesia.html), [Cassandra](http://cassandra.apache.org/), [CouchDB](http://couchdb.apache.org/) and [Riak](https://riak.com/). They are working on [Ecto adapter for Riak](https://github.com/Qqwy/elixir_riak_ecto3).
