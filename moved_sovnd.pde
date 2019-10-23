/**
 * moved-sovnd aka. "that berry was a flower once"
 *
 * ideas and help from:
 * http://www.openprocessing.org/sketch/16770
 * http://stackoverflow.com/a/7227057/2035807
 * https://zugiduino.wordpress.com/2013/01/07/kinect-motion-detection/
 * http://www.learningprocessing.com/examples/chapter-16/example-16-13/
 */


/// IMPORTS

import processing.video.*;

import SimpleOpenNI.*;

import ddf.minim.*;
import ddf.minim.ugens.*;
import ddf.minim.signals.*;

import com.francisli.processing.http.*;


/// VARS

Movie mov;
PImage kinectDepthImage;

SimpleOpenNI kinect;

Minim minim;
AudioOutput out;
SineWave sine1;
SineWave sine2;

HttpClient client;
com.francisli.processing.http.JSONObject JSONResult;

String lastMessage = ""; // •
long lastRefresh = 0;
int refreshInterval = 3000; // ms
int refreshThresh = 7000; // ms;
long showUntil = 0;
String lastCommentId = ""; 
PFont displayFont;

PImage prevFrame, currFrame;
long frameTimer;


/// CONSTANTS
final int FPS = 12, MAX_CHAR = 140;
final boolean mirror = true;
final int winWidth = 800, winHeight = 600;
final int centerX = winWidth/2, centerY = winHeight/2;
final int minDist = 1000;
final int maxDist = minDist + 1000;
final int waveMod = 50;
final int min_freq = 70, max_freq = 1000;
// GL◉W
final boolean requestOnlinePosts = false;
final String POST_ID = "1054796524547380";
//final String POST_ID = "1054021867958179";

final boolean takeSnapshots = false;
// adapt this for your shapshots destination folder
final String savePath = "/path/to/snapshots/directory";
final String saveFormat = ".jpg"; // support by processing



void setup() 
{
  frameRate(FPS);
  
  noCursor();
  
  size(winWidth, winHeight);
  
  mov = new Movie(this, "the-clip.mp4");
  mov.loop();
  mov.volume(0);
 
 
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();
  kinect.enableRGB();
  //kinect.setDepthImageColor(81,18,178);
  kinect.setDepthImageColor(251,72,71);
  //kinect.setDepthImageColor(71,251,124);
  kinect.setMirror(mirror);
  
  
  prevFrame = createImage(640, 480, RGB);
  
  
  minim = new Minim(this);
  out = minim.getLineOut(Minim.STEREO);
  
  sine1 = new SineWave(min_freq, 0.5, out.sampleRate());
  sine1.portamento(200);
  //sine1.setAmp(0.2f);
  
  sine2 = new SineWave(min_freq, 0.5, out.sampleRate());
  sine2.portamento(200);
  sine2.setAmp(0.5f);
  
  out.addSignal(sine1);
  out.addSignal(sine2);
  
  
  displayFont = loadFont("CenturyGothic-48.vlw");
  textFont(displayFont);
  textAlign(CENTER);
  textSize(26);
}


 
void draw() 
{
  /// MOVIE 
  
  int movWidth = (height * mov.width) / mov.height;
  
  // assuming width of movie is bigger
  int winMovWidthDiff = movWidth - width;
  int movPosX = winMovWidthDiff / 2;
  
  imageMode(CORNER);
  image(mov, -movPosX, 0, movWidth, height);
 
  
  /// KINECT
  kinect.update();
  currFrame = kinect.rgbImage();
  
  kinectDepthImage = kinect.depthImage();
  int[] depthValues = kinect.depthMap();
  int depthValuesInCircleCount = 1;
  int depthSum = 800;
  int diffSum = 1;
  
  kinectDepthImage.width = 640;
  kinectDepthImage.height = 480;
  
  kinectDepthImage.loadPixels();
  for ( int y = 0; y < 480; y++ )
  {
    for ( int x = 0; x < 640; x++ ) 
    {
      int i = x + (y * 640);
      int currentDepthValue = depthValues[i];
      
      /// http://stackoverflow.com/a/7227057/2035807
      float dx = abs(x - 320);
      float dy = abs(y - 240);
      int R = 230;
      
      boolean isInCircle = false;
      
      if ( (dx + dy) <= R )
        isInCircle = true;
      else if ( dx > R ) 
        isInCircle = false;
      else if ( dy > R ) 
        isInCircle = false;
      else if ( (pow(dx,2) + pow(dy,2)) <= pow(R,2) ) 
        isInCircle = true;
        
      
      if ( isInCircle && 
           currentDepthValue > minDist && currentDepthValue < maxDist ) 
      {        
        // Y-AVG CALC
        depthValuesInCircleCount++;
        depthSum += currentDepthValue;
        
        // X-AVG CALC
        color current = currFrame.pixels[i];
        color previous = prevFrame.pixels[i];
        
        int r1 = floor(red(current)); 
        int g1 = floor(green(current)); 
        int b1 = floor(blue(current));
        
        int r2 = floor(red(previous)); 
        int g2 = floor(green(previous)); 
        int b2 = floor(blue(previous));
        
        int diff = floor(dist(r1, g1, b1, r2, g2, b2));
        
        diffSum += diff;
      } 
      else 
      {
        kinectDepthImage.pixels[i] = color(0,1);
      }
    }  
  }
  kinectDepthImage.updatePixels();
  
  imageMode(CENTER);
  image(kinectDepthImage, centerX, centerY);

  
  // check if this is more performant
  //int m = millis();
  //if ( m - frameTimer > 50 )
  //{
    prevFrame.copy(currFrame, 0, 0, currFrame.width, currFrame.height, 0, 0, prevFrame.width, prevFrame.height);
    prevFrame.updatePixels();
    //frameTimer = m;
  //}
  
  
  /// CIRCLE
  ellipseMode(CENTER);
  noStroke();
  fill(255, 32);
  ellipse(centerX, centerY, 480, 480);
  fill(0, 50);
  ellipse(centerX, centerY, 460, 460);
  
  
  // Y-CIRCLE
  int avgDepthValue = depthSum / depthValuesInCircleCount;
  
  // X-CIRCLE
  int avgDiffValue = diffSum / depthValuesInCircleCount;
  //avgDiffValue = round(map(avgDiffValue, 1, 50, 1, width));
  
  //lastBigAvgVal = ( avgDepthValue > lastBigAvgVal ) ? avgDepthValue : lastBigAvgVal;
  //float mouseYRep = map(avgDepthValue, minDist, maxDist, 0, height);
  
  
  //avgDepthValue = ( avgDepthValue == 800 ) ? (int)random(minDist+(minDist/3), maxDist) : avgDepthValue;
  
  //float freq1 = map(mouseYRep, 0, height, 1000, 60);
  //float freq1 = map(avgDepthValue, minDist, maxDist, 1300, 60);
  
  float freq1, freq2;
  
  if ( avgDepthValue != 800 ) 
    freq1 = map(avgDepthValue, minDist, maxDist, max_freq, min_freq);
  else
    freq1 = 60;
  
  //float freq2 = freq1 + mouseX * 30 / width;
  //float freq2 = freq1 + (width/2) * 30 / width;
  //float freq2 = freq1 + ((int)random(0, width)) * 30 / width;
  if ( avgDepthValue != 800 ) 
    //freq2 = freq1 + ((int)random(0, width)) * 30 / width;
    //freq2 = freq1 + avgDiffValue * 30 / width;
    //freq2 = freq1 + ((int)random(0, avgDiffValue)) * 30 / width;
    freq2 = map(avgDiffValue, 1, 50, min_freq, max_freq);
  else
    freq2 = 100;
  
  sine1.setFreq(freq1);
  sine2.setFreq(freq2);
  sine1.setPan(-1);
  sine2.setPan(1);
  
  
  // WAVES
  /// http://www.openprocessing.org/sketch/16770
  
  //stroke(178,18,81, 8);
  stroke(71,251,124, 8);
  strokeWeight(28);
  
  for ( int i = 0; i < out.bufferSize() - 1; i++ )
  {
    //float x1 = map(i, 0, out.bufferSize(), 0, width);
    //float x2 = map(i+1, 0, out.bufferSize(), 0, width);
    //line(x1, 50 + out.left.get(i)*50, x2, 50 + out.left.get(i+1)*50);
    //line(x1, (height/2) + out.right.get(i)*50, x2, (height/2) + out.right.get(i+1)*50);
    
    //float x1 = map(i, 0, out.bufferSize(), 170, 630);
    //float x2 = map(i+1, 0, out.bufferSize(), 170, 630);
    
    
    float x1 = map(i, 0, out.bufferSize(), 100, width-100);
    float x2 = map(i+1, 0, out.bufferSize(), 100, width-100);
    
    line(x1, 
         (height-170) + (out.left.get(i) + out.right.get(i)) * waveMod, 
         x2, 
         (height-170) + (out.left.get(i) + out.right.get(i)) * waveMod);
  }
  
  
  /// SOCIAL
  if ( requestOnlinePosts ) 
  {
    long nextRefresh = lastRefresh + refreshInterval + refreshThresh;
    
    if ( millis() > nextRefresh ) 
    {
      try 
      {
        client = new HttpClient(this, "graph.facebook.com");
        client.GET("/" + POST_ID + "/comments?fields=message,created_time");
      }
      catch (Exception x) {
        println("x");
      }
      
      lastRefresh = millis();
      showUntil = lastRefresh + refreshThresh;
    }
  }
  
  
  if ( millis() >= lastRefresh && millis() < showUntil ) 
  {
    rectMode(CENTER);
    fill(252,250,96);
    //fill(71, 251, 124);
    text(lastMessage, width/2, height/2, 300, 200);
    
    
    // take snapshots
    if ( takeSnapshots ) 
    {
      PImage frameImg = new PImage(width, height);
      loadPixels();
      frameImg.pixels = pixels;
      frameImg.updatePixels();
      
      String frameName = millis() + "_" + frameCount + "_" + floor(random(1, 1024));
      frameImg.save(savePath + frameName + saveFormat);
      
      frameName += "_rgb";
      prevFrame.save(savePath + frameName + saveFormat);
    }
  }
  else 
  {
    lastMessage = "";
  }
}



void responseReceived (HttpRequest request, HttpResponse response) 
{
  if ( response.statusCode == 200 ) 
  {
    JSONResult = response.getContentAsJSONObject();
    //println(JSONResult);
    
    com.francisli.processing.http.JSONObject lastMsgObj = JSONResult.get("data");
    
    boolean isNextComment = false;
    for ( int c = 0; c < lastMsgObj.size(); c++ ) 
    {
      String currCommentId = lastMsgObj.get(c).get("id").stringValue();
      
      // firstComment      
      if ( isNextComment || "".equals(lastCommentId) ) 
      {
        lastCommentId = currCommentId;
        
        String lastCommentMessage = lastMsgObj.get(c).get("message").stringValue();
        
        int maxLength = ( lastCommentMessage.length() < MAX_CHAR ) 
                            ? lastCommentMessage.length() : MAX_CHAR;
                            
        lastCommentMessage = lastCommentMessage.substring(0, maxLength);
        
        lastMessage = lastCommentMessage.toUpperCase();
        
        break;
      }
      
      // next check
      isNextComment = currCommentId.equals(lastCommentId);
    }
  }
  else 
  {
    //println(response.getContentAsString());
  }
}


void movieEvent (Movie m) 
{ 
  m.read();
}
