package com.infrared5.rtmpbee;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
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

	private static String VERSION = "4.2.1";
	
    // instance a scheduled executor, using a core size based on cpus
    private static ScheduledExecutorService executor = Executors.newScheduledThreadPool(Runtime.getRuntime().availableProcessors() * 8);

    private String url;

    private int port;

    private String application;

    private String streamName;

    private int numBullets;

    private int timeout = 10; // in seconds

    private String streamManagerURL; // optional

    private AtomicInteger bulletsRemaining = new AtomicInteger();

    Map<Integer, Bullet> machineGun = new HashMap<Integer, Bullet>();

    /**
     * Original Bee - provide all parts of stream endpoint for attack.
     * 
     * @param url
     * @param port
     * @param application
     * @param streamName
     * @param numBullets
     * @param timeout
     */
    public Red5Bee(String url, int port, String application, String streamName, int numBullets, int timeout) {
    	this.url = url;
        this.port = port;
        this.application = application;
        this.streamName = streamName;
        this.numBullets = numBullets;
        this.timeout = timeout;
        this.streamManagerURL = null;
    }

    /**
     * Stream Manager Bee - provide Stream Manager endpoint for GET or stream uri.
     * 
     * @param streamManagerURL
     * @param numBullets
     * @param timeout
     */
    public Red5Bee(String streamManagerURL, int numBullets, int timeout) throws Exception {
    	this.streamManagerURL = streamManagerURL;
        this.numBullets = numBullets;
        this.timeout = timeout;
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
        String scope = json.getScope();
        this.url = json.getServerAddress();
        this.port = this.port == 0 ? 1935 : this.port;
        this.streamName = json.getName();
        this.application = scope.charAt(0) == '/' ? scope.substring(1, scope.length()) : scope;
        
        System.out.printf("url: " + this.url + ", port: " + this.port + ", context: " + this.application + ", name " + this.streamName + ".\n");
        
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
        for (Entry<Integer, Bullet> entry : machineGun.entrySet()) {
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
        	try {
        		if (this.streamManagerURL != null) {
        			modifyEndpointProperties(this.streamManagerURL);
        		}
        		Bullet bullet = Bullet.Builder.build((i + 1), url, port, application, streamName, timeout);
        		bullet.setCompleteHandler(this);
        		bullet.setFailHandler(this);
        		machineGun.put(i, bullet);
        	}
        	catch (Exception e) {
        		System.out.printf("[WARNING] Could not assemble bullet for firing: %s\n", e.getMessage());
        	}
        }
    }

    @Override
    public void OnBulletComplete() {
        int remaining = bulletsRemaining.decrementAndGet();
        if (remaining <= 0) {
            System.out.println("All bullets expended. Bye Bye.");
            System.exit(0);
        }
        System.out.println("Bullet has completed journey. Remaining Count: " + bulletsRemaining);
        System.out.printf("Active thread count: %d bullets remaining: %d\n", Thread.activeCount(), bulletsRemaining.get());
    }

    @Override
    public void OnBulletFireFail() {
        // If is an streammanager-based call, we may need to re-access on a test where the server went down.
        if (this.streamManagerURL != null) {
        	System.out.println("Failure for bullet to fire. Possible missing endpoint. Accessing a new endpoint from stream manager.");
            try {
                modifyEndpointProperties(this.streamManagerURL);
                // build a bullet
                Bullet bullet = Bullet.Builder.build(++numBullets, url, port, application, streamName, timeout);
                bullet.setCompleteHandler(this);
                bullet.setFailHandler(this);
                // submit for execution
                submit(bullet);
            } catch (Exception e) {
                System.out.printf("Could not refire bullet with Stream Manager Endpoint URL: %s\n.", this.streamManagerURL);
                e.printStackTrace();
            }
        }
        else {
        	int remaining = bulletsRemaining.decrementAndGet();
            if (remaining <= 0) {
                System.out.println("All bullets expended. Bye Bye.");
                System.exit(1);
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
        

    /**
     * Entry point.
     * 
     * @param args
     * @throws InterruptedException
     */
    public static void main(String[] args) throws InterruptedException {
    	System.out.printf("Running RTMPBees %s.\n", VERSION);
        System.out.printf("Number of arguments: %d.\n", args.length);
        // app args
        String url;
        int port;
        String application;
        String streamName;
        int numBullets;
        int timeout = 10;

        Red5Bee bee;

        // 3 option for client specific attack.
        if (args.length < 2) {
            System.out.printf("Incorrect number of args, please pass in the following: \n " + "\narg[0] = Stream Manager Endpoint to access Stream Subscription URL" + "\narg[1] = numBullets");
            return;
        } 
        else if (args.length >= 3 && args.length <= 4) {
            System.out.printf("Determined its a stream manager attack...\n");
            url = args[0].toString().trim();
            port = Integer.parseInt(args[1]);
            numBullets = Integer.parseInt(args[2]);
            if (args.length > 3) {
                timeout = Integer.parseInt(args[3]);
            }
            try {
                bee = new Red5Bee(url, numBullets, timeout);
                bee.attack();
            } catch (Exception e) {
                System.out.printf("Could not properly parse provided endpoint from Stream Manager: %s.\n", args[0]);
                e.printStackTrace();
            }
        }
        // 5 option arguments for origin attack.
        else if (args.length < 5) {
            System.out.printf("Incorrect number of args, please pass in the following: \n  " + "\narg[0] = IP Address" + "\narg[1] = port" + "\narg[2] = app" + "\narg[3] = streamName" + "\narg[4] = numBullets");
            return;
        }
        else {
            System.out.println("Determined its an original attack...\n");
            url = args[0];
            port = Integer.parseInt(args[1]);
            application = args[2];
            streamName = args[3];
            numBullets = Integer.parseInt(args[4]);
            if (args.length > 5) {
                timeout = Integer.parseInt(args[5]);
            }
            // create the bee
            bee = new Red5Bee(url, port, application, streamName, numBullets, timeout);
            bee.attack();
        }
        // put the main thread in limbo while the bees fly!
        Thread.currentThread().join();
        // shutdown the executor
        executor.shutdown();
        // wait up-to 10 seconds for tasks to complete
        executor.awaitTermination(10, TimeUnit.SECONDS);
        System.out.println("Main - exit");
        System.exit(0);
    }

}