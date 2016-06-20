/*
  Pump Control Functions

  Daniel.Stolzberg@gmail.com 2016
*/


//////////////////////////////////////////////////////////////////////





















// Pump Control ///////////////////////////////////
void InitializePump() {

  for (int i = 0; i < NumOfPumps; i++) {
    pinMode(PUMP_PWM_pin[i], OUTPUT);
    pinMode(PUMP_LED_pin[i], OUTPUT);

    analogWrite(PUMP_PWM_pin[i], 0);
    digitalWrite(PUMP_LED_pin[i], 0); // discrete LED indicator

    // set default PID values
    consKp[i] = 0.75;
    consKi[i] = 0.035;
    consKd[i] = 0.2;
    aggrKp[i] = 1;
    aggrKi[i] = 0.05;
    aggrKd[i] = 0.25;

    switch (i) {
      case 0: PumpPID0 = PID(&Input[i], &Output[i], &Setpoint[i], consKp[i], consKi[i], consKd[i], REVERSE); break;
      case 1: PumpPID1 = PID(&Input[i], &Output[i], &Setpoint[i], consKp[i], consKi[i], consKd[i], REVERSE); break;
      case 2: PumpPID2 = PID(&Input[i], &Output[i], &Setpoint[i], consKp[i], consKi[i], consKd[i], REVERSE); break;
      case 3: PumpPID3 = PID(&Input[i], &Output[i], &Setpoint[i], consKp[i], consKi[i], consKd[i], REVERSE); break;
    }


  }
  PumpPID0.SetMode(MANUAL); PumpPID0.SetOutputLimits(5, 255); PumpPID0.SetSampleTime(500);
  PumpPID1.SetMode(MANUAL); PumpPID1.SetOutputLimits(5, 255); PumpPID1.SetSampleTime(500);
  PumpPID2.SetMode(MANUAL); PumpPID2.SetOutputLimits(5, 255); PumpPID2.SetSampleTime(500);
  PumpPID3.SetMode(MANUAL); PumpPID3.SetOutputLimits(5, 255); PumpPID3.SetSampleTime(500);
}
///////////////////////////////////////////////////


















void PIDfun(int ID) {

  if (probeTemp[ID] == -999) { return; }

  Input[ID] = probeTemp[ID];

  double gap = abs(Setpoint[ID] - Input[ID]); //distance away from setpoint
  
  if (gap < Gap) {
    // Conservative PID tunings
    switch (ID) {
      case 0: PumpPID0.SetTunings(consKp[ID], consKi[ID], consKd[ID]); break;
      case 1: PumpPID1.SetTunings(consKp[ID], consKi[ID], consKd[ID]); break;
      case 2: PumpPID2.SetTunings(consKp[ID], consKi[ID], consKd[ID]); break;
      case 3: PumpPID3.SetTunings(consKp[ID], consKi[ID], consKd[ID]); break;
    }
  }
  else {
    // Aggressive PID tunings
    switch (ID) {
      case 0: PumpPID0.SetTunings(aggrKp[ID], aggrKi[ID], aggrKd[ID]); break;
      case 1: PumpPID1.SetTunings(aggrKp[ID], aggrKi[ID], aggrKd[ID]); break;
      case 2: PumpPID2.SetTunings(aggrKp[ID], aggrKi[ID], aggrKd[ID]); break;
      case 3: PumpPID3.SetTunings(aggrKp[ID], aggrKi[ID], aggrKd[ID]); break;
    }
  }

  switch (ID) {
    case 0: if (PumpPID0.Compute()) { analogWrite(PUMP_PWM_pin[ID], Output[ID]); } break;
    case 1: if (PumpPID1.Compute()) { analogWrite(PUMP_PWM_pin[ID], Output[ID]); } break;
    case 2: if (PumpPID2.Compute()) { analogWrite(PUMP_PWM_pin[ID], Output[ID]); } break;
    case 3: if (PumpPID3.Compute()) { analogWrite(PUMP_PWM_pin[ID], Output[ID]); } break;
  }

  PUMP_PWM_Speed[ID] = Output[ID];
}












