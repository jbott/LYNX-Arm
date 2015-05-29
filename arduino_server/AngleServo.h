#include <Adafruit_PWMServoDriver.h>

struct servo_calibration {
  int pwm_center;
  int pwm_range;
  int angle_center;
  int angle_range;
};

class AngleServo {
  public:
    AngleServo(Adafruit_PWMServoDriver *pwm, const int index, const servo_calibration calib);
    void setAngle(const int val);
    void setRaw(const int val);
    void set(const int val);
    
    int getAngle();
    int getRaw();
    int get();
    
  private:
    Adafruit_PWMServoDriver *pwm;
    int index;
    servo_calibration calibration;
    int set_val;
};
