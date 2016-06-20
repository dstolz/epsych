  /* Serial communications formatting:

    Command character(s),pump index (0-5),command value (depends on command function)
    
    Pump index is 0-based meaning that pump 1 is addressed at 0, pump 2 is addressed at 1, etc.

    c,0     ...   Return current temperature (deg C) of first pump
    t,0     ...   Get target temperature for PID controller
    T,0,3   ...   Set target temperature for PID controller to 3 degrees (C)
    s,1     ..    Get speed of second pump
    S,2,50  ...   Set speed of the third pump to 50% of max
    H,1     ...   Halt second pump (equivalent to S,1,0)
    m,0     ...   Get mode of first pump (0 for manual; 1 for automatic)
    M,2,1   ...   Set third pump to automatic (1) or manual (0) PID mode
    n       ...   Get number of pumps specified in NumOfPumps
    Kp,0,0.5     ...   Set conservative 'P' constant for first pump
    Ki,0,0.025   ...   Set conservative 'I' constant for first pump
    Kd,0,0.125   ...   Set conservative 'D' constant for first pump
    KP,0,0.5     ...   Set aggressive 'P' constant for first pump
    KI,0,0.025   ...   Set aggressive 'I' constant for first pump
    KD,0,0.125   ...   Set aggressive 'D' constant for first pump
    E,0,1        ...   Set temperature probe to un/available (0/1)
    e,0          ...   Get temperature probe availability (0,1)
    Daniel.Stolzberg@gmail.com 2015
  */

void serialEvent() {


  if (Serial.available() == 0) { return; }
  
//  noInterrupts();

  char  CBuf[2];
  char  Com   = ' ';
  char  Msg   = ' ';
  int   ID    = -1;
  float Val   = 0.0;
  
  // Read Com character from buffer
  Serial.readBytes(CBuf,2);

  Com = CBuf[0];
  if (Com == 75)  { Msg = CBuf[1]; } // K
  if (Com == 107) { Msg = CBuf[1]; } // k
  if (Com == 98)  { Msg = CBuf[1]; } // b
  
  
  // Read channel ID from buffer
  ID = Serial.parseInt();

  // If anything left over, read numeric value
  if (Serial.available() > 0) { Val = Serial.parseFloat(); }

  while(Serial.available()) {Serial.read();} // ensure incoming buffer is clear

  switch (Com) {
    
    case 'n': // Return number of pumps specified in NumOfPumps
      Serial.println(NumOfPumps);
      break;
      
      
      
      
      
      
      


    case 'T': // Set target temperature (Does not set mode to Automatic)
      Setpoint[ID] = Val;
      Serial.println("X");
      break;
 
    case 't': // Return target temperature
      Serial.println(Setpoint[ID]);
      break;
       
            










    case 'M': // Set PID mode
      if (Val) { 
        switch (ID) {
          case 0: PumpPID0.SetMode(AUTOMATIC); break;
          case 1: PumpPID1.SetMode(AUTOMATIC); break;
          case 2: PumpPID2.SetMode(AUTOMATIC); break;
          case 3: PumpPID3.SetMode(AUTOMATIC); break;
        }        
      }
      else
      {
        switch (ID) {
          case 0: PumpPID0.SetMode(MANUAL); break;  
          case 1: PumpPID1.SetMode(MANUAL); break;  
          case 2: PumpPID2.SetMode(MANUAL); break;  
          case 3: PumpPID3.SetMode(MANUAL); break;  
        }
        
        PUMP_PWM_Speed[ID] = 0;
        analogWrite(PUMP_PWM_pin[ID], PUMP_PWM_Speed[ID]);
      }
      Serial.println("X");
      break;


    case 'm': // Get PID mode
      switch (ID) {
        case 0: Serial.println(PumpPID0.GetMode()); break;
        case 1: Serial.println(PumpPID1.GetMode()); break; 
        case 2: Serial.println(PumpPID2.GetMode()); break;
        case 3: Serial.println(PumpPID3.GetMode()); break;
      }
      
      break;
      










    case 'S': // Set Pump Speed (manual control override)
        switch (ID) {
          case 0: PumpPID0.SetMode(MANUAL); break;  
          case 1: PumpPID1.SetMode(MANUAL); break;  
          case 2: PumpPID2.SetMode(MANUAL); break;  
          case 3: PumpPID3.SetMode(MANUAL); break;  
        }
      PUMP_PWM_Speed[ID] = round(Val / 100 * 255);
      analogWrite(PUMP_PWM_pin[ID], PUMP_PWM_Speed[ID]);
      Serial.println("X");
      break;
      
    case 's': // Get Pump Speed
      Val = PUMP_PWM_Speed[ID] / 255 * 100;
      Serial.println(Val);
      break;
      
      
      
      
      
      
      
      
      
          
      
    case 'H': // Halt Pump
      switch (ID) {
        case 0: PumpPID0.SetMode(MANUAL); break;  
        case 1: PumpPID1.SetMode(MANUAL); break;  
        case 2: PumpPID2.SetMode(MANUAL); break;  
        case 3: PumpPID3.SetMode(MANUAL); break;  
      }
      PUMP_PWM_Speed[ID] = 0;
      analogWrite(PUMP_PWM_pin[ID], 0);
      Serial.println("X");
      break;










    case 'b': // Get current PID values
      switch (Msg) {
        case 'p': 
          switch (ID) {
            case 0:   Val = PumpPID0.GetKp(); break;
            case 1:   Val = PumpPID1.GetKp(); break;
            case 2:   Val = PumpPID2.GetKp(); break;
            case 3:   Val = PumpPID3.GetKp(); break;
          }
          break;
        case 'i': 
          switch (ID) {
            case 0:   Val = PumpPID0.GetKi(); break;
            case 1:   Val = PumpPID1.GetKi(); break;
            case 2:   Val = PumpPID2.GetKi(); break;
            case 3:   Val = PumpPID3.GetKi(); break;
          }
          break;
        case 'd': 
          switch (ID) {
            case 0:   Val = PumpPID0.GetKd(); break;
            case 1:   Val = PumpPID1.GetKd(); break;
            case 2:   Val = PumpPID2.GetKd(); break;
            case 3:   Val = PumpPID3.GetKd(); break;
          }
          break;
      }
      Serial.println(Val,4);
      break;
    
    
    case 'l': // Get all PID values for a pump
      Serial.print(consKp[ID]); Serial.print(",");
      Serial.print(consKi[ID]); Serial.print(",");
      Serial.print(consKd[ID]); Serial.print(",");
      Serial.print(aggrKp[ID]); Serial.print(",");
      Serial.print(aggrKi[ID]); Serial.print(",");
      Serial.println(aggrKd[ID]);      
      break;
      
      
      
      
      
      
      
      
      
      
      
      
    case 'K': // Set PID values
      switch (Msg) {
        case 'p': consKp[ID] = Val;  break;
        case 'i': consKi[ID] = Val;  break;
        case 'd': consKd[ID] = Val;  break;
        case 'P': aggrKp[ID] = Val;  break;
        case 'I': aggrKi[ID] = Val;  break;
        case 'D': aggrKd[ID] = Val;  break;
      }
      Serial.println("X");
      break;

    
    case 'k': // Get PID values
      switch (Msg) {
        case 'p': Val = consKp[ID]; break;
        case 'i': Val = consKi[ID]; break;
        case 'd': Val = consKd[ID]; break;
        case 'P': Val = aggrKp[ID]; break;
        case 'I': Val = aggrKi[ID]; break;
        case 'D': Val = aggrKd[ID]; break;
      }
      Serial.println(Val,4);
      break;
      
      
      
      
      
      
          
    
    
    case 'G': // Set Conservative/Aggressive gap
      Gap = round(ID);
      Serial.println("X");
      break;
    
    case 'g': // Get current Gap value
      Serial.println(Gap);
      break;
      
      
      
      
      
      
      
      
    case 'L': // Get lots of info for some pump
      // order of returned buffer: temp,target temp,pump speed,pump mode
      Serial.print(probeTemp[ID]);
      Serial.print(",");
      Serial.print(Setpoint[ID]); 
      switch (ID) {
        case 0: if (PumpPID0.GetMode()) { Val = Output[ID] / 255 * 100; }
                else { Val = PUMP_PWM_Speed[ID] / 255 * 100; }  break;
        case 1: if (PumpPID1.GetMode()) { Val = Output[ID] / 255 * 100; }
                else { Val = PUMP_PWM_Speed[ID] / 255 * 100; }  break;
        case 2: if (PumpPID2.GetMode()) { Val = Output[ID] / 255 * 100; }
                else { Val = PUMP_PWM_Speed[ID] / 255 * 100; }  break;
        case 3: if (PumpPID3.GetMode()) { Val = Output[ID] / 255 * 100; }
                else { Val = PUMP_PWM_Speed[ID] / 255 * 100; }  break;
      }
      Serial.print(",");
      Serial.print(Val,2);
      Serial.print(",");
      switch (ID) {
        case 0: Serial.println(PumpPID0.GetMode()); break; 
        case 1: Serial.println(PumpPID1.GetMode()); break; 
        case 2: Serial.println(PumpPID2.GetMode()); break; 
        case 3: Serial.println(PumpPID3.GetMode()); break; 
      }
      break;
      
      
      
      
      
      
      
      
      
    case 'c': // Return Current Temperature
      Serial.println(probeTemp[ID]);
      break;





    case 'e': // Return avialbility of temperature probe/pump
      Serial.println(ActiveTC[ID]);
      break;

    case 'E': // Change availability of temperature probe/pump
      ActiveTC[ID] = Val;
      //AvailablePumps[ID] = Val;
      Serial.println("X");
      break;
      
      

    default: // unknown command
      Serial.println("?");
      break;

         
  }

  Serial.flush();
 
}

