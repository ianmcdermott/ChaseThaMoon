/**
 * Texture Sphere 
 * by Gillian Ramsay
 * 
 * Rewritten by Gillian Ramsay to better display the poles.
 * Previous version by Mike 'Flux' Chang (and cleaned up by Aaron Koblin). 
 * Original based on code by Toxi.
 * 
 * A 3D textured sphere with simple rotation control.
 */
import processing.serial.*;
int ptsW, ptsH;

PImage img;

int numPointsW;
int numPointsH_2pi; 
int numPointsH;

float[] coorX;
float[] coorY;
float[] coorZ;
float[] multXZ;
float max = 1000;
float min = 0;
float camZ = 0;
float target = 0;
Serial port;    // Create an object from Serial class
String val = "1";     // Data received from the serial port
float prevVal = 0;
int amp = 50;
int xNoiseOffset =0; 
int yNoiseOffset =876; 
int zNoiseOffset =5111; 
float freq = .001;

ArrayList<PVector> stars = new ArrayList<PVector>();
int starsAmount = 1000;

PGraphics starsGraphic;

void setup() {
  //size(1920, 1080, P3D);
  fullScreen(P3D);
  background(0);
  noStroke();
  img=loadImage("moon.png");
  ptsW=100;
  ptsH=100;
  // Parameters below are the number of vertices around the width and height
  initializeSphere(ptsW, ptsH);
  port = new Serial(this, "/dev/cu.usbmodem1411", 57600);
  starsGraphic = createGraphics(width, height);
  for (int i = 0; i < starsAmount; i++) {
    stars.add(new PVector(random(width), random(height)));
  }
}

// Use arrow keys to change detail settings
void keyPressed() {
  if (keyCode == ENTER) saveFrame();
  if (keyCode == UP) ptsH++;
  if (keyCode == DOWN) ptsH--;
  if (keyCode == LEFT) ptsW--;
  if (keyCode == RIGHT) ptsW++;
  if (ptsW == 0) ptsW = 1;
  if (ptsH == 0) ptsH = 2;
  // Parameters below are the number of vertices around the width and height
  initializeSphere(ptsW, ptsH);

  perspective(PI/3.0, (float)width/height, 1, 10000);
}

void draw() {
  background(0);

  if ( port.available() > 0)
  { // If data is available,
    val = port.readStringUntil('\n');         // read it and store it in val
  }
  if (val != null && !Float.isNaN(float(val))) {
    target = float(val)*100;
    camZ = lerp(camZ, target, 0.005);
    prevVal = target;
  } 

  //println(camZ); //print out in the console
  float dirY = (mouseY / float(height) - 0.5) * 2;
  float dirX = (mouseX / float(width) - 0.5) * 2;
  //directionalLight(204, 204, 225, -dirX, -dirY, -1); 
  spotLight(204, 204, 220, width/2, height/2, 800, -dirX, 0, -1, PI, 30);

  camera(width/2+map(width/2, 0, width, -2*width, 2*width)+noise((xNoiseOffset+frameCount)*freq)*amp, 
    height/2+map(height/2, 0, height, -2*height, 2*height)+noise((yNoiseOffset+frameCount)*freq)*amp, 
    constrain(map(camZ, 0, 10000, 10000, 0), 250+ptsW, 10000)+noise((zNoiseOffset+frameCount)*freq)*amp, 
    width/2, height/2.0, 0, 
    0, 1, 0);

  starsGraphic.beginDraw();
  starsGraphic.background(255, 0, 0);

  //starsGraphic.camera(width/2, 
  //  height/2, 
  //  -100, 
  //  width/2, height/2.0, 0, 
  //  0, 1, 0);
    
  for (int i = 0; i < starsAmount; i++) {
    int r = (int) random(3, 4.5);
    starsGraphic.ellipse(stars.get(i).x, stars.get(i).y, r, r);
  }
  starsGraphic.endDraw();

  pushMatrix();
  translate(width/2, height/2, 0);  
  rotateY(frameCount*radians(.02));
  textureSphere(200, 200, 200, img);
  popMatrix();
}

void initializeSphere(int numPtsW, int numPtsH_2pi) {

  // The number of points around the width and height
  numPointsW=numPtsW+1;
  numPointsH_2pi=numPtsH_2pi;  // How many actual pts around the sphere (not just from top to bottom)
  numPointsH=ceil((float)numPointsH_2pi/2)+1;  // How many pts from top to bottom (abs(....) b/c of the possibility of an odd numPointsH_2pi)

  coorX=new float[numPointsW];   // All the x-coor in a horizontal circle radius 1
  coorY=new float[numPointsH];   // All the y-coor in a vertical circle radius 1
  coorZ=new float[numPointsW];   // All the z-coor in a horizontal circle radius 1
  multXZ=new float[numPointsH];  // The radius of each horizontal circle (that you will multiply with coorX and coorZ)

  for (int i=0; i<numPointsW; i++) {  // For all the points around the width
    float thetaW=i*2*PI/(numPointsW-1);
    coorX[i]=sin(thetaW);
    coorZ[i]=cos(thetaW);
  }

  for (int i=0; i<numPointsH; i++) {  // For all points from top to bottom
    if (int(numPointsH_2pi/2) != (float)numPointsH_2pi/2 && i==numPointsH-1) {  // If the numPointsH_2pi is odd and it is at the last pt
      float thetaH=(i-1)*2*PI/(numPointsH_2pi);
      coorY[i]=cos(PI+thetaH); 
      multXZ[i]=0;
    } else {
      //The numPointsH_2pi and 2 below allows there to be a flat bottom if the numPointsH is odd
      float thetaH=i*2*PI/(numPointsH_2pi);

      //PI+ below makes the top always the point instead of the bottom.
      coorY[i]=cos(PI+thetaH); 
      multXZ[i]=sin(thetaH);
    }
  }
}

void textureSphere(float rx, float ry, float rz, PImage t) { 
  // These are so we can map certain parts of the image on to the shape 
  float changeU=t.width/(float)(numPointsW-1); 
  float changeV=t.height/(float)(numPointsH-1); 
  float u=0;  // Width variable for the texture
  float v=0;  // Height variable for the texture

  beginShape(TRIANGLE_STRIP);
  texture(t);
  for (int i=0; i<(numPointsH-1); i++) {  // For all the rings but top and bottom
    // Goes into the array here instead of loop to save time
    float coory=coorY[i];
    float cooryPlus=coorY[i+1];

    float multxz=multXZ[i];
    float multxzPlus=multXZ[i+1];

    for (int j=0; j<numPointsW; j++) { // For all the pts in the ring
      normal(-coorX[j]*multxz, -coory, -coorZ[j]*multxz);
      vertex(coorX[j]*multxz*rx, coory*ry, coorZ[j]*multxz*rz, u, v);
      normal(-coorX[j]*multxzPlus, -cooryPlus, -coorZ[j]*multxzPlus);
      vertex(coorX[j]*multxzPlus*rx, cooryPlus*ry, coorZ[j]*multxzPlus*rz, u, v+changeV);
      u+=changeU;
    }
    v+=changeV;
    u=0;
  }
  endShape();
}
