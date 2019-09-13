//
// Copyright © 2015 Infrared5, Inc. All rights reserved.
//
// The accompanying code comprising examples for use solely in conjunction with Red5 Pro (the "Example Code")
// is  licensed  to  you  by  Infrared5  Inc.  in  consideration  of  your  agreement  to  the  following
// license terms  and  conditions.  Access,  use,  modification,  or  redistribution  of  the  accompanying
// code  constitutes your acceptance of the following license terms and conditions.
//
// Permission is hereby granted, free of charge, to you to use the Example Code and associated documentation
// files (collectively, the "Software") without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The Software shall be used solely in conjunction with Red5 Pro. Red5 Pro is licensed under a separate end
// user  license  agreement  (the  "EULA"),  which  must  be  executed  with  Infrared5,  Inc.
// An  example  of  the EULA can be found on our website at: https://account.red5pro.com/assets/LICENSE.txt.
//
// The above copyright notice and this license shall be included in all copies or portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,  INCLUDING  BUT
// NOT  LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY, FITNESS  FOR  A  PARTICULAR  PURPOSE  AND
// NONINFRINGEMENT.   IN  NO  EVENT  SHALL INFRARED5, INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN  AN  ACTION  OF  CONTRACT,  TORT  OR  OTHERWISE,  ARISING  FROM,  OUT  OF  OR  IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
package com.infrared5.rtmpbee;

import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import org.apache.commons.lang3.StringUtils;
import org.red5.client.net.rtmp.ClientExceptionHandler;
import org.red5.client.net.rtmp.INetStreamEventHandler;
import org.red5.client.net.rtmp.RTMPClient;
import org.red5.io.utils.ObjectMap;
import org.red5.server.api.event.IEvent;
import org.red5.server.api.event.IEventDispatcher;
import org.red5.server.api.service.IPendingServiceCall;
import org.red5.server.api.service.IPendingServiceCallback;
import org.red5.server.api.stream.IStreamPacket;
import org.red5.server.net.rtmp.event.Notify;
import org.red5.server.net.rtmp.status.StatusCodes;

public class Bullet implements Runnable {

    private final int order;

    private final String url;

    private final int port;

    private final String application;

    public final String streamName;

    public final String description;

    private int timeout = 10; // seconds

    private RTMPClient client;

    private ConnectionCloseHook shutdownHook;

    private IBulletCompleteHandler completeHandler;

    private IBulletFailureHandler failHandler;

    public AtomicBoolean completed = new AtomicBoolean(false);

    volatile boolean connectionException;

    private Future<?> future;

    /**
     * Constructs a bullet which represents an RTMPClient.
     * 
     * @param url
     * @param port
     * @param application
     * @param streamName
     */
    private Bullet(int order, String url, int port, String application, String streamName) {
        this.order = order;
        this.url = url;
        this.port = port;
        this.application = application;
        this.streamName = streamName;
        this.description = toString();
    }

    /**
     * Constructs a bullet which represents an RTMPClient.
     * 
     * @param url
     * @param port
     * @param application
     * @param streamName
     * @param timeout
     */
    private Bullet(int order, String url, int port, String application, String streamName, int timeout) {
        this(order, url, port, application, streamName);
        this.timeout = timeout;
    }

    public void run() {
        this.shutdownHook = new ConnectionCloseHook(this);
        System.out.println("<<fire>>: " + description);
        client = new RTMPClient();
        client.setServiceProvider(this);
        client.setExceptionHandler(new ClientExceptionHandler() {
            @Override
            public void handleException(Throwable throwable) {
                connectionException = true;
                dispose();
            }
        });
        client.setStreamEventDispatcher(new IEventDispatcher() {
            @Override
            public void dispatchEvent(IEvent event) {
                @SuppressWarnings("unused")
                IStreamPacket data = (IStreamPacket) event;
                System.out.println("dispatchEvent: " + event);
            }
        });
        client.setStreamEventHandler(new INetStreamEventHandler() {
            @Override
            public void onStreamEvent(Notify notification) {
                System.out.println("<<event>>: " + description);
                System.out.println(notification.toString());
            }
        });
        client.setConnectionClosedHandler(shutdownHook);

        future = Red5Bee.submit(new Runnable() {

            public void run() {
                client.connect(url, port, client.makeDefaultConnectionParams(url, port, application), connectCallback);
                while (!completed.get()) {
                    if (connectionException && failHandler != null) {
                        System.out.println("Failure in Bullet: " + description);
                        failHandler.OnBulletFireFail();
                    }
                    try {
                        Thread.sleep(1L);
                    } catch (InterruptedException e) {
                    }
                }
            }

        });
    }

    public void onBWCheck(Object params) {
        System.out.println("onBWCheck: " + params);
    }

    /**
     * Called when bandwidth has been configured.
     */
    public void onBWDone(Object params) {
        System.out.println("onBWDone: " + params);
    }

    public void onStatus(Object params) {
        System.out.printf("(bullet #%d) onStatus: %s\n", order, params);
        String status = params.toString();
        // if stream is stopped or unpublished
        if (status.indexOf("Stop") != -1 || status.indexOf("UnPublish") != -1) {
            if (completed.compareAndSet(false, true)) {
            	System.out.printf("completeHandler? #%1$b\n", completeHandler);
                if (completeHandler != null) {
                    completeHandler.OnBulletComplete();
                }
                dispose();
            }
        }
    }

    private IPendingServiceCallback streamCallback = new IPendingServiceCallback() {

        public void resultReceived(IPendingServiceCall call) {
            if (call.getServiceMethodName().equals("createStream")) {
            	Number streamId = (Number) call.getResult();
                // -2: live then recorded, -1: live, >=0: recorded
                // streamId, streamName, mode, length
                System.out.printf("streamCallback:resultReceived: (streamId #%f)\n", streamId);
                client.play(streamId, streamName, -2, 0);
                Red5Bee.submit(new Runnable() {
                    public void run() {
                        System.out.printf("Successful subscription of bullet, disposing: bullet #%d\n", order);
                        if (completed.compareAndSet(false, true)) {
                        	System.out.printf("completeHandler? #%1$b\n", completeHandler);
                            if (completeHandler != null) {
                                completeHandler.OnBulletComplete();
                            }
                            dispose();
                        }
                    }
                }, timeout, TimeUnit.SECONDS);
            }
        }
    };

    private IPendingServiceCallback connectCallback = new IPendingServiceCallback() {

        public void resultReceived(IPendingServiceCall call) {
            ObjectMap<?, ?> map = (ObjectMap<?, ?>) call.getResult();
            String code = (String) map.get("code");
            System.out.printf("connectCallback: (code #%s)\n", code);
            // Server connection established, but issue in connection.
            if (StatusCodes.NC_CONNECT_FAILED.equals(code) || StatusCodes.NC_CONNECT_REJECTED.equals(code) || StatusCodes.NC_CONNECT_INVALID_APPLICATION.equals(code)) {
                if (completed.compareAndSet(false, true)) {
                	System.out.printf("completeHandler? #%1$b\n", completeHandler);
                    if (completeHandler != null) {
                        completeHandler.OnBulletComplete();
                    }
                    dispose();
                }
            }
            // If connection successful, establish a stream
            else if (StatusCodes.NC_CONNECT_SUCCESS.equals(code)) {
                client.createStream(streamCallback);
            } else {
                // TODO: Notify of failure.
                System.err.print("ERROR code:" + code);
            }
        }
    };

    public void dispose() {
        System.out.printf("dispose: (bullet #%d)\n", order);
        if (client != null) {
            client.setServiceProvider(null);
            client.setExceptionHandler(null);
            client.setStreamEventDispatcher(null);
            client.setStreamEventHandler(null);
            client.setConnectionClosedHandler(null);
            client.disconnect();
            shutdownHook = null;
            client = null;
        }
        if (future != null) {
            future.cancel(true);
        }
    }

    public void setCompleteHandler(IBulletCompleteHandler completeHandler) {
        this.completeHandler = completeHandler;
    }

    public void setFailHandler(IBulletFailureHandler failHandler) {
        this.failHandler = failHandler;
    }

    public String toString() {
        return StringUtils.join(new String[] { "(bullet #" + this.order + ")", "URL: " + this.url, "PORT: " + this.port, "APP: " + this.application, "NAME: " + this.streamName }, "\n");
    }

    class ConnectionCloseHook implements Runnable {

        private Bullet client;

        public ConnectionCloseHook(Bullet client) {
            this.client = client;
        }

        @Override
        public void run() {
            this.client.connectionException = true;
        }

    }

    static final class Builder {

        static Bullet build(int order, String url, int port, String application, String streamName) {
            return new Bullet(order, url, port, application, streamName);
        }

        static Bullet build(int order, String url, int port, String application, String streamName, int timeout) {
            return new Bullet(order, url, port, application, streamName, timeout);
        }

    }

}
