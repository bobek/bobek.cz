---
title: Experiments with NATS
subtitle: replacing service mesh with NATS.io
category: computers
tags: elixir, nats
date: 2019-10-16
published: false
---

I came across [NATS](https://nats.io) about 2 years ago, when listening to an interview with Derek Collison (original author of NATS) and rediscovered it later this year via [Software Engineering Radio Podcast](https://www.se-radio.net/2019/06/episode-369-derek-collison-on-messaging-systems-and-nats/). I didn't have a project where I could give NATS a spin. Recently I have moved to [a new venture](https://dtone.egineering), where we are designing distributed systems from scratch. That presented an opportunity to start playing with NATS. Also project just release a version [`2.0`](https://nats-io.github.io/docs/whats_new/whats_new_20.html) (version at time of writing this article is `2.1.0`). Timing was perfect.



I have been always doing micro-service deployments with fairly standard topology. Where you have an API gateway or router in role of ingress controller. Gateway applies certain policies (e.g. verifies access tokens) and then routes request to appropriate service instance. APIs are typically JSON based with `http` being a transport of choice. Services are talking to each other in very similar fashion, frequently reusing parts of the infrastructure. Alternatively service meshes are used to facilitate communication among services. One will introduce some sort of message queue very quickly to handle asynchronous messages.

I was intrigued if at lest some of the functionality of service mashes (such as [linkerd](https://linkerd.io/) or [Istio](https://www.istio.io/)) cannot be actually realized with NATS instead of convoluted deployment, typically based on Kubernetes. Also Supercluster and geo-awareness seem really interesting. Let's start with list of some functionalities one would like to have from the communication infrastructure.

- Service Discovery and topology management of the actual mesh (what are nodes forming mesh, handling their failures, support routing over high latency links)
- Service Discovery of service (where they are, how to reach to them)
- Load Balancing (keeping load spread uniformly, some may need session stickiness)
- Observability (tracing, metrics, logging)
- Flow management (circuit-breakers, timeouts and related handling of retries, rate limiting, traffic mirroring, node draining)
- Security (transport encryption, ACLs between services)
- API and ability to automate tasks like deployments (blue/green or canaries) and testing (e.g. fault injection)

Some features can be implemented at different places. For example circuit breaker patter can be functionality of the service mesh as well as the client library (like in case of [Netflix/Hystrix](https://github.com/Netflix/Hystrix/wiki/How-it-Works#CircuitBreaker)).

## What is NATS?

NATS describes itself as follows

> NATS.io is a simple, secure and high performance open source messaging system for cloud native applications, IoT messaging, and microservices architectures.

Core paradigm is a classical **pub/sub** with messages being sent to topics called `subjects` in NATS terminology. Message is delivered to all receivers. Receivers can be grouped into `queue group`s, where message is delivered to at-most-one receiver. Core NATS (sometimes referred to as `nats-server`) is *at-most-once* delivery. That is basically the as making an HTTP request without having retries implemented by the delivery mesh. There is also a [NATS streaming](https://nats-io.github.io/docs/nats_streaming/intro.html) project, which is built on the top of NATS. It offers *at-least-once* delivery as it implements acknowledgment scheme and persist messages on transit.

What is really interesting is that NATS also implements **request/response** paradigm forming. A request is published on a given subject with a reply subject. Receiver providing service (referred to as responder) listen on that subject and send responses to the reply subject. Reply subjects are usually a subject prefixed with `_INBOX` that will be directed back to the originator of the request. All this regardless of location of either party.

## Test setup

Experiments in this article have been done on my laptop over loopback interface. So they are not really representative from the networking point of view. I am running 3 instances of `nats-server`, which forms a cluster:

```bash
nats-server -D -p 4222 -cluster nats://localhost:6222 -m 8222
nats-server -D -p 4333 -cluster nats://localhost:6333 -routes nats://localhost:6222 -m 8333
nats-server -D -p 4444 -cluster nats://localhost:6444 -routes nats://localhost:6222 -m 8444
```

First server (listening on port `4222`) is used as a rendezvous point, which bootstraps the other two with information about each other. `-m` specifies port on which `nats-server` exposes http server with various metrics, which can be scraped. This allows applications like [`nats-top`](https://github.com/nats-io/nats-top) to work.


---

```
17:46:05.917 [error] GenServer #PID<0.206.0> terminating
** (stop) "connection closed"
Last message: {:tcp_closed, #Port<0.11>}
State: %{connection_settings: %{connection_timeout: 3000, host: 'localhost', port: 4222, ssl_opts: [], tcp_opts: [:binary], tls: false}, next_sid: 1, parser: %Gnat.Parsec{partial: nil}, receivers: %{0 => %{recipient: #PID<0.206.0>, unsub_after: :infinity}}, request_inbox_prefix: "_INBOX.IhJ8TddgH0UqcTs2.", request_receivers: %{"_INBOX.IhJ8TddgH0UqcTs2.ex04Vl0Ko8OuNMJc" => #PID<0.201.0>}, socket: #Port<0.11>}
```
