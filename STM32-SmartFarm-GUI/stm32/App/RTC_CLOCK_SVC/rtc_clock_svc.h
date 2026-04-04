/*
* rtc_clock_svc.h
*
* Created on: Mar 27, 2026
* Author: kccistc
*/

#ifndef APP_RTC_CLOCK_SVC_RTC_CLOCK_SVC_H_
#define APP_RTC_CLOCK_SVC_RTC_CLOCK_SVC_H_

#include "stm32f4xx_hal.h"
#include "../../driver/RTC/RTC.h"
#include "../../driver/UART_COM/uart_com.h"
#include "../../driver/UART_COM/uart_protocol.h"

void RtcClock_Init(RTC_HandleTypeDef *hrtc);
void RtcClock_Excute();
void RtcClock_SendTimeData();
void RtcClock_SendDateData();

#endif /* APP_RTC_CLOCK_SVC_RTC_CLOCK_SVC_H_ */