/*
* temp_humi_svc.c
*
* Created on: Mar 26, 2026
* Author: kccistc
*/
#include "temp_humi_svc.h"

extern Fan_t fans[MAX_FANS];

Zone_t zones[MAX_ZONES] = {
{GPIOA, GPIO_PIN_10, 0, 0}, // Zone 1
{GPIOC, GPIO_PIN_4, 0, 0},  // Zone 2
{GPIOB, GPIO_PIN_13, 0, 0}  // Zone 3
};

static volatile uint32_t g_interval_ms = 2000;
static uint8_t g_current_display_zone = 0; // LCD 순환 표시용

Packet_t *rxTempHumidPacket;

void TempHumid_Init()
{
// 각 존의 센서를 초기 상태로 설정
for (int i = 0; i < MAX_ZONES; i++) {
DHT11_Init(zones[i].port, zones[i].pin);
}
}

void TempHumid_Excute()
{
static uint32_t lastTick = 0;
uint32_t now = HAL_GetTick();

if((now - lastTick) >= g_interval_ms){
lastTick = now;

for(uint8_t i = 0; i < MAX_ZONES; i++)
{
TempHumid_SendSensorData(i);
HAL_Delay(10);
}
g_current_display_zone = (g_current_display_zone + 1) % MAX_ZONES;
}

if(UART_COM_TempHumid_isReady()){
rxTempHumidPacket = UART_COM_TempHumid_GetPacket();
switch (rxTempHumidPacket->cmd)
{
case CMD_REQUEST_DATA:
for(uint8_t i = 0; i < MAX_ZONES; i++) {
TempHumid_SendSensorData(i);
HAL_Delay(10);
}
break;

case CMD_SET_INTERVAL:
g_interval_ms = rxTempHumidPacket->payload[0] * 1000;
uint8_t acked = CMD_SET_INTERVAL;
UART_COM_Sendpacket(CMD_ACK, &acked, 1);
break;

case CMD_SET_BACKLIGHT:
if(rxTempHumidPacket->payload[0] == 0) LCD_BackLight_Off();
else LCD_BackLight_On();
break;

case CMD_PING:
UART_COM_Sendpacket(CMD_PONG, NULL, 0);
break;

default:
uint8_t err = ERR_INVALID_CMD;
UART_COM_Sendpacket(CMD_ERROR, &err, 1);
break;
}
}
}

void TempHumid_SendSensorData(uint8_t zoneIdx)
{
DHT11_Data_t dht11Data;
DHT11_Status_t dht11Status = DHT11_Read(zones[zoneIdx].port, zones[zoneIdx].pin, &dht11Data);
char strBuff[30];

if (zoneIdx == g_current_display_zone) {
LCD_Clear();
if(dht11Status == DHT11_OK){
if (fans[zoneIdx].mode == FAN_MODE_AUTO) {
LCD_WriteStringXY(0, 15, "A");
} else {
LCD_WriteStringXY(0, 15, "M");
}
sprintf(strBuff, "Z%d Temp: %2u C", zoneIdx+1, dht11Data.temp_int);
LCD_WriteStringXY(0, 0, strBuff);
sprintf(strBuff, "Z%d Humi: %2u %%", zoneIdx+1, dht11Data.humi_int);
LCD_WriteStringXY(1, 0, strBuff);
}
else{
sprintf(strBuff, "Z%d Sensor Error", zoneIdx + 1);
LCD_WriteStringXY(0, 0, strBuff);
sprintf(strBuff, "%s", (dht11Status == DHT11_ERROR_TIMEOUT) ? "[Time Out]" : "CHECKSUM ERR");
LCD_WriteStringXY(1, 0, strBuff);
}
}

if(dht11Status == DHT11_OK){
uint8_t payload[3] = { (uint8_t)(zoneIdx + 1), dht11Data.temp_int, dht11Data.humi_int };
UART_COM_Sendpacket(CMD_SENSOR_DATA, payload, 3);
zones[zoneIdx].temp = dht11Data.temp_int;
zones[zoneIdx].humi = dht11Data.humi_int;
}
else{
uint8_t err_payload[2] = { (uint8_t)(zoneIdx + 1),
(dht11Status == DHT11_ERROR_TIMEOUT) ? ERR_DHT11_TIMEOUT : ERR_DHT11_CHECKSUM };
UART_COM_Sendpacket(CMD_ERROR, err_payload, 2);
}
}