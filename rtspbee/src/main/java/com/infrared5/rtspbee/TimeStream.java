package com.infrared5.rtspbee;

import java.util.concurrent.TimeUnit;

public class TimeStream{
	private long lastTime=-1;
	private double streamTime = 0;
	private TimeUnit timeUnit;
	private double scale;
	private double multiplier=1;
	private double startFrom =0;
	

	/**
	 * Transforms rtp timestamps to linear timestamps unscaled.
	 * @param asValue The desired linear output granularity.
	 * @param scale The scale of the rtp timestamps.
	 */
	public TimeStream( TimeUnit asValue,long scale){
		this.timeUnit = asValue;
		this.scale=scale;
		switch(timeUnit){
		case MINUTES:
			multiplier=1.0/60.0;
			break;
		default:
		case SECONDS:
			break;
		case MILLISECONDS:
			multiplier=1000.0;
			break;
		case MICROSECONDS:
			multiplier=1000000.0;
			break;
		case NANOSECONDS:
			multiplier=1000000000.0;
			break;
		}
	}
	public void reset(double startFrom){
		lastTime=-1;
		this.startFrom = startFrom;
	}
	
	/**
	 *
	 * @param newTime 32 bit unsigned integer as a long.
	 * @return ascending time as timeunits with roll over handling. 
	 */
	public double deltaScaled(long newTime ){
	
		if(lastTime==-1){
			lastTime = newTime;
			streamTime=startFrom;
			return 0;
		}
		if(lastTime>newTime){
			//roll over
//			System.out.println("roll over");

			double max = 0xFFFFFFFFL ;
			double oldS = lastTime;
			oldS=oldS-max;//
			double deltaInRTP = (newTime-oldS);				
			lastTime=newTime;
			streamTime+=((deltaInRTP/scale)*multiplier);
			
			if(streamTime>4294967295.0){
				streamTime-=4294967295.0;
			}
			return  streamTime;
		}else{
		
			double oldRTP = lastTime;				
			double deltaInRTP = (newTime-oldRTP);
			lastTime=newTime;
			streamTime+=((deltaInRTP/scale)*multiplier);
			
			if(streamTime>4294967295.0){
				streamTime-=4294967295.0;
			}
			return  streamTime;
		}
	}
	public static void main(String[] args)  {		
		
		TimeStream ts=new TimeStream(TimeUnit.MILLISECONDS,90000); 
		long x =0xFFFFFFFFL-10000;
		for(int y=0;y<1000;y++){
			
			System.out.println(x+ "x "+ts.deltaScaled(x&0xFFFFFFFFL)); 
			x+=2000L;

		}
	}
}
