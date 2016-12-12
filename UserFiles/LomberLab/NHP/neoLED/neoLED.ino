/* Control NeoPixel LEDs with good timing control.
 *  
 *  
 *  to use:   > Send RGB values as R,G,B, (add comma after B)
 *            > Arduino will echo back R,G,B, (including final comma) to confirm
 *            > Nothing will change until the rising edge of a 5V TTL pulse is sent to BNC input (pin 2)
 *     
 *  Notes:    > uses Adafruit_NeoPixel library: https://learn.adafruit.com/adafruit-neopixel-uberguide/arduino-library-installation
 *            > Serial @ 115200
 *            > Additional NeoPixels can be added in serial. Modify #define NUMPIXELS to total number of NeoPixels in series.
 *            > Will still work if last ',' is not included, but will be much slower to respond because code uses Serial.parseInt().
 *            > microcontroller: Arduino Nano ATmega328 5V (should work with any Arduino 5V, but check interrupt pin configuration for TTL_PIN)
 *            > Colors will cycle through Red, Green, and Blue and then go blank on startup
 *            
 *            Daniel Stolzberg, PhD  11/2016
 */

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
  #include <avr/power.h>
#endif

#define PIN            9
#define NUMPIXELS      1

#define TTL_PIN        2

Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

int R = 0;
int G = 25;
int B = 25;

void setup() {
  #if defined (__AVR_ATtiny85__)
    if (F_CPU == 16000000) clock_prescale_set(clock_div_1);
  #endif

  attachInterrupt(digitalPinToInterrupt(TTL_PIN), TTL_Trigger, RISING);
  
  pixels.begin();

  StartupShow();

  Serial.begin(115200);
  while (!Serial) {;}
  Serial.println('R');   // send confirmation of serial connection
}

void loop() {

  if (Serial.available() > 0) {

  //*** MAKE SURE TO PUT A NON-NUMERIC CHARACTER AFTER EACH INTEGER ***
  //      EX: 0,12,0,
    
    R = Serial.parseInt(); 
    G = Serial.parseInt();
    B = Serial.parseInt();
    UpdateColors();
    
    while(Serial.available()) {Serial.read();} // ensure incoming buffer is clear

    // echo back RGB values
    Serial.print(R); Serial.print(',');
    Serial.print(G); Serial.print(',');
    Serial.print(B); Serial.println(',');
  }
}

void TTL_Trigger() {

  pixels.show(); // This sends the updated pixel color to the hardware.

}

void UpdateColors() {
  for (int i = 0; i < NUMPIXELS; i++) {
    pixels.setPixelColor(i, pixels.Color(G,R,B));
  }
  
}


void StartupShow() {
  BlankLEDs();
  for (R = 0; R < 50; R++) {
    UpdateColors();
    pixels.show();
    delay(10);
  }
  BlankLEDs();
  for (G = 0; G < 50; G++) {
    UpdateColors();
    pixels.show();
    delay(10);
  }
  BlankLEDs();
  for (B = 0; B < 50; B++) {
    UpdateColors();
    pixels.show();
    delay(10);
  }
  BlankLEDs();
  UpdateColors();
  pixels.show();
}

void BlankLEDs() { R = 0; G = 0; B = 0; UpdateColors(); pixels.show();}

