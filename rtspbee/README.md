# RTSP Bee
The RTSP Bee is a java program that runs a subscription "attack" on a server. One *RTSP Bee* can have N *Bullets* (or stingers) that are fired concurrently.

* [Requirements](#build-requirements)
* [Building](#building)
* [Attacking](#attacking)
* [Notes](#notes)

# Build Requirements

* Maven 3+
* Java 8 JDK

# Building

First run the `setup`:

```sh
./setup.sh
```

## Maven

Creates an executable jar with all the needed dependencies (~26Mb)

```sh
$ mvn clean compile assembly:single
```

# Attacking

> You will need to have Java 8 installed to run the RTSP Bee.

* [Basic Subscription](#basic-subscription)
* [Stream Manager Subscription](#stream-manager-subscription)

## Basic Subscription

```sh
$ java -jar -noverify rtspbee.jar [red5pro-server-IP] [port] [app-name] [stream-name] [count] [timeout]
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

```sh
java -jar -noverify rtspbee.jar xxx.xxx.xxx.xxx 8554 live mystream 100 60
```

This will run an attack with `100` stingers (a.k.a, subscription streams) for `60` seconds each, consuming the `mystream` stream at `rtmp://xxx.xxx.xxx.xxx/1935`.

## Stream Manager Subscription

```sh
$ java -jar -noverify rtspbee.jar [stream-manager-API-request] [port] [count] [timeout]
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

```sh
$ java -jar -noverify rtspbee.jar "http://xxx.xxx.xxx.xxx:5080/streammanager/api/3.1/event/live/mystream?action=subscribe" 8554 100 60
```

This will run an attack with `100` stingers (a.k.a, subscription streams) for `60` seconds each, consuming the `mystream` stream at the Edge server address returned from the Stream Manager API call to `http://xxx.xxx.xxx.xxx:5080/streammanager/api/3.1/event/live/mystream?action=subscribe`.

# Notes

## Stream Manager API

For the Stream Manager example, it is important to note that the insecure IP address is required. If you are serving your Stream Manager over SSL, the RTSP bee cannot properly use its API due to security restrictions. _It is possible to resolve these security issues in the future, if you download and store the cert in your Java install, [https://stackoverflow.com/questions/21076179/pkix-path-building-failed-and-unable-to-find-valid-certification-path-to-requ](https://stackoverflow.com/questions/21076179/pkix-path-building-failed-and-unable-to-find-valid-certification-path-to-requ)._

## noverify

The above `run` examples use the `-noverify` option when running the bee. Without this option, verification errors are thrown due to the compilation and obsfucation of the Red5 Pro dependency libs.
