import java.awt.*;
import java.awt.event.*;
import processing.serial.*;

// Constants
int W_WIDTH = 500;
int W_HEIGHT = 550;

int XPADDING = 130;
int YROW_HEIGHT = 170;
int WIDGET_WIDTH = 200;
int WIDGET_HEIGHT = 200;

// We have 5 joints to control
RadialInput in[] = new RadialInput[5];
int cur_pos[] = new int[5];

String serialPort = "NULL";
Serial serial = null;

void setup()
{
  // Create indicators for each position
  size(W_WIDTH, W_HEIGHT);
  in[0] = new RadialInput( XPADDING, YROW_HEIGHT, WIDGET_WIDTH, WIDGET_HEIGHT );
  in[0].setTitle("BASE");

  in[1] = new RadialInput( W_WIDTH - XPADDING, YROW_HEIGHT, WIDGET_WIDTH, WIDGET_HEIGHT );
  in[1].setTitle("SHOULDER");

  in[2] = new RadialInput( XPADDING, YROW_HEIGHT * 2, WIDGET_WIDTH, WIDGET_HEIGHT );
  in[2].setTitle("ELBOW");

  in[3] = new RadialInput( W_WIDTH - XPADDING, YROW_HEIGHT * 2, WIDGET_WIDTH, WIDGET_HEIGHT );
  in[3].setTitle("WRIST");

  in[4] = new RadialInput( XPADDING, YROW_HEIGHT * 3, WIDGET_WIDTH, WIDGET_HEIGHT );
  in[4].setTitle("GRIPPER");

  // Create COM port list
  MenuBar menu = new MenuBar();

  //create the top level button
  Menu topButton = new Menu("Serial Port");

  for (String port : Serial.list()) {
    MenuItem item = new MenuItem(port);
    item.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent e) {
        MenuItem item = (MenuItem)(e.getSource());
        if (item != null) {
          initSerial(item.getLabel());
        }
      }
    });
    topButton.add(item);
  }

  //add the button to the menu
  menu.add(topButton);

  //add the menu to the frame
  frame.setMenuBar(menu);

  initSerial(serialPort);
}

void draw()
{
  // 8x anti-aliasing
  smooth(8);

  // Black background
  background(0);

  for (RadialInput input : in)
  {
    if (input != null) {
      input.update();
      input.display();
    }
  }

  for (int i = 0; i < in.length; i++)
  {
    if (in[i] != null)
    {
      cur_pos[i] = (int)in[i].getPos();
    } else {
      cur_pos[i] = -1;
    }
  }

  writeSerial(cur_pos);

  // Bottom box
  int upperLeftX = width - XPADDING - WIDGET_WIDTH/2;
  int upperLeftY = (3*YROW_HEIGHT - WIDGET_HEIGHT/2) - 10;
  noFill();
  stroke(130);
  strokeWeight(2);
  strokeCap(PROJECT);
  line((float)upperLeftX, (float)upperLeftY, (float)width, (float)upperLeftY);
  line((float)upperLeftX, (float)upperLeftY, (float)upperLeftX, (float)height);

  // Title
  stroke(255);
  textAlign(CENTER, BOTTOM);
  textSize(25);
  text("DIAG", (float)(width - XPADDING), (float)(upperLeftY - 10));

  // Text
  textAlign(LEFT, TOP);
  textSize(18);
  text(String.format("SERIAL: %s\n", serialPort), (float)(upperLeftX + 10), (float)(upperLeftY + 10));
}

void initSerial(String port) {
  serialPort = port;
  if (port.equals("NULL")) {
    serial = null;
    return;
  }
  serial = new Serial(this, port, 9600);
}

void writeSerial( int ... pos )
{
  // Assemble command
  String str = "A ";
  for ( int p : pos )
  {
    str += p;
    str += " ";
  }
  str += '\n';
  print(serialPort);
  print(": ");
  print(str);

  // Write to hardware
  if (serial != null)
  {
    serial.write(str);
  }
}

void mousePressed()
{
  for (RadialInput input : in)
  {
    if (input != null) {
      input.mousePressed();
    }
  }
}

class RadialInput
{
  private int x, y, w, h;
  private double min, max, pos;
  private boolean clicked = false;
  private String title = "";
  private String numFormat = "%.0f";

  RadialInput( double min, double max, double pos, int x, int y, int w, int h )
  {
    this.min = min;
    this.max = max;
    this.pos = pos;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  RadialInput( int x, int y, int w, int h )
  {
    this(0d, 180d, 90d, x, y, w, h);
  }

  double getPos()
  {
    return pos;
  }

  void setTitle(String title)
  {
    this.title = title;
  }

  void setNumFormat(String numFormat)
  {
    this.numFormat = numFormat;
  }

  void mousePressed()
  {
    if ((mouseX > x - w/2 && mouseX < x + w/2) &&
      (mouseY > y - h/2 && mouseY < y)) // ONLY GO TO y TO LIMIT TO TOP HALF OF CIRCLE
    {
      // Start inside
      clicked = true;
    }
  }

  void update()
  {
    if (clicked)
    {
      clicked = mousePressed;
    }
    if (!clicked) {
      return;
    }

    int val = (mouseX - x + w/2);
    int norm = Math.max(0, Math.min(w, val));
    pos = (float(norm) / w * (max - min)) + min;
  }

  void display()
  {
    // Outside arc
    noFill();
    stroke(130);
    strokeWeight(3);
    strokeCap(PROJECT);
    arc((float)x, (float)y, (float)(w + 17), (float)(h + 17), -PI, 0f);

    // Inside arc
    arc((float)x, (float)y, (float)(w - 17), (float)(h - 17), -PI, 0f);

    // End caps
    line((float)(x - w/2 - 17/2), (float)y, (float)(x - w/2 + 17/2), (float)y);
    line((float)(x + w/2 - 17/2), (float)y, (float)(x + w/2 + 17/2), (float)y);

    // Value arc
    noFill();
    stroke(255);
    strokeWeight(15);
    strokeCap(SQUARE);
    // (POS - MIN) / (MAX - MIN)
    arc((float)x, (float)y, (float)w, (float)h, - PI, (float)( -PI + ( PI * (pos - min) / (max - min) )));

    // Text
    if (clicked)
    {
      stroke(100);
    } else {
      stroke(255);
    }
    textAlign(CENTER, BOTTOM);
    textSize(20);
    text(String.format(numFormat, pos), (float)x, (float)y);

    // Title
    textSize(25);
    text(title, (float)x, (float)(y - h/2 - 20));
  }
}

