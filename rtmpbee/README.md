# RTMP Bee
The RTMP Bee is a java program that runs a subscription "attack" on a server. One *RTMP Bee* can have N *Bullets* (or stingers) that are fired concurrently.

* [Requirements](#requirements)
* [Building](#building)
* [Attacking](#attacking)
* [Notes](#notes)

# Requirements

Github projects listed pulled locally and referenced in workspace:

* [red5-client](https://github.com/Red5/red5-client)
* [red5-io](https://github.com/Red5/red5-io)
* [red5-server-common](https://github.com/Red5/red5-server-common)

Built using **Java 8 JDK**

# Building

First run the `setup` script:

```sh
./setup.sh
```

## Eclipse

> Preferred, as the Maven build has issues with Bouncy Castle

To create the executable jar in Eclipse, use export (~16Mb):

1. Import `rtmpbee` in Eclipse workspace
2. Right-click on the `rtmpbee` project in the Project Explorer
3. Select __Export...__
4. Select __Java / Runnable JAR File__
5. Point to the desired output directory
6. Make sure __Package required libraries...__ is ticked ON
7. Click Finish

## Maven

Creates an executable jar with all the needed dependencies (~17Mb)

```sh
$ mvn clean compile assembly:single
```

# Attacking

* [Basic Subscription](#basic-subscription)
* [Stream Manager Subscription](#stream-manager-subscription)

## Basic Subscription

```sh
$ java -jar rtmpbee.jar [red5pro-server-IP] [port] [app-name] [stream-name] [count] [timeout]
```

### Options

#### red5pro-server-IP
The IP of the Red5 Pro Server that you want the bee to subscribe to attack.

#### port
The port on the Red5 Pro Server that you want the bee to subscribe to attack.

#### app-name
The application name that provides the streaming capabilities.

#### stream-name
The name of the stream you want the bee to subscribe to attack.

#### count
The amount of bullets (stingers, a.k.a. stream connections) for the bee to have in the attack.

#### timeout
The amount of time to subscribe to stream. _The actual subscription time may differ from this amount. This is really the time lapse of start of subscription until end._

#### Example

```ssh
java -jar rtmpbee.jar xxx.xxx.xxx.xxx 1935 live mystream 100 60
```

This will run an attack with `100` stingers (a.k.a, subscription streams) for `60` seconds each, consuming the `mystream` stream at `rtmp://xxx.xxx.xxx.xxx/1935`.

## Stream Manager Subscription

```sh
$ java -jar rtmpbee.jar [stream-manager-API-request] [port] [count] [timeout]
```

### Options

#### stream-manager-API-request
The API request endpoint that will return Edge server information.

#### port
The port on the Red5 Pro Edge Server that you want the bee to subscribe to attack.

#### count
The amount of bullets (stingers, a.k.a. stream connections) for the bee to have in the attack

#### timeout
The amount of time to subscribe to stream. _The actual subscription time may differ from this amount. This is really the time lapse of start of subscription until end._

#### Example

```ssh
$ java -jar rtmpbee.jar "http://xxx.xxx.xxx.xxx:5080/streammanager/api/3.1/event/live/mystream?action=subscribe" 1935 100 60
```

This will run an attack with `100` stingers (a.k.a, subscription streams) for `60` seconds each, consuming the `mystream` stream at the Edge server address returned from the Stream Manager API call to `http://xxx.xxx.xxx.xxx:5080/streammanager/api/3.1/event/live/mystream?action=subscribe`.

# Notes

## Stream Manager API

For the Stream Manager example, it is important to note that the insecure IP address is required. If you are serving your Stream Manager over SSL, the RTMP bee cannot properly use its API due to security restrictions. _It is possible to resolve these security issues in the future, if you download and store the cert in your Java install, [https://stackoverflow.com/questions/21076179/pkix-path-building-failed-and-unable-to-find-valid-certification-path-to-requ](https://stackoverflow.com/questions/21076179/pkix-path-building-failed-and-unable-to-find-valid-certification-path-to-requ)._

[![Analytics](https://ga-beacon.appspot.com/UA-59819838-3/red5pro/rtmpbee?pixel)](https://github.com/igrigorik/ga-beacon)

