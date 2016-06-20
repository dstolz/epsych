/*    
  Temperature Monitor Functions
  > adapted from SEN30007_8_QuadMax31856_example.ino example from playingwithfusion.com

  Daniel.Stolzberg@gmail.com 2016
*/


//////////////////////////////////////////////////////////////////////


const double f2d = 0.0078125;

void UpdateTemps() {
  
  static struct var_max31856 TC_CH0, TC_CH1, TC_CH2, TC_CH3;
  struct var_max31856 *tc_ptr;


  
  if (ActiveTC[0]) {  // Read CH 0
    tc_ptr = &TC_CH0;                             // set pointer
    thermocouple0.MAX31856_update(tc_ptr);        // Update MAX31856 channel 0
//    if(TC_CH0.status)
//    {
//      // lots of faults possible at once, technically... handle all 8 of them
//      // Faults detected can be masked, please refer to library file to enable faults you want represented
//      Serial.println("fault(s) detected");
//      Serial.print("Fault List: ");
//      if(0x01 & TC_CH0.status){Serial.print("OPEN  ");}
//      if(0x02 & TC_CH0.status){Serial.print("Overvolt/Undervolt  ");}
//      if(0x04 & TC_CH0.status){Serial.print("TC Low  ");}
//      if(0x08 & TC_CH0.status){Serial.print("TC High  ");}
//      if(0x10 & TC_CH0.status){Serial.print("CJ Low  ");}
//      if(0x20 & TC_CH0.status){Serial.print("CJ High  ");}
//      if(0x40 & TC_CH0.status){Serial.print("TC Range  ");}
//      if(0x80 & TC_CH0.status){Serial.print("CJ Range  ");}
//      Serial.println(" ");
//    }
    if(0x01 & TC_CH0.status){
      probeTemp[0] = -999;
    } else {
      probeTemp[0] = (double)TC_CH0.lin_tc_temp * f2d;           // convert fixed pt # to double
    }
  }

  if (ActiveTC[1]) {  // Read CH 1
    tc_ptr = &TC_CH1;                             // set pointer
    thermocouple1.MAX31856_update(tc_ptr);        // Update MAX31856 channel 1
    if(0x01 & TC_CH1.status){
      probeTemp[1] = -999;
    } else {
      probeTemp[1] = (double)TC_CH1.lin_tc_temp * f2d;           // convert fixed pt # to double  
    }
  }

  if (ActiveTC[2]) {  // Read CH 2
    tc_ptr = &TC_CH2;                             // set pointer
    thermocouple2.MAX31856_update(tc_ptr);        // Update MAX31856 channel 2
    if(0x01 & TC_CH2.status){
      probeTemp[2] = -999;
    } else {    
      probeTemp[2] = (double)TC_CH2.lin_tc_temp * f2d;           // convert fixed pt # to double  
    }
  }
  
  if (ActiveTC[3]) {  // Read CH 3
    tc_ptr = &TC_CH3;                             // set pointer
    thermocouple3.MAX31856_update(tc_ptr);        // Update MAX31856 channel 3
    if(0x01 & TC_CH3.status){
      probeTemp[3] = -999;
    } else {
      probeTemp[3] = (double)TC_CH3.lin_tc_temp * f2d;           // convert fixed pt # to double  
    }
  }    
    
  ValidateTCs();  
}














void ValidateTCs(){
  for (int i = 0; i < sizeof(ActiveTC)/sizeof(boolean); i++) {
    if (!ActiveTC[i]) { digitalWrite(PUMP_LED_pin[i],LOW); } // inactive TC
    else if (probeTemp[i] == -999) 
    { digitalWrite(PUMP_LED_pin[i],!digitalRead(PUMP_LED_pin[i])); } // active TC with error 
    else { digitalWrite(PUMP_LED_pin[i],HIGH); } // all good
    
  }
}

