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
