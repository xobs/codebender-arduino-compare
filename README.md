Codebender / Arduino Comparison Infrastructure
==============================================

These scripts allow you to compare the Examples between the Arduino IDE and the Codebender
test infrastructure.  It works by passing a file to both Codebender and Arduino, and
comparing the resulting binary.

If Codebender is working correctly, it should produce the exact same output as Arduino.


Setup
-----

In order to use this, the Arduino IDE must have the same version of the Arduino packages
installed as Codebender.  Otherwise, the two will produce slightly different outputs, which
will needlessly fail the test.

To install the proper version, open the Arduino IDE and navigate to

    Tools ->
        Board ->
            Boards Manager

Search for:

    arduino avr

Select "Arduino AVR Boards" and install "1.6.9".

Next, search for:

    arduino arm

Select "Arduino SAM Boards (32-bits ARM Cortex-M3) and install "1.6.6".


Running
-------

To run the tests, use either wrap-build.sh or wrap-wrap-build.sh.

wrap-build.sh will call both Arduino and Codebender and compare the results.  You must
specify the path to an .ino file as well as an FQBN.  The Arduino examples are packaged
along with this script, so you might run:

    ./wrap-build.sh ./01.Basics/AnalogReadSerial/ arduino:sam:arduino_due_x

Which would produce the following output:

    OK                                   arduino:sam:arduino_due_x  ./01.Basics/AnalogReadSerial/

Note that some Examples fail on the Arduino IDE, and so the outputs naturally would differ.
For example:

    ./wrap-build.sh ./02.Digital/toneKeyboard arduino:sam:arduino_due_x

This command produces the following output:

    ARDUINO FAILURE                      arduino:sam:arduino_due_x  ./02.Digital/toneKeyboard

To run all tests in the current directory, use wrap-wrap-build.sh.
