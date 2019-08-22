# RTC Bee
The RTC Bee is a command-line program that runs a subscription "attack" on a server. One *RTC Bee* can have N *Bullets* (or stingers) that are fired concurrently.

* [Requirements](#build-requirements)
* [Building](#building)
* [Attacking](#attacking)
* [Notes](#notes)

# Requirements

## CLI

For the command-line based scripts, the following is required:

* chromium-browser
* python 2.7

### chromium-browser

To install the `chromium-browser`:

```sh
$ apt-get install -y chromium-browser
```

# Building

The current implementations are the command line scripts available in the [script](script) directory. There is no building necessary.

> Note: The original intent was to have the RTC Bee be Java-based just as the other bees (RTMPBee and RTSPBee) are. However, `chromedriver` seemed to occasionally be swallowed or lost when deployed on an AWS EC2 instance (which is the desired deploy for bees). As such, the work on the Java-based version has been halted as of January 28th, 2018.

# Attacking

* [Basic Subscription](#basic-subscription)
* [Stream Manager Proxy Subscription](#stream-manager-proxy-subscription)
* [Stream Manager Edge Subscription](#stream-manager-edge-subscription)

## Basic Subscription

```sh
$ cd script
$ ./rtcbee.sh [viewer.jsp endpoint] [amount of streams to start] [amount of time to playback]
```

### Options

#### endpoint

The endpoint of the `viewer.jsp` page to subscribe to a stream. The `viewer.jsp` page is provided by default with the `live` webapp of the Red5 Pro Server distribution.

#### amount

The amount of bullets (stingers, a.k.a. stream connections) for the bee to have in the attack.

#### timeout

The amount of time to subscribe to stream. _The actual subscription time may differ from this amount. This is really the time lapse of start of subscription until end._

#### Example

```sh
$ ./rtcbee.sh "https://your.red5pro-deploy.com/live/viewer.jsp?host=your.red5pro-deploy.com&stream=streamname" 10 10
```

## Stream Manager Proxy Subscription

The following example demonstrates how to assemble an attack against the multiple Edges deployed and accessible through the Stream Manager.
Included in the Red5 Pro Server distribution within the `live` webapp is are basic Stream Manager proxy examples that wllow for client configurations through query parameters.

* `/webapps/live/proxy-publisher.html`
* `/webapps/live/proxy-subscriber.html`

There are various query parameters you can set to test with the proxy examples, but for the purpose of using the `rtcbee` to test roundtrip tests through the Stream Manager to access Edge address(es) and start subscribing, the `streamName` paramter is all that is required.

```sh
$ cd script
$ ./rtcbee.sh [subscriber proxy endpoint] [amount of streams to start] [amount of time to playback]
```

### Options

#### subscriber proxy endpoint

The endpoint of the `proxy-subscriber.html` file including the `streamName` query param.

#### amount

The amount of streams to start.

#### timeout

The amount of time to subscribe to stream. _The actual subscription time may differ from this amount. This is really the time lapse of start of subscription until end._

```sh
$ cd script
$ ./rtcbee_sm.sh [stream-manager subscribe API endpoint] [app context] [stream name] [amount of streams to start] [amount of time to playback]
```

#### Example

```sh
$ ./rtcbee.sh https://stream-manager.url/live/proxy-subscriber.html?verbose=true&streamName=streamname" 1 100
```

## Stream Manager Edge Subscription

The following example demonstrates how to assemble an attack against a single Edge in a Stream Manager deployment.

### Options

#### stream-manager API endpoint

The API request endpoint that will return Edge server information.

#### context

The webapp context name that the stream would be available in at the edge IP returned.

#### stream name

The stream name to subscribe to at the edge IP returned.

#### amount

The amount of streams to start.

#### timeout

The amount of time to subscribe to stream. _The actual subscription time may differ from this amount. This is really the time lapse of start of subscription until end._

#### Example

```sh
$ ./rtcbee_sm.sh "https://stream-manager.url/streammanager/api/2.0/event/live/streamname?action=subscribe" live todd 10 10
```

