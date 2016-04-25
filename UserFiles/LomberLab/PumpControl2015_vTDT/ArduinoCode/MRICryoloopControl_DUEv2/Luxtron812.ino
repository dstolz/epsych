/*
	Luxtron 812 RS232 communications

	Daniel.Stolzberg@gmail.com 2015
*/


// Luxtron 812 Com ////////////////////////////////    
void InitializeL812() {
  Serial1.begin(9600);
  Serial1.setTimeout(100);
//  Serial1.println(20); // Ctrl+T: Exit Standby Mode
//  Serial1.println(5);  // Ctrl+E: Enter remote control mode

  Serial1.print(27); // Esc
  if (NumProbes == 1) {
    Serial1.println('PS=1');
  } else if (NumProbes == 2) {
    Serial1.println('PS=1,2');
  }
}


//////////////////////////////////////////////////////////////////////
void UpdateTemps() {
  
  // blank temperature readings
  for (int ID = 0; ID < NumProbes; ID++) {
    probeTemp[ID] = 0; 
  }
  
  unsigned long start = millis();
  while (Serial1.available() == 0) {
    if (millis()-start > 200) {
      return; 
    }
  }

  // read recent temperature readings
  for (int ID = 0; ID < NumProbes; ID++) {
    Serial1.find(":");
    probeTemp[ID] = Serial1.parseFloat();
  }

}


