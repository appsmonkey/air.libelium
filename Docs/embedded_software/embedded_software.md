# Embedded Software

Libelium code has the same structure as Arduino code with already prepared libraries for any heavy lifting and well known _setup()_ and _loop()_ functions.

## Required Libraries

For our usecase, where we have WiFi connected Waspmote Plug & Sense and a BME sensor probe, we need following libraries to succesfully interface the sensor and communicate with the server

```cpp
#include <WaspWIFI_PRO.h>
#include <WaspSensorGas_Pro.h>
#include <WaspPM.h>
#include <String.h>
```

- **WaspWIFI_PRO** provides the functions needed to interaface the Wi-Fi module.

- **WaspSensorGas_Pro** provides the support for various sensors among which is also the BME sensor used in this project.

- **WaspPM** provides the functions needed to interface the PM sensor.

## Constants and Global Variables

```cpp
// choose socket (needed to initalize WiFi module)
// this is default recommended value
uint8_t socket = SOCKET0;

// WiFi AP settings (CHANGE TO USER'S AP)
char ESSID[] = "SSIDHERE";
char PASSW[] = "passwordhere";

// DEVICE SHADOW ID (needed for AWS lambda to identify this device)
char deviceId[] = "NameYourDevice";

// SERVER settings
char type[] = "http";
char host[] = "url.toyourapi.domain";
char port[] = "80";
char url[50];
char msgToAws[100]; // message for POST request

// BME sensor class available thorugh WaspSensorGas_Pro
// this sensor probe has to be
// plugged in into socket "E" on the waspmote P&S device
bmeGasesSensor  bme;

float temperature;  // Stores the temperature in ºC
float humidity;   // Stores the realitve humidity in %RH
float feelsLike;
float tempF;
float pressure;   // Stores the pressure in Pa

//PM particle sensor has to be plugged into SOCKET "D"
int PMstatus; //holds status code of sensor
int PMmeasure; 
float pm1; //holds measurement values in ug/m³
float pm2p5; //holds measurement values in ug/m³
float pm10; //holds measurement values in ug/m³

// battery data of the Libelium Plug and Sense device
float batteryVoltage; //
float batteryPercentage;
```

## setup()

the code below will be run **only once** after the device is powered on.

```cpp
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
  
  // Switch ON the WiFi module
  error = WIFI_PRO.ON(socket);

  if (error == 0)
  {
    USB.println(F("1. WiFi switched ON"));
  }
  else
  {
    USB.println(F("1. WiFi did not initialize correctly"));
  }
  
  // Reset to default values
  error = WIFI_PRO.resetValues();

  if (error == 0)
  {
    USB.println(F("2. WiFi reset to default"));
  }
  else
  {
    USB.println(F("2. WiFi reset to default ERROR"));
  }
  
  // Set ESSID
  error = WIFI_PRO.setESSID(ESSID);

  if (error == 0)
  {
    USB.println(F("3. WiFi set ESSID OK"));
  }
  else
  {
    USB.println(F("3. WiFi set ESSID ERROR"));
  }
  
  // Set password key
  error = WIFI_PRO.setPassword(WPA2, PASSW);

  if (error == 0)
  {
    USB.println(F("4. WiFi set AUTHKEY OK"));
  }
  else
  {
    USB.println(F("4. WiFi set AUTHKEY ERROR"));
  }
  
  // Restart the device
  error = WIFI_PRO.softReset();

  if (error == 0)
  {
    USB.println(F("5. WiFi softReset OK"));
  }
  else
  {
    USB.println(F("5. WiFi softReset ERROR"));
  }
  
  // Set URL for POST requests that are going to be executed
  error = WIFI_PRO.setURL( type, host, port, "/path/api" );

  if (error == 0)
  {
    USB.println(F("6. Set URL OK"));
  }
  else
  {
    USB.println(F("6. Error calling 'setURL' function"));
    WIFI_PRO.printErrorCode();
  }
```

## loop()

the following code will be executed repeatedly, when device wakes up from deep sleep it omits _setup()_ and immediately runs this code again.

```cpp
// 1. Switch ON the WiFi module
error = WIFI_PRO.ON(socket);

if (error == 0)
{
    USB.println(F("1. WiFi switched ON"));
}
else
{
    USB.println(F("1. WiFi did not initialize correctly"));
}

// if wifi module is connected to the AP 
// then proceed to read the sensor and send data to AWS
if (WIFI_PRO.isConnected() == true){
    USB.print(F("2. WiFi is connected OK"));

    // Turn on the sensor
    bme.ON();

    // Read enviromental variables
    temperature = bme.getTemperature();
    humidity = bme.getHumidity();
    pressure = bme.getPressure();

    // Turn off the sensor
    bme.OFF();

    //Calculate *felsLike* value
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

    // Turn on the PM particle sensor
    PMstatus = PM.ON();
    if (PMstatus == 1)
    {
      USB.println(F("Particle sensor started"));
    }
    else
    {
      USB.println(F("Error starting the particle sensor"));
    }
    
    // Read PM particle sensor
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
    // Turn off the PM sensor
    PM.OFF();
    
    // make HTTP POST request to AWS api
    // 1. construct message for AWS
    char pressureShort[30];
    dtostrf(pressure, 1, 0, pressureShort);
    char batteryVoltageShort[30];
    dtostrf(batteryVoltage, 1, 2, batteryVoltageShort);
    snprintf( msgToAws, sizeof(msgToAws), "{\"thingName\": \"%s\", \"s1\": %d,  \"s2\": %d,  \"s3\": %s,  \"s4\": %d,  \"s6\": %d,  \"s5\": %d, \"d1\": %d, \"s18\": %s, \"d6\": %d}", deviceId, (int) temperature,(int) humidity, pressureShort, (int) pm1,(int) pm10,(int) pm2p5, (int) feelsLike, batteryVoltageShort, (int) batteryPercentage);
    USB.println(msgToAws);

    // 2. send HTTP request containing the above constructed message
    error = WIFI_PRO.post(msgToAws);

    // 3. check for response by the API and print it to monitor
    if( error == 0 )
    {
      USB.println(F("3. HTTP POST OK"));
      USB.print(F("Server answer:"));
      USB.println(WIFI_PRO._buffer, WIFI_PRO._length);
    }
    else
    {
      USB.println(F("3. Error caling 'POST' function"));
      WIFI_PRO.printErrorCode();
    }

    //turn OFF WiFi modem before going tto sleep
    WIFI_PRO.OFF(socket);

    // go to deep sleep for 3 minutes to save power
    PWR.deepSleep("00:00:03:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}
```
