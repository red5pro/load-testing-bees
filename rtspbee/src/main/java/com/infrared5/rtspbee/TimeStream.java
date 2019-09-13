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
