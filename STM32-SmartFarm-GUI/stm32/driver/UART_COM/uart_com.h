/*
* uart_com.h
*
* Created on: Mar 25, 2026
* Author: kccistc
*/

#ifndef DRIVER_UART_COM_UART_COM_H_
#define DRIVER_UART_COM_UART_COM_H_

#include "stm32f4xx_hal.h"
#include "uart_protocol.h"

extern UART_HandleTypeDef huart2;
#define UART_RX_DMA_BUF_SIZE 64

void UART_COM_Init(UART_HandleTypeDef *huart);

// Temp & Humid
uint8_t   UART_COM_TempHumid_isReady();
Packet_t *UART_COM_TempHumid_GetPacket();

// RTC
uint8_t   UART_COM_RTC_isReady();
Packet_t *UART_COM_RTC_GetPacket();

// FAN
uint8_t   UART_COM_FAN_isReady();
Packet_t *UART_COM_FAN_GetPacket();

void UART_COM_Sendpacket(uint8_t cmd, const uint8_t *payload, uint8_t payloadLen);
void UART_COM_RxEventHandler(uint16_t size);

#endif /* DRIVER_UART_COM_UART_COM_H_ */