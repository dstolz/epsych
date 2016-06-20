
//////////////////////////////////////////////////////////////////////
void UpdateAnalogTemps() {
  
  // blank temperature readings
  for (int ID = 0; ID < NumProbes; ID++) {
    probeTemp[ID] = 0; 
  }
  
  unsigned long start = millis();

  // read recent temperature readings
  long v;
  float tmp;
  for (int ID = 0; ID < NumProbes; ID++) {
    tmp = 0;
    for (int i = 0; i < 100; i++) {
      v = analogRead(TEMPpins[ID]);
      tmp = tmp + fmap(v,0,4095,0,50); // RANGE NEEDS TO BE CALIBRATED
    }
    probeTemp[ID] = tmp / 100;
    Serial.println(probeTemp[ID]);
  }

}

float fmap(long x, long in_min, long in_max, float out_min, float out_max)
{
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
