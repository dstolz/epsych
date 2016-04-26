/*
  MRI Cryoloop Temperature Control and Scan Triggering

  Interface with LumaSense Luxtron 912 fiber optic thermometer and
  5V TTL trigger from external source (typically fMRI scanner)

  Suggested use from PC software:
  1. An interrupt is triggered on the rising edge of a 5V pulse to the TTL Trigger digital line.
      > Once triggered, the time (in milliseconds) elapsed since powering on the Arduino
        is printed to the PC Serial buffer. This timestamp acts as both indication that a trigger
				has occured and the time at which it happened (relative to powering on the Aurduino).
  2. Once a trigger is detected, present some stimulus using external hardware
  3. Poll Arduino for current probe temperature using the command 'c,0' for probe
     channel 1, or 'c,1' for probe channel 2


  Hardware:
  1. Arduino Due
  2. Homemade RS232 shield based around MAXIM MAX3323EEPE
  3. Pin configuration:
     > L812 RX      -    19
     > L812 TX      -    18
     > RxTxLED      -    13
     > TTL Trigger  -     3
  4. LumaSense Technologies Luxtron 812 Fiber Optic Thermometer base station
  5. FMI Lab Pump Model RHB RH0CKC
  6. Pololu High-Power Motor Driver 18v15 (Pololu item# 755)
  7. 12V 5A DC Power Supply (Pololu item# 1465; also item# 2449)
  8. (optional) Analog temperature input to A0 from BAT-12 module

  Notes:
  1. On startup (setup), the Arduino will send the following commands to the Luxtron 812:
     > 'Ctrl+T'    -    Exit Standby Mode
     > 'Ctrl+E'    -    Enable Remote Control Mode
	2. Power on the Luxtron 812 and allow it ~30 seconds to startup before powering on the Arduino (or reset the Arduino)
	3. See SerialCom.ino for Serial Communications commands
	4. INO files required for this project:
			1. MRICryoloopControl.ino (this file)
			2. Luxtron812.ino
			3. PumpControl.ino
			4. SerialCom.ino

  Daniel.Stolzberg@gmail.com  9/2015
*/







#include <stdlib.h>
#include <PID_v1.h>











// Luxtron 812 Com ////////////////////////////////
#define NumProbes 1

#define CR 13
#define LF 10


byte rx = 18;
byte tx = 19;

byte RxTxLED = 13;
float probeTemp[NumProbes];


unsigned long LastTempTime = 0;
///////////////////////////////////////////////////

















// PID Pump Control ///////////////////////////////
# define NumOfPumps 1

// Pump control PWM pinouts
int PWM_Pump[NumOfPumps] = {8};
int PANEL_LED_PUMP[NumOfPumps] = {9};

// PWM rate for manual speed control
double PWMspeed[NumOfPumps];

// PID controller
double consKp[NumOfPumps], consKi[NumOfPumps], consKd[NumOfPumps];
double aggrKp[NumOfPumps], aggrKi[NumOfPumps], aggrKd[NumOfPumps];

double Setpoint[NumOfPumps], Input[NumOfPumps], Output[NumOfPumps];

PID myPID[NumOfPumps];

int Gap = 5;

unsigned long LastPIDTime = 0;
unsigned long PollInterval = 250;

///////////////////////////////////////////////////





















// MRI Scan Trigger ///////////////////////////////
int TRIGGERpin = 3;
int MANUAL_TRIGGERpin = 50;
int PANEL_LED_TTL = 22;
volatile unsigned long RecentTrigTime = 0;
volatile boolean TTLState = false;
///////////////////////////////////////////////////





// Analog temperature input ///////////////////////
boolean useAnalogTemp = false;
int TEMPpins [A0];
///////////////////////////////////////////////////














void setup() {
  InitializeTrig();
  InitializeL812();
  InitializePump();



  // for communication with PC
  Serial.begin(57600);
  while (!Serial) { }
  Serial.setTimeout(1);
  Serial.println('R'); // Send ready signal to PC



}



















void loop() {




  // MRI Scan Trigger ///////////////////////////////
  if (!digitalRead(MANUAL_TRIGGERpin)) {
    TTL_DETECT();
    digitalWrite(PANEL_LED_TTL, HIGH);
    delay(50);
    digitalWrite(PANEL_LED_TTL, LOW);
  }

  if (TTLState) {
    Serial.print("TTL");
    Serial.println(RecentTrigTime); // Prints the number of milliseconds since Ardunio started running to the buffer
    TTLState = false;
  }
  digitalWrite(PANEL_LED_TTL, digitalRead(TRIGGERpin));
  ///////////////////////////////////////////////////







  unsigned long CurTime = millis();

  // Update Temperature Readings ////////////////////
  if (CurTime - LastTempTime >= PollInterval) {
    if (useAnalogTemp) {
      UpdateAnalogTemps();  
    } else {
      UpdateTemps();
    }
    
    LastTempTime = CurTime;
  }
  ///////////////////////////////////////////////////



  // Pump Control ///////////////////////////////////
  if (CurTime - LastPIDTime >= PollInterval) {
    for (int ID = 0; ID < NumOfPumps; ID++) {
      if (myPID[ID].GetMode()) {
        PIDfun(ID);
      }

     analogWrite(PANEL_LED_PUMP[ID], PWMspeed[ID]); // Tells us if pump is on
    }
    LastPIDTime = CurTime;
  }
  ///////////////////////////////////////////////////



}














// MRI Scan Trigger ///////////////////////////////
void InitializeTrig() {
  pinMode(MANUAL_TRIGGERpin, INPUT_PULLUP);
  pinMode(TRIGGERpin, INPUT);
  attachInterrupt(digitalPinToInterrupt(TRIGGERpin), TTL_DETECT, RISING); // interrupt unreliable?
  pinMode(PANEL_LED_TTL, OUTPUT);
  digitalWrite(PANEL_LED_TTL, LOW);

}













// MRI Scan Trigger Interrupt /////////////////////
void TTL_DETECT() {
  // It can be > 200 ms since the last call because of code overhead so make sure TTL trigger is longer (> 300 ms)
  
  if (millis() - RecentTrigTime > 10) { // simple debouncing timeout for 10 ms
    RecentTrigTime = millis();
    TTLState = true;
  }
}
































