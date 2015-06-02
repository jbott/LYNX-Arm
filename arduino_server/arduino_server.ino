#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <SerialCommand.h>

#include "AngleServo.h"

// https://github.com/adafruit/Adafruit-PWM-Servo-Driver-Library
// https://github.com/kroimon/Arduino-SerialCommand

Adafruit_PWMServoDriver pwm;
SerialCommand SCmd;

enum pwm_joint {
  PWM_GRIPPER = 0,
  PWM_WRIST,
  PWM_ELBOW,
  PWM_SHOULDER,
  PWM_BASE,
  PWM_COUNT
};

enum servo_joint {
  SERVO_BASE = 0,
  SERVO_SHOULDER,
  SERVO_ELBOW,
  SERVO_WRIST,
  SERVO_GRIPPER,
  SERVO_COUNT
};

AngleServo *servos[SERVO_COUNT];

void getPositionCommand() {
  Serial.print("GP");
  for (int i=0; i < SERVO_COUNT; i++) {
    if (servos[i] != NULL) {
      Serial.print(" ");
      Serial.print(i);
      Serial.print(":");
      Serial.print(servos[i]->get());
    }
  }
  Serial.println();
}

void setPositionCommand() {
  char *arg;

  for (int i=0; i < SERVO_COUNT; i++) {
    arg = SCmd.next();

    if (arg == NULL) {
      Serial.println("Not enough arguments!");
      return;
    }
    
    if (servos[i] != NULL)
      servos[i]->set(atoi(arg));
  }
}

void getAngleCommand() {
  Serial.print("GA");
  for (int i=0; i < SERVO_COUNT; i++) {
    if (servos[i] != NULL) {
      Serial.print(" ");
      Serial.print(i);
      Serial.print(":");
      Serial.print(servos[i]->getAngle());
    }
  }
  Serial.println();
}

void setAngleCommand() {
  char *arg;

  for (int i=0; i < SERVO_COUNT; i++) {
    arg = SCmd.next();

    if (arg == NULL) {
      Serial.println("Not enough arguments!");
      return;
    }
    
    if (servos[i] != NULL)
      servos[i]->setAngle(atoi(arg));
  }
}

void doesnotexist(const char *command) {
    Serial.println("Does not exist!");
}

void init_servos()
{
  /*==== BASE ====*/
  servo_calibration c_base;
  c_base.pwm_center = 320;
  c_base.pwm_range = 320 - 170;
  c_base.angle_center = 90;
  c_base.angle_range = 80;

  servos[SERVO_BASE] = new AngleServo(&pwm, PWM_BASE, c_base);
  servos[SERVO_BASE]->setAngle(90);

  /*==== SHOULDER ====*/
  servo_calibration c_shoulder;
  c_shoulder.pwm_center = 320;
  c_shoulder.pwm_range = 320 - 170;
  c_shoulder.angle_center = 90;
  c_shoulder.angle_range = 90;

  servos[SERVO_SHOULDER] = new AngleServo(&pwm, PWM_SHOULDER, c_shoulder);
  servos[SERVO_SHOULDER]->setAngle(90);

  /*==== ELBOW ====*/
  servo_calibration c_elbow;
  c_elbow.pwm_center = 320;
  c_elbow.pwm_range = -(320 - 170);
  c_elbow.angle_center = 90;
  c_elbow.angle_range = 90;

  servos[SERVO_ELBOW] = new AngleServo(&pwm, PWM_ELBOW, c_elbow);
  servos[SERVO_ELBOW]->setAngle(90);

  /*==== WRIST ====*/
  servo_calibration c_wrist;
  c_wrist.pwm_center = 310;
  c_wrist.pwm_range = -(320 - 170);
  c_wrist.angle_center = 180;
  c_wrist.angle_range = -90;
  c_wrist.angle_constrain_min = 90;
  c_wrist.angle_constrain_max = 270;

  servos[SERVO_WRIST] = new AngleServo(&pwm, PWM_WRIST, c_wrist);
  servos[SERVO_WRIST]->setAngle(180);

  /*==== GRIPPER ====*/
  servo_calibration c_gripper;
  c_gripper.pwm_center = 320;
  c_gripper.pwm_range = (320 - 170);
  c_gripper.angle_center = 0;
  c_gripper.angle_range = 90;
  c_gripper.angle_constrain_min = 0;
  c_gripper.angle_constrain_max = 60;

  servos[SERVO_GRIPPER] = new AngleServo(&pwm, PWM_GRIPPER, c_gripper);
  servos[SERVO_GRIPPER]->setAngle(0);
}

void setup() {
  Serial.begin(9600);
  Serial.println("Servo arm control!");

  pwm.begin();
  pwm.setPWMFreq(50);

  init_servos();

  SCmd.addCommand("P", setPositionCommand);
  SCmd.addCommand("GP", getPositionCommand);
  SCmd.addCommand("A", setAngleCommand);
  SCmd.addCommand("GA", getAngleCommand);
  SCmd.setDefaultHandler(doesnotexist);

  Serial.println("READY");
}


void loop() {
  SCmd.readSerial();
}
