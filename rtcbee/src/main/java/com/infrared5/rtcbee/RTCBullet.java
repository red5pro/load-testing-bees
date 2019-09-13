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

import java.io.File;
import java.util.Date;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import org.apache.commons.lang3.StringUtils;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;

public class RTCBullet implements Runnable {

  private boolean doRun;
  private final int order;
  public final String description;
  private int timeout = 10; // seconds

  private String protocol = "http";
  private String host = "0.0.0.0";
  private int port = 5080;
  private String contextPath = "live";
  private String streamName = "stream1";
  
  private String binaryLocation;

  private IBulletCompleteHandler completeHandler;
  private IBulletFailureHandler failHandler;
  public AtomicBoolean completed = new AtomicBoolean(false);
  volatile boolean connectionException;
  private Future<?> future;
  
  private String formatEndpoint () {
	  String portStr = this.port == -1 ? "" : ":" + String.valueOf(this.port);
	  return this.protocol + "://" + this.host + portStr + 
			  "/" + this.contextPath + 
			  "/viewer.jsp" + 
			  "?host=" + this.host + 
			  "&stream=" + this.streamName;
  }

  @SuppressWarnings("unused")
  public void run() {
	  
	  WebDriver driver = null;
	  try {
		  
		  String t = String.valueOf(new Date().getTime());
		  
		  String endpoint = formatEndpoint();
		  System.out.println("Bullet #" + this.order + ", Attempting connect to " + endpoint);
		  
		  ChromeOptions options = new ChromeOptions();
		  options.addArguments("--headless",
				  "--disable-gpu",
				  "--use-gl=swiftshader-webgl",
				  "--disable-accelerated-video-decode",
				  "--disable-gpu-compositing",
				  "--enable-gpu-async-worker-context",
				  "--user-data-dir=/tmp/chrome" + this.order,
				  "--remote-debugging-port=900" + this.order,
				  "--mute-audio",
				  "--window-size=1024,768",
				  "--enable-logging",
				  "--v=99");
		  if (binaryLocation != null) {
			  options.setBinary(new File(binaryLocation));
		  }
		  
		  driver = new ChromeDriver(options);
	  	  driver.get(endpoint);
	  	  
	  	  final WebDriver d = driver;
	  
		  Red5Bee.submit(new Runnable() {
			  public void run() {
				  System.out.printf("Successful subscription of bullet, disposing: bullet #%d\n", order);
				  if (completed.compareAndSet(false, true)) {
					  if (completeHandler != null) {
						  d.close();
						  completeHandler.OnBulletComplete();
						  doRun = false;
					  }
				  }
			  }
		  }, timeout, TimeUnit.SECONDS);
		  
		  while (doRun) {
			  System.out.println("Bullet #" + this.order + ", running...");
		  }
	  }
	  catch (Exception e) {
		  e.printStackTrace();
		  if (driver != null) {
			  driver.close();
		  }
	  }
  }

  public void stop() {
    doRun = false;
  }

  public boolean isRunnning() {
    return doRun;
  }

  public String getHost() {
    return host;
  }

  public void setHost(String host) {
    this.host = host;
  }

  public int getPort() {
    return port;
  }

  public void setPort(int port) {
    this.port = port;
  }

  public String getContextPath() {
    return contextPath;
  }

  public void setContextPath(String contextPath) {
    this.contextPath = contextPath;
  }

  public String getStreamName() {
    return streamName;
  }

  public void setStreamName(String streamName) {
    this.streamName = streamName;
  }
  
  public void setCompleteHandler(IBulletCompleteHandler completeHandler) {
      this.completeHandler = completeHandler;
  }

  public void setFailHandler(IBulletFailureHandler failHandler) {
      this.failHandler = failHandler;
  }
  
  public void setBinaryLocation (String location) {
	  this.binaryLocation = location;
	  System.out.println("Bullet #" + this.order + ", Binary location set: " + this.binaryLocation);
  }

	/**
	 * Constructs a bullet which represents an RTC Client.
	 *
	 * @param protocol
	 * @param host
	 * @param port
	 * @param application
	 * @param streamName
	 */
	private RTCBullet(int order, String protocol, String host, int port, String application, String streamName) {
		
		this.protocol = protocol;
		this.order = order;
	    this.host = host;
	    if (protocol.compareTo("https") == 0 && port == 43) {
		  this.port = -1;
		}
		else if (protocol.compareTo("http") == 0 && port == 80) {
		  this.port = -1;
		}
		else {
		  this.port = port;
		}
	    this.contextPath = application;
	    this.streamName = streamName;
	    this.description = toString();
	    
	}
	
	/**
	 * Constructs a bullet which represents an RTC Client.
	 *
	 * @param protocol
	 * @param host
	 * @param port
	 * @param application
	 * @param streamName
	 * @param timeout
	 */
	private RTCBullet(int order, String protocol, String host, int port, String application, String streamName, int timeout) {
	    this(order, protocol, host, port, application, streamName);
	    this.timeout = timeout;
	}
	
	public String toString() {
	    return StringUtils.join(new String[] { "(bullet #" + this.order + ")", "Endpoint: " + formatEndpoint() }, "\n");
	}

	static final class Builder {

        static RTCBullet build(int order, String protocol, String host, int port, String application, String streamName) {
            return new RTCBullet(order, protocol, host, port, application, streamName);
        }

        static RTCBullet build(int order, String protocol, String host, int port, String application, String streamName, int timeout) {
            return new RTCBullet(order, protocol, host, port, application, streamName, timeout);
        }

    }

}
