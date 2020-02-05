#include <WaspWIFI_PRO.h>
#include <WaspSensorGas_Pro.h>
#include <WaspPM.h>
#include <String.h>

// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket = SOCKET0;
///////////////////////////////////////
// WiFi AP settings (CHANGE TO USER'S AP)
///////////////////////////////////////
char ESSID[] = "SSID";
char PASSW[] = "PASSWORD";
///////////////////////////////////////
// DEVICE SHADOW ID (FOR AWS)
///////////////////////////////////////
char deviceId[] = "Boxy-Libelium-{LOCATION}";
///////////////////////////////////////
// SERVER settings
///////////////////////////////////////
char type[] = "http";
char host[] = "pathto.cloudfront.net";
char port[] = "80";
char url[50];
// message for POST request
char msgToAws[150];
// define variables
uint8_t error;
uint8_t status;
unsigned long previous;
/*
 * P&S! Possibilities for BME temperature sensor:
 *  - SOCKET_E
 */
bmeGasesSensor  bme;
float temperature;  // Stores the temperature in ºC
float humidity;   // Stores the realitve humidity in %RH
float feelsLike;
float tempF;
float pressure;   // Stores the pressure in Pa
/*
 * P&S! Possibilities for PM particle sensor:
 *  - SOCKET_D
 */
int PMstatus;
int PMmeasure;
float pm1;
float pm2p5;
float pm10;
float batteryVoltage;
float batteryPercentage;
void setup() 
{
  USB.println(F("Start program"));
  //////////////////////////////////////////////////
  // 0. Check Battery status
  //////////////////////////////////////////////////
  // Show the remaining battery level
  batteryPercentage = PWR.getBatteryLevel();
  batteryVoltage = PWR.getBatteryVolts();
  USB.print(F("Battery Level: "));
  USB.print(batteryPercentage);
  USB.print(F(" %"));
  // Show the battery Volts
  USB.print(F(" | Battery (Volts): "));
  USB.print(batteryVoltage);
  USB.println(F(" V"));
  //////////////////////////////////////////////////
  // 1. Switch ON the WiFi module
  //////////////////////////////////////////////////
  error = WIFI_PRO.ON(socket);
  if (error == 0)
  {    
    USB.println(F("1. WiFi switched ON"));
  }
  else
  {
    USB.println(F("1. WiFi did not initialize correctly"));
  }
  //////////////////////////////////////////////////
  // 2. Reset to default values
  //////////////////////////////////////////////////
  error = WIFI_PRO.resetValues();
  if (error == 0)
  {    
    USB.println(F("2. WiFi reset to default"));
  }
  else
  {
    USB.println(F("2. WiFi reset to default ERROR"));
  }
  //////////////////////////////////////////////////
  // 3. Set ESSID
  //////////////////////////////////////////////////
  error = WIFI_PRO.setESSID(ESSID);
  if (error == 0)
  {    
    USB.println(F("3. WiFi set ESSID OK"));
  }
  else
  {
    USB.println(F("3. WiFi set ESSID ERROR"));
  }
  //////////////////////////////////////////////////
  // 4. Set password key (It takes a while to generate the key)
  //////////////////////////////////////////////////
  error = WIFI_PRO.setPassword(WPA2, PASSW);
  if (error == 0)
  {    
    USB.println(F("4. WiFi set AUTHKEY OK"));
  }
  else
  {
    USB.println(F("4. WiFi set AUTHKEY ERROR"));
  }
  //////////////////////////////////////////////////
  // 5. Software Reset 
  //////////////////////////////////////////////////
  error = WIFI_PRO.softReset();
  if (error == 0)
  {    
    USB.println(F("5. WiFi softReset OK"));
  }
  else
  {
    USB.println(F("5. WiFi softReset ERROR"));
  }
  // get current time
  previous = millis();
  //////////////////////////////////////////////////
  // 6. Set URL
  //////////////////////////////////////////////////
  error = WIFI_PRO.setURL( type, host, port, "/air_libelium_update_data" );
  // check response
  if (error == 0)
  {
    USB.println(F("6. Set URL OK"));           
  }
  else
  {
    USB.println(F("6. Error calling 'setURL' function"));
    WIFI_PRO.printErrorCode();
  }
  //RTC.setTime("20:01:24:06:13:39:00");
  USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
  USB.println(RTC.getTime());
}
void loop()
{
  //////////////////////////////////////////////////
  // 1. Switch ON the WiFi module
  //////////////////////////////////////////////////
  error = WIFI_PRO.ON(socket);
  if (error == 0)
  {    
    USB.println(F("1. WiFi switched ON"));
  }
  else
  {
    USB.println(F("1. WiFi did not initialize correctly"));
  }
  //////////////////////////////////////////////////
  // 2. Join AP
  //////////////////////////////////////////////////  
  // Check if module is connected
  if (WIFI_PRO.isConnected() == true){    
    USB.print(F("WiFi is connected OK"));
    USB.print(F(" Time(ms):"));    
    USB.println(millis()-previous); 
    USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
    USB.println(RTC.getTime());
    ///////////////////////////////////////////
    // 3. Turn on BME temperature sensor
    ///////////////////////////////////////////
    bme.ON();
    ///////////////////////////////////////////
    // 4. Read BME temperature sensors
    ///////////////////////////////////////////
    // Read enviromental variables
    temperature = bme.getTemperature();
    humidity = bme.getHumidity();
    pressure = bme.getPressure();
    // And print the values via USB
    USB.println(F("***************************************"));
    USB.print(F("Temperature: "));
    USB.print(temperature);
    USB.println(F(" Celsius degrees"));
    USB.print(F("RH: "));
    USB.print(humidity);
    USB.println(F(" %"));
    USB.print(F("Pressure: "));
    USB.print(pressure);
    USB.println(F(" Pa"));
    ///////////////////////////////////////////
    // 5. Turn off the sensor
    ///////////////////////////////////////////
    bme.OFF();
    tempF = 9.0 / 5.0 * temperature + 32.0;
    feelsLike = 0.5 * (tempF + 61.0 + ((tempF - 68.0) * 1.2) + (humidity * 0.094));
    if (feelsLike > 79) {
        feelsLike = -42.379
          + 2.04901523 * tempF
          + 10.14333127 * humidity
          + -0.22475541 * tempF * humidity
          + -0.00683783 * pow(tempF, 2)
          + -0.05481717 * pow(humidity, 2)
          + 0.00122874 * pow(tempF, 2) * humidity
          + 0.00085282 * tempF * pow(humidity, 2)
          + -0.00000199 * pow(tempF, 2) * pow(humidity, 2);
        if ((humidity < 13) && (tempF >= 80.0) && (tempF <= 112.0))
            feelsLike -= ((13.0 - humidity) * 0.25) * sqrt((17.0 - abs(tempF - 95.0)) * 0.05882);
        else if ((humidity > 85.0) && (tempF >= 80.0) && (tempF <= 87.0))
            feelsLike += ((humidity - 85.0) * 0.1) * ((87.0 - tempF) * 0.2);
    }
    feelsLike = (feelsLike - 32) * 0.55555;
        USB.print(F("Feels Like: "));
        USB.println(feelsLike);
    ///////////////////////////////////////////
    // 6. Turn on the PM particle sensor
    ///////////////////////////////////////////
   PMstatus = PM.ON();
    if (PMstatus == 1)
    {
      USB.println(F("Particle sensor started"));
    }
    else
    {
      USB.println(F("Error starting the particle sensor"));
    }
    ///////////////////////////////////////////
    // 7. Read PM particle sensor
    ///////////////////////////////////////////
    if (PMstatus == 1)
    {
      // Power the fan 5 seconds before measuring, and then perform a measure of 5 seconds
      PMmeasure = PM.getPM(5000, 5000);
      // check answer
      if (PMmeasure == 1)
      {
        USB.println(F("PM Measurement performed"));
        USB.print(F("PM 1: "));
        USB.printFloat(PM._PM1, 1);
        pm1 = PM._PM1;
        USB.println(F(" ug/m3"));
        USB.print(F("PM 2.5: "));
        USB.printFloat(PM._PM2_5, 1);
        pm2p5 = PM._PM2_5;
        USB.println(F(" ug/m3"));
        USB.print(F("PM 10: "));
        USB.printFloat(PM._PM10, 1);
        pm10 = PM._PM10;
        USB.println(F(" ug/m3"));
      }
      else
      {
        USB.print(F("Error performing the measure. Error code:"));
        USB.println(PMmeasure, DEC);
      }
    }
     USB.print("Bin: ");
       for (int i = 0; i < 24; i++)
       {
         USB.print(PM._bin[i]);
         USB.print(";");
       }
       USB.println();
    ///////////////////////////////////////////
    // 8. Turn off the sensor
    ///////////////////////////////////////////
    PM.OFF();
    //////////////////////////////////////////////// 
    // 9. Http POST request
    ////////////////////////////////////////////////
    // construct message for AWS
    char pressureShort[30];
    dtostrf(pressure, 1, 0, pressureShort);
    char batteryVoltageShort[30];
    dtostrf(batteryVoltage, 1, 2, batteryVoltageShort);
    snprintf( msgToAws, sizeof(msgToAws), "{\"thingName\": \"%s\", \"s1\": %d,  \"s2\": %d,  \"s3\": %s,  \"s4\": %d,  \"s6\": %d,  \"s5\": %d, \"d1\": %d, \"s18\": %s, \"d6\": %d}", deviceId, (int) temperature,(int) humidity, pressureShort, (int) pm1,(int) pm10,(int) pm2p5, (int) feelsLike, batteryVoltageShort, (int) batteryPercentage);
    USB.println(msgToAws);
    //send HTTP request
    error = WIFI_PRO.post(msgToAws);
    // check response
    if( error == 0 )
    {
      USB.println(F("HTTP POST OK"));          
      USB.print(F("HTTP Time from OFF state (ms):"));    
      USB.println(millis()-previous);    
      USB.print(F("Server answer:"));
      USB.println(WIFI_PRO._buffer, WIFI_PRO._length);
    }
    else
    {
      USB.println(F("Error caling 'post' function"));
      WIFI_PRO.printErrorCode();
    }
    //////////////////////////////////////////////// 
    // 10. Deep Sleep
    ////////////////////////////////////////////////
    //turn OFF WiFi modem
    WIFI_PRO.OFF(socket);
    //go to deep sleep
    PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  }
  else{
    USB.print(F("WiFi is connected ERROR")); 
    USB.print(F("Time(ms):"));    
    USB.println(millis()-previous);  
  }
}