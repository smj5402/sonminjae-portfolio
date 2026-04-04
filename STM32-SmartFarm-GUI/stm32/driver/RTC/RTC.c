/*
* RTC.c
*
* Created on: Mar 24, 2026
* Author: kccistc
*/

#include "RTC.h"

RTC_TimeTypeDef sTime = {0};
RTC_DateTypeDef sDate = {0};
RTC_HandleTypeDef *hRTC;

void RTC_Init(RTC_HandleTypeDef *hrtc)
{
    hRTC = hrtc;
}

void RTC_GetTime()
{
    HAL_RTC_GetTime(hRTC, &sTime, RTC_FORMAT_BIN);
}

void RTC_SetTime(uint8_t hour, uint8_t min, uint8_t sec)
{
    sTime.Hours   = hour;
    sTime.Minutes = min;
    sTime.Seconds = sec;
    HAL_RTC_SetTime(hRTC, &sTime, RTC_FORMAT_BIN);
}

void RTC_GetDate()
{
    HAL_RTC_GetTime(hRTC, &sTime, RTC_FORMAT_BIN);
    HAL_RTC_GetDate(hRTC, &sDate, RTC_FORMAT_BIN);
}

void RTC_SetDate(uint8_t year, uint8_t month, uint8_t date, uint8_t WeekDay)
{
    sDate.Year    = year;
    sDate.Month   = month;
    sDate.Date    = date;
    sDate.WeekDay = WeekDay;
    HAL_RTC_SetDate(hRTC, &sDate, RTC_FORMAT_BIN);
}