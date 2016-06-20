




#include "stdlib.h"
#include "PID_v1.h"


#include "PlayingWithFusion_MAX31856.h"
#include "PlayingWithFusion_MAX31856_STRUCT.h"
#include "SPI.h"






// Thermocouple Shield SEN-30007 //////////////////////////////////
boolean ActiveTC[] = {1,0,0,0}; // which thermocouples are currently available

uint8_t TC0_CS  = 10;
uint8_t TC1_CS  =  9;
uint8_t TC2_CS  =  8;
uint8_t TC3_CS  =  7;
uint8_t TC0_FAULT = 2;                     // not used in this example, but needed for config setup
uint8_t TC0_DRDY  = 2;                     // not used in this example, but needed for config setup


// TC channels seem to be mapped in reverse on the SEN-30007 shield??? DJS
PWF_MAX31856  thermocouple0(TC3_CS, TC0_FAULT, TC0_DRDY);
PWF_MAX31856  thermocouple1(TC2_CS, TC0_FAULT, TC0_DRDY);
PWF_MAX31856  thermocouple2(TC1_CS, TC0_FAULT, TC0_DRDY);
PWF_MAX31856  thermocouple3(TC0_CS, TC0_FAULT, TC0_DRDY);

double probeTemp[] = {-999,-999,-999,-999};
unsigned long LastTempTime = 0;
///////////////////////////////////////////////////////////////////
















// PID Pump Control ///////////////////////////////
#define NumOfPumps 4

// boolean AvailablePumps[] = {1,0,0,0}; // which pumps are currently available

// Pump control PWM pinouts
int PUMP_PWM_pin[NumOfPumps] = {3,4,5,6};
int PUMP_LED_pin[NumOfPumps] = {44,45,46,47}; // on Mega, only 44,45,46 have pwm

// PWM rate for manual speed control
double PUMP_PWM_Speed[NumOfPumps];

// PID controller
double consKp[NumOfPumps], consKi[NumOfPumps], consKd[NumOfPumps];
double aggrKp[NumOfPumps], aggrKi[NumOfPumps], aggrKd[NumOfPumps];

double Setpoint[NumOfPumps], Input[NumOfPumps], Output[NumOfPumps];

// double Kp=2, Ki=5, Kd=1;
PID PumpPID0;
PID PumpPID1;
PID PumpPID2;
PID PumpPID3;

int Gap = 5;

unsigned long LastPIDTime = 0;

///////////////////////////////////////////////////



unsigned long PollInterval = 250;














void setup() {
  delay(1000);                            // give MAX31856 chip a chance to stabilize

  InitializePump();



  
  // setup for the the SPI library:
  SPI.begin();                            // begin SPI
  SPI.setClockDivider(SPI_CLOCK_DIV16);   // SPI speed to SPI_CLOCK_DIV16 (1MHz)
  SPI.setDataMode(SPI_MODE3);             // MAX31856 is a MODE3 device

  
  // call config command... options can be seen in the PlayingWithFusion_MAX31856.h file
  thermocouple0.MAX31856_config(T_TYPE, CUTOFF_60HZ, AVG_SEL_2SAMP);
  thermocouple1.MAX31856_config(T_TYPE, CUTOFF_60HZ, AVG_SEL_2SAMP);
  thermocouple2.MAX31856_config(T_TYPE, CUTOFF_60HZ, AVG_SEL_2SAMP);
  thermocouple3.MAX31856_config(T_TYPE, CUTOFF_60HZ, AVG_SEL_2SAMP);

 
  
  // for communication with PC
  Serial.begin(115200);
  while (!Serial) { }
  Serial.setTimeout(1);
  Serial.println('R'); // Send ready signal to PC
}






















void loop() {


    
  // Update Temperature Readings ////////////////////
  if (millis() - LastTempTime >= PollInterval) {
    UpdateTemps();
    LastTempTime = millis();
  }
  ///////////////////////////////////////////////////        



  


  // Pump Control ///////////////////////////////////
  //if (millis() - LastPIDTime >= PollInterval) {

    if (PumpPID0.GetMode()) { PIDfun(0); } 
    if (PumpPID1.GetMode()) { PIDfun(1); } 
    if (PumpPID2.GetMode()) { PIDfun(2); } 
    if (PumpPID3.GetMode()) { PIDfun(3); } 
    
    //LastPIDTime = millis();
  //}
  ///////////////////////////////////////////////////     



}









