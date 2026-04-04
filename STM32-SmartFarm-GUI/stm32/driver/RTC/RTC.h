/*
* RTC.h
*
* Created on: Mar 24, 2026
* Author: kccistc
*/

#ifndef DRIVER_RTC_RTC_H_
#define DRIVER_RTC_RTC_H_

#include "stm32f4xx_hal.h"

extern RTC_TimeTypeDef sTime;
extern RTC_DateTypeDef sDate;

void RTC_Init(RTC_HandleTypeDef *hrtc);
void RTC_GetTime();
void RTC_SetTime(uint8_t hour, uint8_t min, uint8_t sec);
void RTC_GetDate();
void RTC_SetDate(uint8_t year, uint8_t month, uint8_t date, uint8_t WeekDay);

#endif /* DRIVER_RTC_RTC_H_ */