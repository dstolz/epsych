  /* Serial communications formatting:

    Command character(s),pump index (0-5),command value (depends on command function)
		
		Pump index is 0-based meaning that pump 1 is addressed at 0, pump 2 is addressed at 1, etc.

    c,0     ...   Return current temperature (deg C) of first pump
    t,0     ...   Get target temperature for PID controller
    T,0,3   ...   Set target temperature for PID controller
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
      if (Val == 0) { 
        myPID[ID].SetMode(MANUAL);
        PWMspeed[ID] = 0;
        analogWrite(PWM_Pump[ID], PWMspeed[ID]);
      }
      else { 
        myPID[ID].SetMode(AUTOMATIC);        
      }
      Serial.println("X");
      break;


    case 'm': // Get PID mode
      Serial.println(myPID[ID].GetMode());
      break;
      










    case 'S': // Set Pump Speed (manual control override)
      myPID[ID].SetMode(MANUAL);
      PWMspeed[ID] = round(Val / 100 * 255);
      analogWrite(PWM_Pump[ID], PWMspeed[ID]);
      Serial.println("X");
      break;
      
    case 's': // Get Pump Speed
      Val = PWMspeed[ID] / 255 * 100;
      Serial.println(Val,2);
      break;
      
      
      
      
      
      
      
      
      
          
      
    case 'H': // Halt Pump
      myPID[ID].SetMode(MANUAL);
      PWMspeed[ID] = 0;
      analogWrite(PWM_Pump[ID], 0);
      break;










    case 'b': // Get current PID values
      switch (Msg) {
        case 'p': Val = myPID[ID].GetKp(); break;
        case 'i': Val = myPID[ID].GetKi(); break;
        case 'd': Val = myPID[ID].GetKd(); break;
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
      Serial.print(probeTemp[ID],3);
      Serial.print(",");
      Serial.print(Setpoint[ID]); 
      if (myPID[ID].GetMode() == 0) {
        Val = PWMspeed[ID] / 255 * 100;
      }
      else {
        Val = Output[ID] / 255 * 100;
      }
      Serial.print(",");
      Serial.print(Val,2);
      Serial.print(",");
      Serial.println(myPID[ID].GetMode());
      break;
      
      
      
      
      
      
      
      
      
    case 'c': // Return Current Temperature
      Serial.println(probeTemp[ID],3);
      break;




       
      
      

    default: // unknown command
      Serial.println("?");
      break;

         
  }



  while(Serial.available()) {Serial.read();} // ensure incoming buffer is clear
  
 // interrupts();
}

