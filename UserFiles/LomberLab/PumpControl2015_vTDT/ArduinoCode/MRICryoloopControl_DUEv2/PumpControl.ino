/*		
	Pump Control Functions

	Daniel.Stolzberg@gmail.com 2015
*/


//////////////////////////////////////////////////////////////////////




















  
// Pump Control ///////////////////////////////////  
void InitializePump() {
  
  for (int i = 0; i < NumOfPumps; i++) {
    pinMode(PWM_Pump[i], OUTPUT);
    pinMode(PANEL_LED_PUMP[i], OUTPUT);

    analogWrite(PWM_Pump[i], 0);
    analogWrite(PANEL_LED_PUMP[i], 0);
    
    // set default PID values
    consKp[i] = 0.75;
    consKi[i] = 0.035;
    consKd[i] = 0.2;
    aggrKp[i] = 1;
    aggrKi[i] = 0.05;
    aggrKd[i] = 0.25;

    myPID[i] = PID(&Input[i], &Output[i], &Setpoint[i], consKp[i], consKi[i], consKd[i], REVERSE);
    
    myPID[i].SetMode(MANUAL);
    myPID[i].SetOutputLimits(5, 255); 
    myPID[i].SetSampleTime(500);

  }
}
///////////////////////////////////////////////////
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
void PIDfun(int ID) {
  
    Input[ID] = probeTemp[ID];
    
    double gap = abs(Setpoint[ID]-Input[ID]); //distance away from setpoint

    if(gap < Gap) { 
      // Conservative PID tunings
      myPID[ID].SetTunings(consKp[ID], consKi[ID], consKd[ID]); }
    else { 
      // Aggressive PID tunings
      myPID[ID].SetTunings(aggrKp[ID], aggrKi[ID], aggrKd[ID]); 
    }
    
    if (myPID[ID].Compute()) {
      analogWrite(PWM_Pump[ID],Output[ID]);  
    }
    
    PWMspeed[ID] = Output[ID];
    
}


















  
  
















