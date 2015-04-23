#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <SerialCommand.h>

// https://github.com/adafruit/Adafruit-PWM-Servo-Driver-Library
// https://github.com/kroimon/Arduino-SerialCommand

Adafruit_PWMServoDriver pwm;
SerialCommand SCmd;

#define SERVO_MIN 190
#define SERVO_MAX 460

enum joint {
  JOINT_GRIPPER = 0,
  JOINT_WRIST,
  JOINT_ELBOW,
  JOINT_SHOULDER,
  JOINT_BASE,
  JOINT_COUNT
};

// Per servo range limits for the LYNX ARM
int range[JOINT_COUNT][2] = {
 {0, 140},
 {0, 255},
 {0, 255},
 {0, 255},
 {0, 255}
};

void setPWM(int servo, int val)
{
  val = constrain(val, range[servo][0], range[servo][1]);
  pwm.setPWM(servo, 0, map(val, 0, 255, SERVO_MIN, SERVO_MAX));
}

void setPosition(int arr[])
{
  for (int i = i; i < JOINT_COUNT; i++) {
    setPWM(i, arr[i]);
  }  
}

int val[] = { 0, 0, 0, 0, 0 };
void setPositionCommand() {
  char *arg;

  for (int i=0; i < JOINT_COUNT; i++) {
    arg = SCmd.next();

    if (arg == NULL) {
      Serial.println("Not enough arguments!");
      return;
    }
    
    val[i] = atoi(arg);
  }
  
  setPosition(val);
}

void doesnotexist(const char *command) {
    Serial.println("Does not exist!");
}

void setup() {
  Serial.begin(9600);
  Serial.println("Servo arm control!");
  pwm.begin();
  pwm.setPWMFreq(60);  // Analog servos run at ~60 Hz updates
  int def_pos[] = { 0, 0, 0, 0, 0 };
  setPosition(def_pos);
  
  SCmd.addCommand("P", setPositionCommand);
  SCmd.setDefaultHandler(doesnotexist);
  
  Serial.println("READY");
}


void loop() {
  SCmd.readSerial();
}
