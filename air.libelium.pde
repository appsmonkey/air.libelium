#include <WaspWIFI_PRO.h>
#include <WaspSensorGas_Pro.h>
#include <String.h>

// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket = SOCKET0;
///////////////////////////////////////

// WiFi AP settings (CHANGE TO USER'S AP)
///////////////////////////////////////
char ESSID[] = "ESSID";
char PASSW[] = "PASSWORD";
///////////////////////////////////////

// DEVICE SHADOW ID (FOR AWS)
///////////////////////////////////////
char deviceId[] = "SHADOW ID";
///////////////////////////////////////

// SERVER settings
///////////////////////////////////////
char type[] = "http";
char host[] = "*********.cloudfront.net";
char port[] = "80";
char url[50];
// message for POST request
char msgToAws[100];

// define variables
uint8_t error;
uint8_t status;
unsigned long previous;

/*
 * Waspmote OEM. Possibilities for this sensor:
 *  - CENTRAL SOCKET
 * P&S! Possibilities for this sensor:
 *  - SOCKET_E
 */
bmeGasesSensor  bme;

int temperature;  // Stores the temperature in ºC
int humidity;   // Stores the realitve humidity in %RH
int pressure;   // Stores the pressure in Pa


void setup() 
{
  USB.println(F("Start program"));  

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
  // 7. Set URL
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
  // Join AP
  //////////////////////////////////////////////////  

  // Check if module is connected
  if (WIFI_PRO.isConnected() == true){    
    USB.print(F("WiFi is connected OK"));
    USB.print(F(" Time(ms):"));    
    USB.println(millis()-previous); 


    USB.print(F("Time [Day of week, YY/MM/DD, hh:mm:ss]: "));
    USB.println(RTC.getTime());

    ///////////////////////////////////////////
    // 1. Turn on the sensor
    ///////////////////////////////////////////

    bme.ON();


    ///////////////////////////////////////////
    // 2. Read sensors
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
    // 3. Turn off the sensor
    ///////////////////////////////////////////

    bme.OFF();


    //////////////////////////////////////////////// 
    // 4. Http POST request
    ////////////////////////////////////////////////
    
    // construct message for AWS
    snprintf( msgToAws, sizeof(msgToAws), "{\"thingName\": \"%s\", \"s1\": %d,  \"s2\": %d,  \"s3\": %d}", deviceId, temperature, humidity, pressure);
    
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
    // 5. Deep Sleep
    ////////////////////////////////////////////////

    //turn OFF WiFi modem
    WIFI_PRO.OFF(socket);
    //go to deep sleep
    PWR.deepSleep("00:00:03:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  }
  else{
    USB.print(F("WiFi is connected ERROR")); 
    USB.print(F("Time(ms):"));    
    USB.println(millis()-previous);  
  }
}
