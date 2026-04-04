/*
* ap_main.c
*
* Created on: Mar 25, 2026
* Author: kccistc
*/
#include "ap_main.h"

void ap_Init()
{
LCD_Init(&hi2c1);
// DHT11_Init();
TempHumid_Init(); // 이 함수가 내부적으로 3개의 DHT11을 모두 초기화합니다.
UART_COM_Init(&huart2);
RtcClock_Init(&hrtc);
Fan_Init(&htim3);
}

void ap_exe()
{
TempHumid_Excute();
RtcClock_Excute();
Fan_Excute();
}

void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t Size)
{
if(huart->Instance == USART2){
UART_COM_RxEventHandler(Size);
}
}