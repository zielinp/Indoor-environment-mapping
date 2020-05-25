/*
  Scanse Sweep Arduino Library Examples

  Created by Scanse LLC, February 21, 2017.
  Released into the public domain.
  
  Modified by zielinp, March 20, 2019
*/

#include <Sweep.h>
#include <Servo.h>

// create servo object to control a servo
Servo servoLidar;

// analog pin used to connect servo
#define SERVO_LIDAR_PIN 53
uint8_t servoLidarPos = 0;



// Create a Sweep device using Serial #1 (RX1 & TX1)
Sweep device(Serial1);

// keeps track of how many scans have been collected
uint8_t scanCount = 0;
// keeps track of how many samples have been collected
uint16_t sampleCount = 0;
uint16_t lastData = 0;



// Arrays to store attributes of collected scans
bool syncValues[600];         // 1 -> first reading of new scan, 0 otherwise
float angles[600];            // in degrees (accurate to the millidegree)
uint16_t distances[600];      // in cm
uint8_t signalStrengths[600]; // 0:255, higher is better

// Finite States for the program sequence
const uint8_t STATE_WAIT_FOR_USER_INPUT = 0;
const uint8_t STATE_ADJUST_DEVICE_SETTINGS = 1;
const uint8_t STATE_VERIFY_CURRENT_DEVICE_SETTINGS = 2;
const uint8_t STATE_BEGIN_DATA_ACQUISITION = 3;
const uint8_t STATE_GATHER_DATA = 4;
const uint8_t STATE_STOP_DATA_ACQUISITION = 5;
const uint8_t STATE_REPORT_COLLECTED_DATA = 6;
const uint8_t STATE_RESET = 7;
const uint8_t STATE_ERROR = 8;

// Current state in the program sequence
uint8_t currentState;

// String to collect user input over serial
char userInput = 's';

void setup()
{

  // Initialize serial
  Serial.begin(115200);    // serial terminal on the computer
  Serial1.begin(115200); // sweep device
  reset();

  // attaches the servo on pin 9 to the servo object
  servoLidar.attach(SERVO_LIDAR_PIN);
  int pos = 0;
  //roztuch serwa
  for (pos = 0; pos <= 180; pos += 1) { // goes from 0 degrees to 180 degrees
    // in steps of 1 degree
    servoLidar.write(pos);              // tell servo to go to position in variable 'pos'
    delay(15);                       // waits 15ms for the servo to reach the position
  }
  for (pos = 180; pos >= 0; pos -= 1) { // goes from 180 degrees to 0 degrees
    servoLidar.write(pos);              // tell servo to go to position in variable 'pos'
    delay(15);                       // waits 15ms for the servo to reach the position
  }

  // reserve space to accumulate user message
  //  userInput.reserve(50);

  // initialize counter variables and reset the current state

}

// Loop functions as an FSM (finite state machine)
void loop()
{
  switch (currentState)
  {
    case STATE_WAIT_FOR_USER_INPUT:
      if (listenForUserInput() == true)
        currentState = STATE_ADJUST_DEVICE_SETTINGS;
      // currentState = STATE_BEGIN_DATA_ACQUISITION;
      break;

    case STATE_ADJUST_DEVICE_SETTINGS:
      if (adjustDeviceSettings() == true)
        currentState = STATE_VERIFY_CURRENT_DEVICE_SETTINGS;
      else
        currentState = STATE_ERROR;
      break;

    case STATE_VERIFY_CURRENT_DEVICE_SETTINGS:
      currentState = verifyCurrentDeviceSettings() ? STATE_BEGIN_DATA_ACQUISITION : STATE_ERROR;
      break;

    case STATE_BEGIN_DATA_ACQUISITION:
      currentState = beginDataCollectionPhase(servoLidarPos) ? STATE_GATHER_DATA : STATE_ERROR;
      break;

    case STATE_GATHER_DATA:
      gatherSensorReading();
      if (scanCount > 1)
      { scanCount = 0;
        currentState = STATE_STOP_DATA_ACQUISITION;
        //currentState = STATE_REPORT_COLLECTED_DATA;
      }
      break;

    case STATE_STOP_DATA_ACQUISITION:
      currentState = stopDataCollectionPhase() ? STATE_REPORT_COLLECTED_DATA : STATE_ERROR;
      break;

    case STATE_REPORT_COLLECTED_DATA:
      printCollectedData();
      servoLidarPos++;
      servoLidar.write(servoLidarPos);
      if (servoLidarPos > 180) {
        currentState =  STATE_RESET;
        servoLidarPos = 0;
      }
      else // currentState = STATE_RESET;
      {
        currentState = STATE_BEGIN_DATA_ACQUISITION;
      }
      break;

    case STATE_RESET:
      Serial.println("\n\nAttempting to reset and run the program again...");
      reset();
      currentState = STATE_WAIT_FOR_USER_INPUT;
      break;

    default: // there was some error
      Serial.println("An error occured. Attempting to reset and run program again...");
      reset();
      currentState = STATE_WAIT_FOR_USER_INPUT;
      break;
  }
}

// checks if the user has communicated anything over serial
// looks for the user to send "start"
bool listenForUserInput()
{
  // while (Serial.available())
//  while (true)
//  {
//    userInput = (char)Serial.read();
//  }
  if (userInput == 's')
  {
    Serial.println("Registered user start.");
    return true;
  }
  return false;
}

// Adjusts the device settings
bool adjustDeviceSettings()
{
  // Set the motor speed to 5HZ (codes available from 1->10 HZ)
  bool bSuccess = device.setMotorSpeed(MOTOR_SPEED_CODE_2_HZ);
  Serial.println(bSuccess ? "\nSuccessfully set motor speed." : "\nFailed to set motor speed");

  /*
    // Device will always default to 500HZ scan rate when it is powered on.
    // Snippet below is left for reference.
    // Set the sample rate to 500HZ (codes available for 500, 750 and 1000 HZ)
    bool bSuccess = device.setSampleRate(SAMPLE_RATE_CODE_500_HZ);
    Serial.println(bSuccess ? "\nSuccessfully set sample rate." : "\nFailed to set sample rate.");
  */
  return bSuccess;
}

// Querries the current device settings (motor speed and sample rate)
// and prints them to the console
bool verifyCurrentDeviceSettings()
{
  // Read the current motor speed and sample rate
  int32_t currentMotorSpeed = device.getMotorSpeed();
  if (currentMotorSpeed < 0)
  {
    Serial.println("\nFailed to get current motor speed");
    return false;
  }
  int32_t currentSampleRate = device.getSampleRate();
  if (currentSampleRate < 0)
  {
    Serial.println("\nFailed to get current sample rate");
    return false;
  }

  // Report the motor speed and sample rate to the computer terminal
  Serial.println("\nMotor Speed Setting: " + String(currentMotorSpeed) + " HZ");
  Serial.println("Sample Rate Setting: " + String(currentSampleRate) + " HZ");

  return true;
}

// Initiates the data collection phase (begins scanning)
bool beginDataCollectionPhase(int x)
{
  // Attempt to start scanning
  if (!x) {
    Serial.println("\nWaiting for motor speed to stabilize and calibration routine to complete...");
  }
  bool bSuccess = device.startScanning();

  if (!x) {
    Serial.println(bSuccess ? "\nSuccessfully initiated scanning..." : "\nFailed to start scanning.");
    if (bSuccess)
      Serial.println("\nGathering 3 scans...");
    Serial.println("n");
  }

  return bSuccess;
}

// Gathers individual sensor readings until 3 complete scans have been collected
void gatherSensorReading()
{
  // attempt to get the next scan packet
  // Note: getReading() will write values into the "reading" variable
  bool success = false;
  ScanPacket reading = device.getReading(success);
  if (success)
  {
    // check if this reading was the very first reading of a new 360 degree scan
    // don't collect more than 3 scans

    if (reading.isSync())
    {
      if (scanCount == 0)
        sampleCount = 0;

      //if(scanCount==1)
      // lastData=sampleCount;

      // lastData=sampleCount;

      scanCount++;

      if (scanCount > 1)
        lastData = sampleCount;

      return;
    }

    // store the info for this sample
    syncValues[sampleCount] = reading.isSync();
    angles[sampleCount] = reading.getAngleDegrees();
    distances[sampleCount] = reading.getDistanceCentimeters();
    signalStrengths[sampleCount] = reading.getSignalStrength();

    // increment sample count
    sampleCount++;
  }
}

// Terminates the data collection phase (stops scanning)
bool stopDataCollectionPhase()
{
  // Attempt to stop scanning
  bool bSuccess = device.stopScanning();

  // Serial.println(bSuccess ? "\nSuccessfully stopped scanning." : "\nFailed to stop scanning.");
  return bSuccess;
}

// Prints the collected data to the console
// (only prints the complete scans, ignores the first partial)
void printCollectedData()
{
  // print the readings for all the complete scans
  for (int i = 0; i < lastData; i++)
  {
    // if (syncValues[i])

    Serial.println(String(angles[i], 3) + " " + String(distances[i]) + " " + String(signalStrengths[i]));
  }
  // Serial.println("e");
  Serial.println("401 ");

  //
}

// Resets the variables and state so the sequence can be repeated
void reset()
{
  scanCount = 0;
  sampleCount = 0;
  // reset the sensor
  device.reset();
  delay(50);
  Serial.flush();
  //userInput = 'x';
  Serial.println("\n\nWhenever you are ready, type \"s\" to to begin the sequence...");
  currentState = 0;
}
