#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <EEPROM.h>
#include <string.h>
#include "EMG_parm.h"

#define LED_ON  1
#define LED_OFF 0 

//#define DEBUG_MSG


ESP8266WiFiMulti WiFiMulti;
WiFiClient client;


//initial AP mode IP
IPAddress Device_ip(192,168,0,120);
IPAddress Device_gateway(192,168,0,254);
IPAddress Device_gateway1(192,168,1,254);
IPAddress Device_subnet(255,255,255,0);
IPAddress Device_broadcase(255,255,255,255);


const uint16_t port = 9999;
//const char * host = "192.168.0.100"; // ip or dns
const char *host = "192.168.43.133";

int connect_cnt=0;
char TxDataBuf[TX_DATA_BUF_MAX] = {0};
char RxDataBuf[RX_DATA_BUF_MAX] = {0};

char DevNum = 45;




void DataReceive_Busy(){

    State_LED_CTL(LED_ON);

    /********************************/
    /* RTS : 1 -> Busy              */
    /* RTS : 0 -> Ready             */
    /********************************/
    digitalWrite(UART_SOFTWARE_RTS_PIN, HIGH);
}

void DataReceive_Ready(){
    
    State_LED_CTL(LED_OFF);
    
    /********************************/
    /* RTS : 1 -> Busy              */
    /* RTS : 0 -> Ready             */
    /********************************/    
    digitalWrite(UART_SOFTWARE_RTS_PIN, LOW);
}

void UART_init(){
    Serial.begin(115200);

    /* Set Software Flow Control    */
   
    pinMode(UART_SOFTWARE_RTS_PIN, OUTPUT);
    DataReceive_Ready();
}


void State_LED_init(){
    
    /* Initial the Transmission STate LED    */
    pinMode(LED_SATAE_PIN, OUTPUT);

}

void State_LED_CTL(uint8_t LED){
    
    if(LED == LED_ON)
        digitalWrite(LED_SATAE_PIN, LOW);
    else
        digitalWrite(LED_SATAE_PIN, HIGH);
}




void setup() {
    UART_init();
    State_LED_init();
    //EEPROM.begin(512);
    delay(1000);


    //#ifdef DEBUG_MSG
        Serial.println();
        Serial.println("Start EMG acquisition. ");
    //#endif

    //WiFi.config(Device_ip, Device_gateway, Device_subnet);

    WiFi.mode(WIFI_STA);
    WiFiMulti.addAP("test", "12345678");



    //#ifdef DEBUG_MSG
        Serial.println();
        Serial.println();
        Serial.print("Wait for WiFi... ");
    //#endif

    /* Connect to Router */
    // To connect to the AP we set
    while(WiFiMulti.run() != WL_CONNECTED) {
        
        #ifdef DEBUG_MSG
            Serial.print(".");
        #endif

        connect_cnt++;
        if(connect_cnt > 20 )
        ESP.restart(); 
        delay(500);   
    }
    
    //#ifdef DEBUG_MSG
        Serial.println("");
        Serial.println("WiFi connected");  
        Serial.println("IP address: ");
        Serial.println(WiFi.localIP());
    //#endif

    delay(500);

    //#ifdef DEBUG_MSG
        Serial.print("connecting to ");
        Serial.println(host);
    //#endif

    /* Use WiFiClient class to create TCP connections */
    if (!client.connect(host, port)) {
        #ifdef DEBUG_MSG
            Serial.println("connection failed");
            Serial.println("wait 5 sec...");
        #endif

        delay(5000);
        return;
    }

    TxDataBuf[0] = 'E';
    TxDataBuf[1] = 'M';
    TxDataBuf[2] = 'G';

    
}


char serial_temp = 0;
// the loop function runs over and over again forever
void loop() {
   
    serial_available();
    client_available();

    // if (Serial.available() > 0) {
    //     serial_temp = Serial.read();
    //     Serial.println(serial_temp); 
    // }
}

void serial_available(){

    static uint32_t TxDataBuf_cnt = 0;
    static uint32_t UART_RxTimeOut_cnt = 0;
    char incomingByte = 0;

    UART_RxTimeOut_cnt++;
    
    if (Serial.available() > 0) {
        incomingByte = Serial.read();
        
        #ifdef DEBUG_MSG
            Serial.println(incomingByte);
        #endif

        if(TxDataBuf[3] == (FUNC_START_DETECTION + 1))
            TxDataBuf[TxDataBuf_cnt + 5] = incomingByte;
        else 
            TxDataBuf[TxDataBuf_cnt + 4] = incomingByte;
        TxDataBuf_cnt++;
        UART_RxTimeOut_cnt = 0;
        if(TxDataBuf_cnt>=200)
        {
            TxDataBuf[4] = TxDataBuf_cnt;
            DataReceive_Busy();
            delay(1);
            client.write(TxDataBuf, (TxDataBuf_cnt + 5));
            client.flush();
            DataReceive_Ready();
            
            TxDataBuf_cnt=0;
            //client_available();
            //return 1;
        }
    }

    if(UART_RxTimeOut_cnt >= 100000){
        UART_RxTimeOut_cnt = 0;
        if(TxDataBuf_cnt != 0){

            if(TxDataBuf[3] == (FUNC_SEARCH_DEV_NUMBER + 1)){
                TxDataBuf[4] = DevNum;
            }
            if((TxDataBuf_cnt & 0x1) && (TxDataBuf[3] == (FUNC_START_DETECTION + 1))){
                if(TxDataBuf_cnt != 1){
                    TxDataBuf[4] = TxDataBuf_cnt - 1;
                    DataReceive_Busy();
                    delay(1);
                    client.write(TxDataBuf, (TxDataBuf_cnt + 5 - 1));
                    client.flush();
                    DataReceive_Ready();
                    TxDataBuf[5] = TxDataBuf[TxDataBuf_cnt + 5 - 1];
                    TxDataBuf_cnt = 1;
                }
            }
            else if(TxDataBuf[3] == (FUNC_START_DETECTION + 1)){
                TxDataBuf[4] =  TxDataBuf_cnt;
                DataReceive_Busy();
                delay(1);
                client.write(TxDataBuf, (TxDataBuf_cnt + 5));
                client.flush();
                DataReceive_Ready();
                TxDataBuf_cnt = 0;
            }
            else{
                DataReceive_Busy();
                delay(1);
                client.write(TxDataBuf, (TxDataBuf_cnt + 4));
                client.flush();
                DataReceive_Ready();
                TxDataBuf_cnt = 0;
            }
        }
    }

    //return 0;
}


void client_available(){
    //char temp[50] = {0};
    char len = client.available();
    if(len > 0){
        client.read((uint8_t *)RxDataBuf, len);
        // Serial.println(len, DEC);
        // Serial.println((char *)temp);
        switch(RxDataBuf[3]){
            case FUNC_START_DETECTION:
                TxDataBuf[3] = (char)(FUNC_START_DETECTION + 1);
                if(RxDataBuf[4] == 0xFF){
                    #ifdef DEBUG_MSG
                        Serial.print(0x81, HEX);
                        Serial.println(0x40, HEX);
                    #else
                        Serial.write(0x81);
                        Serial.write(0x40);
                    #endif
                }
                else{
                    #ifdef DEBUG_MSG
                        Serial.print(0x81, HEX);
                        Serial.println(RxDataBuf[4], HEX);
                    #else
                        Serial.write(0x81);
                        Serial.write(RxDataBuf[4]);
                    #endif
                }
                break;

            case FUNC_STOP_DETECTION:
                #ifdef DEBUG_MSG
                    Serial.println(0x80, HEX);
                #else
                    Serial.write(0x80);
                #endif
                
                break;
            case FUNC_SEARCH_DEV_NUMBER:
                TxDataBuf[3] = (char)(FUNC_SEARCH_DEV_NUMBER + 1);
                TxDataBuf[4] = DevNum;
                #ifdef DEBUG_MSG
                    Serial.println(0x82, HEX);
                #else
                    Serial.write(0x82);
                #endif
                // DataReceive_Busy();
                // client.write(TxDataBuf, 5);
                // DataReceive_Ready();
                break;
            case FUNC_SEARCH_BAT:
                TxDataBuf[3] = (char)(FUNC_SEARCH_BAT + 1);
                #ifdef DEBUG_MSG
                    Serial.println(0x83, HEX);
                #else
                    Serial.write(0x83);
                #endif
                break;
            default: break;
        }
    }
}