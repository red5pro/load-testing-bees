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
package com.infrared5.rtcbee;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import com.google.gson.Gson;

public class Red5Bee implements IBulletCompleteHandler, IBulletFailureHandler {

    // instance a scheduled executor, using a core size based on cpus
    private static ScheduledExecutorService executor = Executors.newScheduledThreadPool(Runtime.getRuntime().availableProcessors() * 8);
    
    private static String DEFAULT_DRIVER_LOCATION = null;
//    private static String DEFAULT_DRIVER_LOCATION = "/Users/toddanderson/Documents/Workplace/infrared5/rtcbee-node/node_modules/chromedriver/lib/chromedriver/chromedriver";
    private static String DEFAULT_BINARY_LOCATION = null;
//    private static String DEFAULT_BINARY_LOCATION = "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary";
    
    private String binaryLocation;

    private String protocol;
    
    private String host;

    private int port;

    private String application;

    private String streamName;

    private int numBullets;

    private int timeout = 10; // in seconds

    private AtomicInteger bulletsRemaining = new AtomicInteger();

    Map<Integer, RTCBullet> machineGun = new HashMap<Integer, RTCBullet>();
    
    private String streamManagerURL;

    /**
     * Original Bee - provide all parts of stream endpoint for attack.
     * 
     * @param protocol
     * @param host
     * @param port
     * @param application
     * @param streamName
     * @param numBullets
     * @param timeout
     * @param binaryLocation
     */
    public Red5Bee(String protocol, String host, int port, String application, String streamName, int numBullets, int timeout, String binaryLocation) {
    	this.protocol = protocol;
        this.host = host;
        this.port = port;
        this.application = application;
        this.streamName = streamName;
        this.numBullets = numBullets;
        this.timeout = timeout;
        this.binaryLocation = binaryLocation;
        this.streamManagerURL = null;
    }
    
    /**
     * Stream Manager Bee - provide Stream Manager endpoint for GET or stream uri.
     * 
     * @param streamManagerURL
     * @param numBullets
     * @param port
     * @param timeout
     * @param binaryLocation
     */
    public Red5Bee(String streamManagerURL, int numBullets, int port, int timeout, String binaryLocation) throws Exception {
        this.streamManagerURL = streamManagerURL;
        this.numBullets = numBullets;
        this.protocol = "http";
        this.port = port;
        this.timeout = timeout;
        this.binaryLocation = binaryLocation;
        modifyEndpointProperties(this.streamManagerURL);

    }

    /**
     * Submits a Runnable task to the executor.
     * 
     * @param runnable
     * @return
     */
    public static Future<?> submit(Runnable runnable) {
        return executor.submit(runnable);
    }

    /**
     * Submits a Runnable task to the executor with a scheduled delay.
     * 
     * @param runnable
     * @param delay
     * @param unit
     * @return
     */
    public static ScheduledFuture<?> submit(Runnable runnable, long delay, TimeUnit unit) {
        return executor.schedule(runnable, delay, unit);
    }
    
    /**
     * Updates property state based on data received from Stream Manager Endpoint request.
     * 
     * @param smURL
     * @throws Exception
     */
    public void modifyEndpointProperties(String smURL) throws Exception {
        
        System.out.printf("Access Streaming Endpoint from Stream Manager URL: %s.\n", streamManagerURL);
        String endpoint = accessStreamEndpoint(smURL).toString().trim();
        System.out.printf("Received Streaming Endpoint: %s.\n", endpoint);
        
        SubscriberEndpoint json = new Gson().fromJson(endpoint, SubscriberEndpoint.class);
        this.host = json.getServerAddress();
        this.port = this.port == 0 ? 5080 : this.port;
        this.streamName = json.getName();
        this.application = json.getScope().substring(1, json.getScope().length());
        
        System.out.printf("protocol: " + this.protocol + 
        		"host: " + this.host + 
        		", port: " + this.port + 
        		", context: " + this.application + 
        		", name " + this.streamName + ".\n");
        
    }

    /**
     * Loads up and fires.
     */
    public void attack() {
        this.loadMachineGun();
        this.fireMachineGun();
    }

    /**
     * Fires bullets from machine gun (iterable).
     */
    private void fireMachineGun() {
        for (Entry<Integer, RTCBullet> entry : machineGun.entrySet()) {
            System.out.printf("Submitting %d for execution\n", entry.getKey().intValue());
            // submit for execution
            submit(entry.getValue());
            bulletsRemaining.incrementAndGet();
        }
        System.out.printf("Active thread count at fireMachineGun: %d bullets: %d\n", Thread.activeCount(), bulletsRemaining.get());
    }

    /**
     * Puts bullets into machine gun (iterable).
     */
    private void loadMachineGun() {
        // load our bullets into the gun
        for (int i = 0; i < numBullets; i++) {
            // build a bullet
            RTCBullet bullet = RTCBullet.Builder.build((i + 1), protocol, host, port, application, streamName, timeout);
            bullet.setBinaryLocation(this.binaryLocation);
            bullet.setCompleteHandler(this);
            bullet.setFailHandler(this);
            machineGun.put(i, bullet);
        }
    }
    
    @Override
    public void OnBulletComplete() {
        int remaining = bulletsRemaining.decrementAndGet();
        if (remaining <= 0) {
            System.out.println("All bullets expended. Bye Bye.");
            System.exit(1);
        }
        System.out.println("Bullet has completed journey. Remaining Count: " + bulletsRemaining);
        System.out.printf("Active thread count: %d bullets remaining: %d\n", Thread.activeCount(), bulletsRemaining.get());
    }

    @Override
    public void OnBulletFireFail() {
        System.out.println("Failure for bullet to fire.");
        if (this.streamManagerURL != null) {
            try {
                modifyEndpointProperties(this.streamManagerURL);
                // build a bullet
                RTCBullet bullet = RTCBullet.Builder.build(++numBullets, protocol, host, port, application, streamName, timeout);
                bullet.setBinaryLocation(this.binaryLocation);
                bullet.setCompleteHandler(this);
                bullet.setFailHandler(this);
                // submit for execution
                submit(bullet);
            } catch (Exception e) {
                System.out.printf("Could not refire bullet with Stream Manager Endpoint URL: %s\n.", this.streamManagerURL);
                e.printStackTrace();
            }
        }
    }
    
    /**
     * Attempts to access stream endpoint uri from Stream Manager URL.
     * 
     * @param desiredUrl
     * @return
     * @throws Exception
     */
    private String accessStreamEndpoint(String desiredUrl) throws Exception {
        URL url = null;
        BufferedReader reader = null;
        StringBuilder stringBuilder;

        try {
            url = new URL(desiredUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setReadTimeout(15 * 1000);
            connection.connect();

            // read the output from the server
            reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
            stringBuilder = new StringBuilder();
            String line = null;
            while ((line = reader.readLine()) != null) {
                stringBuilder.append(line + "\n");
            }
            return stringBuilder.toString();
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (IOException ioe) {
                    ioe.printStackTrace();
                }
            }
        }
    }
    
    private static String getDefinedArgument (String[] args, String namedParam, int index) {
    	if (args[index].compareTo(namedParam) == 0) {
    		return args[index + 1].trim();
    	}
    	return null;
    }

    /**
     * Entry point.
     * 
     * @param args
     * @throws InterruptedException
     */
    public static void main(String[] originalArgs) throws InterruptedException {
    	
        System.out.printf("Number of original arguments: %d.\n", originalArgs.length);
        
        // app args
        String protocol;
        String url;
        int port;
        String application;
        String streamName;
        int numBullets;
        int timeout = 10;
        
        int sliceIndex = 0;
        String[] args = null;
        String driverLocation = null;
        String binaryLocation = null;

        Red5Bee bee;
        
        if (originalArgs.length > 1) {
        	
        	// Binary is specified
        	binaryLocation = getDefinedArgument(originalArgs, "-b", 0);
        	if (binaryLocation == null) {
        		binaryLocation = getDefinedArgument(originalArgs, "-b", 2);
        	}
        	else {
        		sliceIndex = 2;
        	}
        	
        	// Driver is specified
        	driverLocation = getDefinedArgument(originalArgs, "-d", sliceIndex);
        	if (driverLocation != null) {
        		sliceIndex = (binaryLocation != null) ? 4 : 2;
        	}
        	else {
        		driverLocation = Red5Bee.DEFAULT_DRIVER_LOCATION;
        	}
        	
        	if (binaryLocation == null) {
        		binaryLocation = Red5Bee.DEFAULT_BINARY_LOCATION;
        	}
        	
        	System.out.println("Binary defined: " + binaryLocation);
        	System.out.println("Driver defined: " + driverLocation);
        	
        }

        // >----- SET UP SYSTEM DRIVE PROPS -----
    	// Optional, if not specified, WebDriver will search your path for chromedriver.
    	System.setProperty("webdriver.chrome.logfile", "chromedriver.log");
    	System.setProperty("webdriver.chrome.verboseLogging", "true");
        if (driverLocation != null) {
        	System.setProperty("webdriver.chrome.driver", driverLocation);
        }
        // <----- SET UP SYSTEM DRIVE PROPS -----
        
        System.out.println("Going to trim arg list from " + sliceIndex + "...");
        args = Arrays.copyOfRange(originalArgs, sliceIndex, originalArgs.length -1);
        System.out.printf("Number of sliced arguments: %d.\n", args.length);
        
        // 3 option for client specific attack.
        if (args.length < 2) {
        	
            System.out.printf("Incorrect number of args, please pass in the following: \n " + "\narg[0] = Stream Manager Endpoint to access Stream Subscription URL" + "\narg[1] = numBullets");
            return;
            
        } 
        else if (args.length >= 3 && args.length <= 4) {
        	
            System.out.printf("Determined its a stream manager attack...");
            url = args[0].toString().trim();
            port = Integer.parseInt(args[1]);
            numBullets = Integer.parseInt(args[2]);
            if (args.length > 3) {
                timeout = Integer.parseInt(args[3]);
            }
            try {
                bee = new Red5Bee(url, numBullets, port, timeout, binaryLocation);
                bee.attack();
            } catch (Exception e) {
                System.out.printf("Could not properly parse provided endpoint from Stream Manager: %s.\n", args[0]);
                e.printStackTrace();
            }
        	
        }
    	// 6 option arguments for origin attack.
        else if (args.length < 6) {
        	
            System.out.printf("Incorrect number of args, please pass in the following: \n  " + "\narg[0] = IP Address" + "\narg[1] = port" + "\narg[2] = app" + "\narg[3] = streamName" + "\narg[4] = numBullets");
            return;
            
        }
        else {
        	
            System.out.println("Determined its an original attack... " + args[0]);
            url = args[0];
            protocol = args[1];
            port = Integer.parseInt(args[2]);
            application = args[3];
            streamName = args[4];
            numBullets = Integer.parseInt(args[5]);
            if (args.length > 6) {
                timeout = Integer.parseInt(args[6]);
            }
            // create the bee
            bee = new Red5Bee(protocol, url, port, application, streamName, numBullets, timeout, binaryLocation);
            bee.attack();
            
        }
        // put the main thread in limbo while the bees fly!
        Thread.currentThread().join();
        // shutdown the executor
        executor.shutdown();
        // wait up-to 10 seconds for tasks to complete
        executor.awaitTermination(10, TimeUnit.SECONDS);
        System.out.println("Main - exit");
    }

}
