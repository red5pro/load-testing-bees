package com.infrared5.rtmpbee;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

public class SubscriberEndpoint {
	
	@SerializedName("name")
	@Expose
	private String name;
	
	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	@SerializedName("scope")
	@Expose
	private String scope;
	
	public String getScope() {
		return scope;
	}

	public void setScope(String scope) {
		this.scope = scope;
	}

	@SerializedName("serverAddress")
	@Expose
	private String serverAddress;
	
	public String getServerAddress() {
		return serverAddress;
	}

	public void setServerAddress(String serverAddress) {
		this.serverAddress = serverAddress;
	}

	@SerializedName("region")
	@Expose
	private String region;

	public String getRegion() {
		return region;
	}

	public void setRegion(String region) {
		this.region = region;
	}
}
