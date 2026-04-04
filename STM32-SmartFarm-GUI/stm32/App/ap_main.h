/*
* ap_main.h
*
* Created on: Mar 25, 2026
* Author: kccistc
*/

#ifndef APP_AP_MAIN_H_
#define APP_AP_MAIN_H_

#include "stm32f4xx_hal.h"
#include "Temp_HUMI_SVC/temp_humi_svc.h"
#include "RTC_CLOCK_SVC/rtc_clock_svc.h"
#include "FAN_SVC/fan_svc.h"

#include "../driver/DHT11/DHT11.h"
#include "../driver/LCD/LCD.h"
#include "../driver/RTC/RTC.h"
#include "../driver/UART_COM/uart_com.h"
#include "../driver/Motor/motor.h"

extern I2C_HandleTypeDef hi2c1;
extern UART_HandleTypeDef huart2;
extern DMA_HandleTypeDef hdma_usart2_rx;
extern RTC_HandleTypeDef hrtc;
extern TIM_HandleTypeDef htim3;

void ap_Init();
void ap_exe();
void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t Size);

#endif /* APP_AP_MAIN_H_ */