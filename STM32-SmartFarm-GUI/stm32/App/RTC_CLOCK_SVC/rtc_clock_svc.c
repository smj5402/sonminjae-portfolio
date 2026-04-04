/*
* rtc_clock_svc.c
*
* Created on: Mar 27, 2026
* Author: kccistc
*/

#include "rtc_clock_svc.h"

uint32_t g_rtc_interval_ms = 1000;

void RtcClock_Init(RTC_HandleTypeDef *hrtc)
{
    RTC_Init(hrtc);
    RTC_SetTime(10, 51, 50);
    RTC_SetDate(26, 3, 27, 5);
}

void RtcClock_Excute()
{
    static uint32_t lastTick = 0;
    uint32_t now = HAL_GetTick();

    if ((now - lastTick) >= g_rtc_interval_ms) {
        lastTick = now;
    }

    if (!UART_COM_RTC_isReady()) return;
    Packet_t *rtcPkt = UART_COM_RTC_GetPacket();
    uint8_t payload[8];
    uint8_t err;

    switch (rtcPkt->cmd) {
        case CMD_GET_TIME:
            RtcClock_SendTimeData();
            break;

        case CMD_SET_TIME:
            if (rtcPkt->len < 3) {
                err = ERR_INVALID_LEN;
                UART_COM_Sendpacket(CMD_ERROR, &err, 1);
                break;
            }
            RTC_SetTime(rtcPkt->payload[0], rtcPkt->payload[1], rtcPkt->payload[2]);
            payload[0] = CMD_SET_TIME;
            UART_COM_Sendpacket(CMD_ACK, payload, 1);
            break;

        case CMD_GET_DATE:
            RtcClock_SendDateData();
            break;

        case CMD_SET_DATE:
            if (rtcPkt->len < 4) {
                err = ERR_INVALID_LEN;
                UART_COM_Sendpacket(CMD_ERROR, &err, 1);
                break;
            }
            RTC_SetDate(rtcPkt->payload[0], rtcPkt->payload[1],
                        rtcPkt->payload[2], rtcPkt->payload[3]);
            payload[0] = CMD_SET_DATE;
            UART_COM_Sendpacket(CMD_ACK, payload, 1);
            break;

        default:
            break;
    }
}

void RtcClock_SendTimeData()
{
    uint8_t payload[8];
    RTC_GetTime();
    RTC_GetDate();
    payload[0] = sTime.Hours;
    payload[1] = sTime.Minutes;
    payload[2] = sTime.Seconds;
    UART_COM_Sendpacket(CMD_TIME_DATA, payload, 3);
}

void RtcClock_SendDateData()
{
    uint8_t payload[8];
    RTC_GetTime();
    RTC_GetDate();
    payload[0] = sDate.Year;
    payload[1] = sDate.Month;
    payload[2] = sDate.Date;
    payload[3] = sDate.WeekDay;
    UART_COM_Sendpacket(CMD_DATE_DATA, payload, 4);
}