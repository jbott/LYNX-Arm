/**
 * Simple Write. 
 * 
 * Check if the mouse is over a rectangle and writes the status to the serial port. 
 * This example works with the Wiring / Arduino program that follows below.
 */


/*
Measurements:
l2 = 3.75 in
l1 = 3.72 in

rotation center = 186
shoulder up = 181
elbow right angle = 181
wrist right angle = 0

*/

import processing.serial.*;

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port

int[] pos = { 255, 0, 181, 181, 186 };

HScrollbar[] input = new HScrollbar[5];

void writePos( int ... pos )
{
  String val = "P ";
  for ( int p : pos )
  {
    val += p;
    val += " ";
  }
  val += '\n';
  print(val);
  myPort.write(val);
}

void setup() 
{
  size(255, 255);
  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  println(Serial.list());
  String portName = Serial.list()[1];
  myPort = new Serial(this, portName, 9600);
  
  for (int i = 0; i < input.length; i++)
  {
    input[i] = new HScrollbar(0, 32*i + 16, width, 16, 16);
    input[i].spos = pos[i];
    input[i].newspos = pos[i];
  }
  
  writePos(pos);
}

void draw() {
  background(255);
  
  for (int i = 0; i < input.length; i++)
  {
    pos[i] = (int) input[i].getPos();
    input[i].update();
    input[i].display();
  }
  writePos(pos);
}
 
 class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;

  HScrollbar (float xp, float yp, int sw, int sh, int l) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
  }

  void update() {
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
    }
  }

  float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
       mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(spos, ypos, sheight, sheight);
  }

  float getPos() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }
}
