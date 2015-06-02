#include "AngleServo.h"

AngleServo::AngleServo(Adafruit_PWMServoDriver *pwm, const int index, const servo_calibration calib)
{
  this->pwm = pwm;
  this->index = index;
  this->calibration = calib;
}

void
AngleServo::setAngle(const int val)
{
  int newval;
  if (calibration.angle_constrain_min != 0 || calibration.angle_constrain_max != 0) {
    newval = constrain(val,
    calibration.angle_constrain_min,
    calibration.angle_constrain_max);
  } else {
    newval = constrain(val,
    calibration.angle_center - calibration.angle_range,
    calibration.angle_center + calibration.angle_range);
  }
  setRaw(map(newval,
    calibration.angle_center - calibration.angle_range, calibration.angle_center + calibration.angle_range,
    calibration.pwm_center - calibration.pwm_range,
    calibration.pwm_center + calibration.pwm_range
    ));
}

void
AngleServo::setRaw(const int val)
{
  this->set_val = val;
  pwm->setPWM(index, 0, val);
}

void
AngleServo::set(const int val)
{
  setRaw(map(constrain(val, 0, 255), 0, 255,
    calibration.pwm_center - calibration.pwm_range,
    calibration.pwm_center + calibration.pwm_range
    ));
}

int
AngleServo::get()
{
  return map(getRaw(),
    calibration.pwm_center - calibration.pwm_range,
    calibration.pwm_center + calibration.pwm_range,
    0, 255
    );
}

int
AngleServo::getRaw()
{
  return set_val;
}

int
AngleServo::getAngle()
{
  return map(getRaw(),
    calibration.pwm_center - calibration.pwm_range,
    calibration.pwm_center + calibration.pwm_range,
    calibration.angle_center - calibration.angle_range,
    calibration.angle_center + calibration.angle_range
    );
}
