# This requires the LEAP sdk in ../../LeapSDK
# pyserial should also be installed from pypi

import os, sys, inspect, thread, time
from time import sleep
src_dir = os.path.dirname(inspect.getfile(inspect.currentframe()))
lib_dir = '../../LeapSDK/lib'
sys.path.insert(0, os.path.abspath(os.path.join(src_dir, lib_dir)))
arch_dir = '../../LeapSDK/lib/x86'
sys.path.insert(0, os.path.abspath(os.path.join(src_dir, arch_dir)))

import Leap

from Leap import CircleGesture, KeyTapGesture, ScreenTapGesture, SwipeGesture

import serial, math

def arduino_map(x, in_min, in_max, out_min, out_max):
    return (x - in_min) * (out_max - out_min) // (in_max - in_min) + out_min

def constrain(x, in_min, in_max):
    return min(max(x, in_min), in_max)

def center(x, x_center, center, per):
    return (x - x_center) * per + center

class Arm:
    port = None

    msg = "A {} {} {} {} {}\n"
    pos = [ 90, 90, 90, 180, 0 ]

    center = [ 90, 90, 90, 180, 0 ]

    grip     = 4
    wrist    = 3
    elbow    = 2
    shoulder = 1
    base     = 0

    def set( self, offset, val ):
        self.pos[offset] = val

    def get_msg( self, arr ):
        new = []
        for a in arr:
            new.append(int(a))
        return self.msg.format(*new)

    def update( self ):
        print self.get_msg(self.pos)
        if self.port != None:
            self.port.write(self.get_msg(self.pos))
            self.port.flush()

    def __init__( self, com ):
        print "Arm init!"
        try:
            self.port = serial.Serial(com);
            self.port.flush()
        except:
            print "No serial port!"
        # Wait for arduino reset
        sleep(5)



class SampleListener(Leap.Listener):
    arm = Arm("COM14")

    def on_init(self, controller):
        print "Initialized"

    def on_connect(self, controller):
        print "Connected"

    def on_disconnect(self, controller):
        # Note: not dispatched when running in a debugger.
        print "Disconnected"

    def on_exit(self, controller):
        print "Exited"

    def on_frame(self, controller):
        # Get the most recent frame and report some basic information
        frame = controller.frame()

	if (frame.id % 10 == 0 or len(frame.hands) > 0):
            print "Frame id: %d, timestamp: %d, hands: %d" % (
                frame.id, frame.timestamp, len(frame.hands))

        # Get hand's position
        if len(frame.hands) == 2:
            grab_hand = frame.hands.leftmost
            hand = frame.hands.rightmost

            position = hand.palm_position
            grab = grab_hand.grab_strength

            print "pos: {}".format(position)
            print "grab: {}".format(grab)

            # Grabber
            self.arm.set(Arm.grip, grab * 60 * 2)

            # Y and Z

	    y_in = constrain(position.y / 25 - 4, 0, 3.75 * 2)
	    z_in = constrain(-position.z / 25 + 6, 0, 3.75 * 2)

	    print "height: {}".format(y_in)
	    print "dist: {}".format(z_in)

            length = math.sqrt(z_in*z_in + y_in*y_in) # Pythagorean
	    print "tri_length: {}".format(length)

            l = 3.75

            # Essentially an isoceles triangle
            # topang
            # |\
            # | \
            # |  \ l
            # |   \
            # |____\ botang
            #   length / 2


            topang = math.degrees(2 * math.asin((length / 2) / l))
            print "topang: {}".format(topang)
	    self.arm.set(Arm.elbow, topang)

            botang = math.degrees(math.acos((length / 2) / l) + math.atan(y_in / z_in))
            print "botang: {}".format(botang)
	    self.arm.set(Arm.shoulder, botang)


            # Wrist
            wristang = 90 + (180 - topang - botang)
	    print "wrist: {}".format(wristang)

            # Wrist angle
	    wristoffset = wristang + (grab_hand.palm_position.y - 200)
	    print "wristoffset: {}".format(wristoffset)

            self.arm.set(Arm.wrist, wristoffset)

            # Base
            self.arm.set(Arm.base, position.x / 2  + Arm.center[Arm.base] - 30) # At x = zero, set to center

            self.arm.update()


    def state_string(self, state):
        if state == Leap.Gesture.STATE_START:
            return "STATE_START"

        if state == Leap.Gesture.STATE_UPDATE:
            return "STATE_UPDATE"

        if state == Leap.Gesture.STATE_STOP:
            return "STATE_STOP"

        if state == Leap.Gesture.STATE_INVALID:
            return "STATE_INVALID"

def main():
    print "Initializing..."
    # Create a sample listener and controller
    listener = SampleListener()
    controller = Leap.Controller()

    # Have the sample listener receive events from the controller
    controller.add_listener(listener)

    # Keep this process running until Enter is pressed
    print "Press Enter to quit..."
    try:
        sys.stdin.readline()
    except KeyboardInterrupt:
        pass
    finally:
        # Remove the sample listener when done
        controller.remove_listener(listener)


if __name__ == "__main__":
    main()
