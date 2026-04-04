/*
* temp_humi_svc.h
*
* Created on: Mar 26, 2026
* Author: kccistc
*/

#ifndef APP_TEMP_HUMI_SVC_TEMP_HUMI_SVC_H_
#define APP_TEMP_HUMI_SVC_TEMP_HUMI_SVC_H_

#include <stdio.h>
#include "stm32f4xx_hal.h"

#include "../FAN_SVC/fan_svc.h"
#include "../../driver/DHT11/DHT11.h"
#include "../../driver/LCD/LCD.h"
#include "../../driver/UART_COM/uart_com.h"
#include "../../driver/UART_COM/uart_protocol.h"

#define MAX_ZONES 3

typedef struct {
GPIO_TypeDef* port;
uint16_t pin;
uint8_t temp;
uint8_t humi;
} Zone_t;
extern Zone_t zones[MAX_ZONES];
void TempHumid_Init();
void TempHumid_Excute();

void TempHumid_SendSensorData(uint8_t zoneIdx);

#endif /* APP_TEMP_HUMI_SVC_TEMP_HUMI_SVC_H_ */