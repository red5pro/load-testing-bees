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

import java.io.IOException;
import java.io.OutputStream;
import java.net.ConnectException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import org.apache.commons.lang3.StringUtils;
import org.apache.mina.core.buffer.IoBuffer;
import org.apache.mina.util.Base64;
import org.red5.server.api.event.IEvent;
import org.red5.server.net.rtmp.event.AudioData;
import org.red5.server.net.rtmp.event.VideoData;
import org.red5.server.net.rtmp.message.Constants;
import org.red5.server.net.rtmp.message.Header;

import com.red5pro.server.stream.Red5ProIO;
import com.red5pro.server.stream.rtp.RTPStreamPacket;
import com.red5pro.server.stream.rtp.handlers.codec.AAC;
import com.red5pro.server.stream.sdp.SDPTrack;
import com.red5pro.server.stream.sdp.SessionDescription;
import com.red5pro.server.stream.sdp.SessionDescriptionProtocolDecoder;

/**
 * Transcode rtsp over tcp .
 *
 * @author Andy Shaules
 */
public class RTSPBullet implements Runnable {

  private final int order;
  public final String description;
  private int timeout = 10; // seconds

  private static final int CodedSlice = 1;
  private static final int IDR = 5;
  private static final int FUA = 28;
  private static int FU8 = 1 << 7;
  private static int FU7 = 1 << 6;
  private static int FU6 = 1 << 5;
  private static int FU5 = 1 << 4;
  private static int FU4 = 1 << 3;
  private static int FU3 = 1 << 2;
  private static int FU2 = 1 << 1;
  private static int FU1 = 1;
  private static int FUupper = FU8 | FU7 | FU6;
  private static int FUlower = FU5 | FU4 | FU3 | FU2 | FU1;
  private static final int[] AAC_SAMPLERATES = { 96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000,
      11025, 8000, 7350 };

  private String host = "0.0.0.0";
  private int port = 8554;
  private String contextPath = "";
  private String streamName = "stream1";
  private Socket requestSocket;
  private OutputStream out;
  private long seq = 0;
  private int state = 0;
  private int bodyCounter = 0;
  private Map<String, String> headers = new HashMap<String, String>();
  private byte[] part1;
  private byte[] part2;
  private List<byte[]> chunks = new ArrayList<byte[]>();
  private volatile boolean doRun = true;
  private boolean fistKey = false;
  private SessionDescriptionProtocolDecoder decoder;
  private SessionDescription sdp;
  private SDPTrack videoTrack;
  private SDPTrack audioTrack;
  private String session;
  private byte[] codecSetup;
  private long videoStart;
  private byte[] packetBuffer = null;
  private int packetBufferOffset = 0;
  private int bufferingDataSize;
  private long lastSent;
  private boolean initialAudioSent;
  private byte[] audioConfig;
  //private long audioStart;
  private volatile ConcurrentLinkedQueue<MediaPacket> packets = new ConcurrentLinkedQueue<MediaPacket>();
  private TimeStream videoTimer=new TimeStream(TimeUnit.MILLISECONDS,90000);
  private TimeStream audiioTimer;
  //private boolean isPlaying=false;
  
  private IBulletCompleteHandler completeHandler;
  private IBulletFailureHandler failHandler;
  public AtomicBoolean completed = new AtomicBoolean(false);
  volatile boolean connectionException;
  private Future<?> future;
  
  private boolean requiresVideoSetup = true;


  private String formUri() {
    return "rtsp://" + host + ":" + port + "/" + contextPath + "/" + streamName;
  }

  protected void setupVideo() throws IOException {

    out.write(("SETUP " + formUri() + "/video RTSP/1.0\r\n" + "CSeq: " + nextSeq() + "\r\n"
        + "User-Agent: Red5Pro\r\n" + "Blocksize : 4096\r\n"
        + "Transport: RTP/AVP/TCP;interleaved=2-3\r\n\r\n").getBytes());
    out.flush();

    int k = 0;
    String lines = "";

    while ((k = requestSocket.getInputStream().read()) != -1) {

      lines += String.valueOf((char) k);
      if (lines.indexOf("\n") > -1) {

        lines = lines.trim();
        parseHeader(lines);

        if (lines.length() == 0) {
          break;
        }
        lines = "";

      }

    }
  }

  protected void setupAudio() throws IOException {
    out.write(("SETUP " + formUri() + "/audio RTSP/1.0\r\nCSeq: " + nextSeq()
        + "\r\n" + "User-Agent: Red5Pro\r\n" + "Transport: RTP/AVP/TCP;interleaved=0-1\r\n\r\n").getBytes());

    out.flush();
    int k = 0;
    String lines = "";

    while ((k = requestSocket.getInputStream().read()) != -1) {
      lines += String.valueOf((char) k);
      if (lines.indexOf("\n") > -1) {

        lines = lines.trim();
        parseHeader(lines);

        if (lines.length() == 0) {
          break;
        }
        lines = "";

      }

    }
  }

  private synchronized void safeClose(){
    try{
    	stop();
    	if(requestSocket!=null) {
    		System.out.println("Bullet #" + this.order + ", closing socket...");
    		requestSocket.close();
    		requestSocket=null;
    	}
    }catch(Exception e){
    	System.out.println("Error in SAFE CLOSE");
    	e.printStackTrace();
    }
  }

  @SuppressWarnings("unused")
  public void run() {

    boolean mustEnd =false;
    try {

      System.out.println("Bullet #" + this.order + ", Attempting connect to " + host + " in port " + String.valueOf(port));

      requestSocket = new Socket(host, port);

      System.out.println("Bullet #" + this.order + ", Connected to " + host + " in port " + String.valueOf(port));

      out = requestSocket.getOutputStream();
      out.write(("OPTIONS " + formUri() + " RTSP/1.0\r\n" + "CSeq: " + nextSeq() + "\r\n"
          + "User-Agent: Red5Pro\r\n\r\n").getBytes());
      out.flush();
      try{
//        System.out.println("parsing options...");
        parseOptions();
      }
      catch(Exception e) {
         safeClose();
         System.out.println("Parsing options error.");
         System.out.println(e.getMessage());
         e.printStackTrace();
         dostreamError();
         return;
      }
      out.write(("DESCRIBE " + formUri() + " RTSP/1.0\r\n" + "CSeq: " + nextSeq() + "\r\n"
          + "User-Agent: Red5Pro\r\n" + "Accept: application/sdp\r\n" + "\r\n").getBytes());
      out.flush();
      
      System.out.println("Bullet #" + this.order + ", Parsing Description.");
      try{
        System.out.println("parsing description...");
        parseDescription();
        setupAudio();
        if (this.requiresVideoSetup) {
        	setupVideo();
        }
      }
      catch(Exception e){
        System.out.println("parsing description error...");
        System.out.println(e.getMessage());
        e.printStackTrace();
        safeClose();
        dostreamError();
        return;
      }

//      System.out.println("LETS PLAY...");
      System.out.println("Bullet #" + this.order + ", Start Playback.");
      out.write(("PLAY " + formUri() + " RTSP/1.0\r\nCSeq:" + nextSeq() + "\r\n"
          + "User-Agent:Lavf\r\n\r\n").getBytes());
      out.flush();

      int k = 0;
      String lines = "";
      try{
        while ((k = requestSocket.getInputStream().read()) != -1) {
          lines += String.valueOf((char) k);
          if (lines.indexOf("\n") > -1) {
            lines = lines.trim();
            if (lines.length() == 0) {
              System.out.println("End of header, begin stream.");
              break;
            }
            lines = "";
          }
        }
      }
      catch(Exception e) {
        System.out.println("reading socket input error...");
        System.out.println(e.getMessage());
        e.printStackTrace();
        safeClose();
        dostreamError();
        return;
      }
      
      Red5Bee.submit(new Runnable() {
          public void run() {
              System.out.printf("Successful subscription of bullet, disposing: bullet #%d\n", order);
              if (completed.compareAndSet(false, true)) {
              	if (completeHandler != null) {
              		safeClose();
              		completeHandler.OnBulletComplete();
                }
              }
          }
      }, timeout, TimeUnit.SECONDS);

      mustEnd = true;
      int lengthToRead = 0;// incoming packet length.
      while (doRun && (k = requestSocket.getInputStream().read()) != -1) {
//        System.out.println("doRun run.");
        //isPlaying=true;
        if (k == 36) {

          int buffer[] = new int[3];
          buffer[0] = requestSocket.getInputStream().read() & 0xff;
          buffer[1] = requestSocket.getInputStream().read() & 0xff;
          buffer[2] = requestSocket.getInputStream().read() & 0xff;

          lengthToRead = (buffer[1] << 8 | buffer[2]);

          byte packet[] = new byte[lengthToRead];// copy packet.

          k = 0;
          while (lengthToRead-- > 0) {
            packet[k++] = (byte) requestSocket.getInputStream().read();
          }
          // packet header info.
          int cursor = 0;
          int version = (packet[0] >> 6) & 0x3;// rtp
          int p = (packet[0] >> 5) & 0x1;
          int x = (packet[0] >> 4) & 0x1;
          int cc = packet[0] & 0xf;// count of sync srsc
          int m = packet[1] >> 7;// m bit
          int pt = packet[1] & (0xff >> 1);// packet type
          int sn = packet[2] << 8 | packet[3];// sequence number.
          long time = ((packet[4] & 0xFF) << 24 | (packet[5] & 0xFF) << 16 | (packet[6] & 0xFF) << 8
              | (packet[7] & 0xFF)) & 0xFFFFFFFFL;

          cursor = 12;
          // parse any other clock sources.
          for (int y = 0; (y < cc); y++) {
            long CSRC = packet[cursor++] << 24 | packet[cursor++] << 16 | packet[cursor++] << 8
                | packet[cursor++];
          }
          // based on packet type.
          int type = 0;

          if (buffer[0] == 0) {// video channel
            IoBuffer buffV;
            if (!initialAudioSent) {
              time = 0;
            }

            time = (long) videoTimer.deltaScaled(time);

            int pos = cursor;

            type = readNalHeader((byte) packet[cursor++]);
            // IoBuffer buffV;

            byte[] realPacket = Arrays.copyOfRange(packet, pos, packet.length);

            switch (type) {

            case FUA:

              byte info = (byte) realPacket[1];
              int fragStart = (info >> 7) & 0x1;
              int fragEnd = (info >> 6) & 0x1;
              int fragmentedType = readNalHeader(info);

              if (fragStart == 1) {
                chunks.clear();
              }

              chunks.add(realPacket);

              if (fragEnd == 1) {

                int tot = 1;// packet header.
                for (byte[] part : chunks) {
                  tot += part.length - 2;
                }

                byte totBuf[] = new byte[tot];
                // set in non-fragmented Nal header.
                totBuf[0] = (byte) ((realPacket[0] & FUupper) | (realPacket[1] & FUlower));

                int chunkCursor = 1;

                for (int l = 0; l < chunks.size(); l++) {
                  // Aggregate into one array.
                  for (int d = 2; d < chunks.get(l).length; d++) {
                    totBuf[chunkCursor++] = chunks.get(l)[d];
                  }
                }
                type = fragmentedType;
                realPacket = totBuf;

              } else {
                break;
              }

            case IDR:// key frame. send config for giggles.
              if (type == IDR) {

                sendAVCDecoderConfig((int) time);
                int y = realPacket.length;

                buffV = IoBuffer.allocate(y + 9);
                buffV.setAutoExpand(true);
                buffV.put((byte) 0x17);// packet tag// key //
                            // avc
                buffV.put((byte) 0x01);// vid tag
                // vid tag presentation off set
                buffV.put((byte) 0);
                buffV.put((byte) 0);
                buffV.put((byte) 0);
                // nal size
                buffV.put((byte) ((y >> 24) & 0xff));
                buffV.put((byte) ((y >> 16) & 0xff));
                buffV.put((byte) ((y >> 8) & 0xff));
                buffV.put((byte) ((y) & 0xff));
                // nal data
                // second copy
                buffV.put(realPacket);
                buffV.flip();
                buffV.position(0);
                VideoData videoIDR = new VideoData(buffV);
                videoIDR.setSourceType(Constants.SOURCE_TYPE_LIVE);
                videoIDR.setHeader(new Header());
                // videoIDR.getHeader().setTimer(time);
                videoIDR.setTimestamp((int) time);
                // slices.clear();
                videoIDR.getHeader().setStreamId(1);
                MediaPacket deliverable = new MediaPacket();
                deliverable.frame = videoIDR;
                packets.add(deliverable);
                break;
              }

            case CodedSlice:
              if (type == CodedSlice) {

                int y = realPacket.length;
                buffV = IoBuffer.allocate(y + 9);
                buffV.setAutoExpand(true);
                buffV.put((byte) 0x27);// packet tag//non
                            // key//avc
                buffV.put((byte) 0x01);// vid tag
                // presentation off set
                buffV.put((byte) 0x0);
                buffV.put((byte) 0);
                buffV.put((byte) 0);
                // nal size
                buffV.put((byte) ((y >> 24) & 0xff));
                buffV.put((byte) ((y >> 16) & 0xff));
                buffV.put((byte) ((y >> 8) & 0xff));
                buffV.put((byte) ((y) & 0xff));
                // nal data
                // second copy

                buffV.put(realPacket);
                buffV.flip();
                buffV.position(0);

                VideoData codedSlice = new VideoData(buffV);
                codedSlice.setSourceType(Constants.SOURCE_TYPE_LIVE);
                codedSlice.setTimestamp((int) time);
                codedSlice.setHeader(new Header());
                codedSlice.getHeader().setStreamId(1);

                MediaPacket deliverable = new MediaPacket();
                deliverable.frame = codedSlice;
                packets.add(deliverable);

              }

              break;
            }

          } else if (buffer[0] == 2) {
            // audio channel
            time = time / Long.valueOf(audioTrack.format.clockRate);
            RTPStreamPacket aacPacket = new RTPStreamPacket(IoBuffer.wrap(packet));
            parseAAC(aacPacket);
          }
        }
      }

      System.out.println("--- teardown ---");
      
      out.write(("TEARDOWN " + formUri() + " RTSP/1.0\r\n" + "CSeq: " + nextSeq() + "\r\n"
          + "User-Agent: Red5-Pro\r\n" + "Session: " + session + " \r\n\r\n").getBytes());

      out.flush();
      out.close();
      
      System.out.println("---/ teardown ---");
      
    } catch (UnknownHostException unknownHost) {
      System.out.println("--- host error ---");
      System.out.println(unknownHost.getMessage());
      unknownHost.printStackTrace();
      dostreamError();
      System.out.println("---/ host error ---");
    } catch (ConnectException conXcept) {
      System.out.println("--- connect error ---");
      System.out.println(conXcept.getMessage());
      conXcept.printStackTrace();
      dostreamError();
      System.out.println("---/ connect error ---");
    } catch (IOException ioException) {
      System.out.println("--- io error ---");
      System.out.println(ioException.getMessage());
      ioException.printStackTrace();
      System.out.println("---/ io error ---");
      dostreamError();
    } catch (Exception genException) {
      System.out.println("--- general error ---");
      System.out.println(genException.getMessage());
      genException.printStackTrace();
      System.out.println("---/ general error ---");
      dostreamError();
    } finally {
      System.out.println("--- /finally ---");
      safeClose();
    }
  }
  private void dostreamError() {
	  
	  final IBulletFailureHandler thisFail = this.failHandler;
	  System.out.println("Bullet #" + this.order + ", stream error.");
	  new Thread(new Runnable(){
	
	    @Override
	    public void run() {
	      thisFail.OnBulletFireFail();
	    }}).start();
    
  }

  private void sendAVCDecoderConfig(int timecode) {

    if (part2 == null) {
      return;
    }

    produceCodecSetup();

    IoBuffer buffV = IoBuffer.allocate(codecSetup.length);
    buffV.setAutoExpand(true);
    for (int p = 0; p < codecSetup.length; p++)
      buffV.put(codecSetup[p]);

    buffV.flip();
    buffV.position(0);

    VideoData video = new VideoData(buffV);
    video.setSourceType(Constants.SOURCE_TYPE_LIVE);
    video.setTimestamp(timecode);
    video.setHeader(new Header());
    video.getHeader().setStreamId(1);
    MediaPacket deliverable = new MediaPacket();
    deliverable.frame = video;
    packets.add(deliverable);
    fistKey = initialAudioSent;
    // log.trace( "config sent. length" + codecSetup.length+" "+thisId);
  }

  private void produceCodecSetup() {

    int codecSetupLength = 5 // header
        + 8 // SPS header
        + part1.length // the SPS itself
        + 3 // PPS header
        + part2.length; // the PPS itself

    codecSetup = new byte[codecSetupLength];
    int cursor = 0;
    // header
    codecSetup[cursor++] = 0x17; // 0x10 - key frame; 0x07 - H264_CODEC_ID
    codecSetup[cursor++] = 0; // 0: AVC sequence header; 1: AVC NALU; 2: AVC
    // end of sequence
    codecSetup[cursor++] = 0; // CompositionTime
    codecSetup[cursor++] = 0; // CompositionTime
    codecSetup[cursor++] = 0; // CompositionTime
    // SPS
    codecSetup[cursor++] = 1; // version
    codecSetup[cursor++] = part1[1]; // profile
    codecSetup[cursor++] = part1[2]; // profile compat
    codecSetup[cursor++] = part1[3]; // level

    codecSetup[cursor++] = (byte) 0xff; // 6 bits reserved (111111) + 2 bits
    // nal size length - 1 (11)//Adobe
    // does not set reserved bytes.
    codecSetup[cursor++] = (byte) 0xe1; // 3 bits reserved (111) + 5 bits
    // SPS length.
    codecSetup[cursor++] = (byte) ((part1.length >> 8) & 0xFF);
    codecSetup[cursor++] = (byte) (part1.length & 0xFF);
    // copy _pSPS data;part1
    for (int k = 0; k < part1.length; k++) {
      codecSetup[cursor++] = part1[k];
    }
    // PPS
    codecSetup[cursor++] = 1; // number of pps. TODO, actually check for
    // short to big endian.
    codecSetup[cursor++] = (byte) ((part2.length >> 8) & 0xFF);
    codecSetup[cursor++] = (byte) (part2.length & 0xFF);
    // copy _pPPS data;
    for (int k = 0; k < part2.length; k++) {
      codecSetup[cursor++] = part2[k];
    }

  }

  private void parseOptions() throws IOException {
    int lineLength = Integer.MAX_VALUE;
    int k = 0;
    String returnData = "";
    while (lineLength > 0 && (k = requestSocket.getInputStream().read()) != -1) {
      returnData = returnData + String.valueOf((char) k);
      if (returnData.indexOf("\n") > -1) {

        //System.out.println(returnData.trim());
        lineLength = returnData.trim().length();
        returnData = "";
      }
    }
  }

  private void parseDescription() throws IOException {
    int k = 0;

    String returnData = "";

    while (bodyCounter == 0 && (k = requestSocket.getInputStream().read()) != -1) {
      // get header
      returnData = returnData + String.valueOf((char) k);
      // read it line by line.
      if (state < 3) {
        if (returnData.indexOf("\n") > -1) {
          //System.out.println(returnData);
          parse(returnData);

          returnData = "";
        } else {
          continue;
        }
      } else {
        // got description header.
        break;
      }
    }
    // parse description body.
    int localVal = bodyCounter;
    // get body
    while (localVal-- > 0 && (k = requestSocket.getInputStream().read()) != -1) {

      returnData = returnData + String.valueOf((char) k);
      // read it line by line.
      if (state < 3) {
        if (returnData.indexOf("\n") > -1) {
          parse(returnData);
          returnData = "";
        } else {
          continue;
        }
      } else {
        break;
      }
    }
    sdp = decoder.decode();
    // We have the sdp description data.
//    System.out.println("--- sdp ---");
//    System.out.println(sdp.toString());
//    System.out.println("--- /sdp ---");
    String propsets = "";
    for (SDPTrack t : sdp.tracks) {
      if (t.announcement.content.equals(SessionDescription.VIDEO)) {
        videoTrack = t;
        propsets = t.parameters.parameters.get("sprop-parameter-sets");
      } else if (t.announcement.content.equals(SessionDescription.AUDIO)) {
        audioTrack = t;
      }
    }

//    System.out.println("----- propsets ----");
//    System.out.println(propsets);
//    System.out.println("----- /propsets ----");
    String splits[] = propsets.split("(,)");
    // sps
    part1 = Base64.decodeBase64(splits[0].trim().getBytes());
    if (splits.length > 1) {
    	// pps
    	part2 = Base64.decodeBase64(splits[1].trim().getBytes());
    }
    else {
    	// An empty propset means it is audio only.
    	requiresVideoSetup = false;
    }

  }

  private long nextSeq() {
    return ++seq;
  }

  private void parseHeader(String s) {

    String[] hdr = new String[2];
    int idx = s.indexOf(":");
    // end of header?

//    System.out.println("parseHeader: " + s);
//    System.out.println("--- headers ---");
//    System.out.println(headers);
//    System.out.println("--- /headers ---");
    if (idx < 0 && headers.get("Content-Length") != null) {
      bodyCounter = Integer.valueOf(headers.get("Content-Length"));
      state = 2;
      return;
    }
    else if (idx < 0) {
      return;
    }
    hdr[0] = s.substring(0, idx);
    hdr[1] = s.substring(idx + 1);
    hdr[1] = hdr[1].replace("\r", "");
    hdr[1] = hdr[1].replace("\n", "");
    if (hdr[0].trim().equals("Session")) {
      this.session = hdr[1].trim();
    }
    headers.put(hdr[0].trim(), hdr[1].trim());
//    System.out.println("--- hdr ---");
//    System.out.println(hdr[0] + " = " + hdr[1]);
//    System.out.println("--- /hdr ---");
//    System.out.println("--- session ---");
//    System.out.println(this.session);
//    System.out.println("--- /session ---");
  }

  private int readNalHeader(byte bite) {

    int NALUnitType = (int) (bite & 0x1F);
    return NALUnitType;
  }

  private void parse(String s) {
    if (state == 1) {// RTSP OK 200, get headers.
//      System.out.println("Parse Headers..." + s);
      parseHeader(s);
      return;
    }
    if (state == 2) {// DESCRIBE results.
//      System.out.println("Parse Describe.... " + s);
      parseDescribeBody(s);
      return;
    }
    if (state == 3) {// Done. Ready for setup/playback.
      return;
    }
    // check for RTSP OK 200
    String[] tokens = s.split(" ");
    for (int i = 0; i < tokens.length; i++) {
      if ((tokens[i].indexOf("200") > -1)) {
        state = 1;
      }
    }
  }

  public void createDecoder (RTSPBullet target) {
    target.decoder = new SessionDescriptionProtocolDecoder();
  }

  private void parseDescribeBody(String s) {

//    System.out.println("parseDescriptionBody: " + s);

    if (decoder == null) {
//      System.out.println("Lets create a new decoder...");
      this.decoder = new SessionDescriptionProtocolDecoder();
    }

//    System.out.println("gonna do a check...");
//    System.out.println("Index? " + s.indexOf("="));
    int idx = s.indexOf("=");
//    System.out.println("= index: " + idx);
    if (idx < 0) {// finished with body header?
      state = 3;
      return;
    }

//    System.out.println("Decoder read.");
    decoder.readLine(s);
  }

  private void parseAAC(RTPStreamPacket packet) {

    boolean sendConfig = false;
    double time = packet.getTimestamp();
    if(audiioTimer==null){
      audiioTimer=new TimeStream(TimeUnit.MILLISECONDS, Long.valueOf(audioTrack.format.clockRate));
    }
    time = audiioTimer.deltaScaled(((long) time)&0xFFFFFFFFL);

    // enter the AU Header section;

    if (packet.payload.length > 3) {

      int headerBitsSize = (packet.payload[0] & 0xFF) << 8 | packet.payload[1] & 0xFF;

      int headerBytesLength = headerBitsSize / 8;

      if (headerBitsSize % 8 != 0)
        headerBytesLength++;// it is padded out with zeros.

      if (headerBytesLength < 2)// invalid for HBR;
        return;

      int auSizeField = (packet.payload[2] & 0xFF) << 8 | packet.payload[3] & 0xFF;

      int audioDataSize = (auSizeField >> 3) & 0x1FFF;// top 13 bits.

      if (packetBuffer != null) {

        if (packetBuffer != null && bufferingDataSize != audioDataSize) {

          packetBuffer = null;

          if (audioDataSize <= packet.payload.length - 4) {

            if (audioDataSize - bufferingDataSize == 4) {
              dispatchAudio(sendConfig, packet.payload, 8, bufferingDataSize, (long) time);
            }
            bufferingDataSize = 0;
          }
          return;
        }

        if ((packet.payload.length - 4) + packetBufferOffset >= audioDataSize) {

          try {
            System.arraycopy(packet.payload, 4, packetBuffer, packetBufferOffset,
                audioDataSize - packetBufferOffset);
          }
          catch (Exception e) {
//            System.out.println("Couldnt parse AAC");
          }

          dispatchAudio(sendConfig, packetBuffer, 0, audioDataSize, (long) time);
          packetBuffer = null;

        } else {
          Red5ProIO.debug("Uh oh unhandled triple audio fragment!");
          packetBuffer = null;
        }

      } else if (packet.payload.length < audioDataSize + headerBytesLength
          + 2/* header-bits size */) {

        packetBuffer = new byte[audioDataSize * 2];
        packetBufferOffset = packet.payload.length - (headerBytesLength + 2);
        bufferingDataSize = audioDataSize;

        try {
          System.arraycopy(packet.payload, 4, packetBuffer, 0, packet.payload.length - 4);
        }
        catch (Exception e) {
//          System.out.println("Couldnt parse AAC");
        }

      } else if (packet.payload.length == audioDataSize + headerBytesLength
          + 2/* header-bits size */) {
        packetBuffer = null;
        dispatchAudio(sendConfig, packet.payload, 4, audioDataSize, (long) time);

      } else if (packet.payload.length > audioDataSize + headerBytesLength
          + 2/* header-bits size */) {

        dispatchAudio(sendConfig, packet.payload, 4, audioDataSize, (long) time);
        packetBuffer = null;
        // next audio size;
        try {
          int nxtAudioSize = (packet.payload[(audioDataSize + 4) + 2] & 0xFF) << 8
              | (packet.payload[(audioDataSize + 4) + 3] & 0xFF);

          bufferingDataSize = nxtAudioSize;
          packetBuffer = new byte[((packet.payload.length - 4) - audioDataSize)];

          System.arraycopy(packet.payload, audioDataSize + 4, packetBuffer, 0, packetBuffer.length);
        }
        catch (Exception e) {
//        	System.out.println("Couldnt parse AAC");
        }
      }
    }
  }

  private void dispatchAudio(boolean sendConfig, byte[] payload, int offset, int audioDataSize, long rtpTime) {

    //if (!initialAudioSent) {
    //  audioStart = rtpTime;
    //
    //}

    //rtpTime = rtpTime - audioStart;

    IoBuffer minbuffer = IoBuffer.allocate(audioDataSize + 2);
    minbuffer.setAutoExpand(true);
    if (audioDataSize <= 3) {// inband aac config data
      lastSent = System.currentTimeMillis();
      minbuffer.put(new byte[] { (byte) 0xAF, (byte) 0x00 });
    } else {
      minbuffer.put(new byte[] { (byte) 0xAF, (byte) 0x01 });
    }

    for (int y = offset; y < (audioDataSize + offset); y++) {
      minbuffer.put(payload[y]);
    }

    minbuffer.flip();

    AudioData audioData = new AudioData(minbuffer);
    audioData.setHeader(new Header());
    audioData.getHeader().setChannelId(1);
    audioData.setSourceType(Constants.SOURCE_TYPE_LIVE);
    audioData.setTimestamp((int) rtpTime);

    MediaPacket deliverable = new MediaPacket();
    deliverable.frame = audioData;
    if (System.currentTimeMillis() - lastSent > 10000) {
      sendConfig = true;
    }

    if (!initialAudioSent) {
      initialAudioSent = true;
      videoTimer.reset(rtpTime);
      lastSent = System.currentTimeMillis();
      MediaPacket privateData = new MediaPacket();
      privateData.frame = getPrivateData((int) rtpTime);
      packets.add(privateData);
    } else if (sendConfig) {

      lastSent = System.currentTimeMillis();
      MediaPacket privateData = new MediaPacket();
      privateData.frame = getPrivateData((int) rtpTime);

      packets.add(privateData);
    }

    packets.add(deliverable);

  }

  private IEvent getPrivateData(long timecode) {

    IoBuffer buffer = IoBuffer.allocate(10);
    buffer.setAutoExpand(true);
    buffer.put((byte) 0xaf);
    buffer.put((byte) 0x00);
    buffer.put(getAACSpecificConfig());

    buffer.flip();

    buffer.rewind();

    AudioData data = new AudioData(buffer);
    data.setHeader(new Header());
    data.setSourceType(Constants.SOURCE_TYPE_LIVE);
    data.getHeader().setChannelId(1);
    data.setTimestamp((int) timecode);
    return data;

  }

  private byte[] getAACSpecificConfig() {

    boolean defaulting = false;
    int profile = 2;
    int frequency_index = -1;
    int channel_config = 0;

    for (int x = 0; x < AAC.AAC_SAMPLERATES.length; x++) {
      if (AAC_SAMPLERATES[x] == Integer.valueOf(audioTrack.format.clockRate)) {
        frequency_index = x;
      }
    }
    if (audioTrack.parameters.parameters.containsKey("object")) {
      profile = Integer.valueOf(audioTrack.parameters.parameters.get("object"));
    }
    channel_config = Integer.valueOf(audioTrack.format.numChannels);

    if (frequency_index < 0) {
      defaulting = true;
      frequency_index = 4;
    }

    profile = (profile & 0x1F) << 3;

    byte[] b = new byte[] { (byte) ((profile | ((frequency_index >> 1) & 0x07))),
        (byte) ((((frequency_index & 0x01) << 7) | ((channel_config & 0x0F) << 3))) };

    if (audioConfig != null) {
      if (AAC.doMatch(b, audioConfig)) {
        return audioConfig;
      }
      if (defaulting) {// we guessed wrong, I guess....
        return audioConfig;
      }
    }

    return b;
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

  public ConcurrentLinkedQueue<MediaPacket> getPackets() {
    return packets;
  }
  
  public void setCompleteHandler(IBulletCompleteHandler completeHandler) {
      this.completeHandler = completeHandler;
  }

  public void setFailHandler(IBulletFailureHandler failHandler) {
      this.failHandler = failHandler;
  }


	/**
	 * Constructs a bullet which represents an RTMPClient.
	 *
	 * @param url
	 * @param port
	 * @param application
	 * @param streamName
	 */
	private RTSPBullet(int order, String url, int port, String application, String streamName) {
	    this.order = order;
	    this.host = url;
	    this.port = port;
	    this.contextPath = application;
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
	private RTSPBullet(int order, String url, int port, String application, String streamName, int timeout) {
	    this(order, url, port, application, streamName);
	    this.timeout = timeout;
	}
	
	public String toString() {
	    return StringUtils.join(new String[] { "(bullet #" + this.order + ")", "URL: " + this.host, "PORT: " + this.port, "APP: " + this.contextPath, "NAME: " + this.streamName }, "\n");
	}

	static final class Builder {

        static RTSPBullet build(int order, String url, int port, String application, String streamName) {
            return new RTSPBullet(order, url, port, application, streamName);
        }

        static RTSPBullet build(int order, String url, int port, String application, String streamName, int timeout) {
            return new RTSPBullet(order, url, port, application, streamName, timeout);
        }

    }

}
