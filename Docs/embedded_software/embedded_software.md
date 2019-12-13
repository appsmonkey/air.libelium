# Embedded Software

Libelium code has the same structure as Arduino code with already prepared libraries for any heavy lifting and well known _setup()_ and _loop()_ functions.

## Required Libraries

For our usecase, where we have WiFi connected Waspmote Plug & Sense and a BME sensor probe, we need following libraries to succesfully interface the sensor and communicate with the server

```cpp
#include <WaspWIFI_PRO.h>
#include <WaspSensorGas_Pro.h>
```

- **WaspWIFI_PRO** provides the functions needed to interaface the Wi-Fi module.

- **WaspSensorGas_Pro** provides the support for various sensors among which is also the BME sensor used in this project

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

int temperature;  // Stores the temperature in ºC
int humidity;   // Stores the realitve humidity in %
int pressure;   // Stores the pressure in Pa
```

## setup()

the code below will be run **only once** after the device is powered on.

```cpp
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

    // make HTTP POST request to AWS api
    // 1. construct message for AWS
    snprintf( msgToAws, sizeof(msgToAws), "{\"deviceId\": \"temperature\", \"pressure\": %d,  \"humidity\": %d,  \"s3\": %d}", deviceId, temperature, humidity, pressure);

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
