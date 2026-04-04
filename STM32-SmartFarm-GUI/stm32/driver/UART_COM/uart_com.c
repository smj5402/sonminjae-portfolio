/*
* uart_com.c
*
* Created on: Mar 25, 2026
* Author: kccistc
*/

#include "uart_com.h"

ParseCtx_t s_parseCtx;

Packet_t s_dht11Pkt;
uint8_t  s_dht11RxReady = 0;

Packet_t s_rtcPkt;
uint8_t  s_rtcRxReady = 0;

Packet_t s_fanPkt;
uint8_t  s_fanRxReady = 0;

uint8_t s_rxBuf[UART_RX_DMA_BUF_SIZE];
uint8_t s_txBuf[PROTO_MAX_PKT_SIZE];
UART_HandleTypeDef *s_huart;

void UART_COM_Init(UART_HandleTypeDef *huart)
{
    s_huart = huart;
    Proto_ParseReset(&s_parseCtx);
    memset(s_rxBuf, 0, sizeof(s_rxBuf));
    // DMA 처리 후 Interrupt
    HAL_UARTEx_ReceiveToIdle_DMA(s_huart, s_rxBuf, UART_RX_DMA_BUF_SIZE);
    __HAL_DMA_DISABLE_IT(s_huart->hdmarx, DMA_IT_HT);
}

uint8_t UART_COM_TempHumid_isReady()  { return s_dht11RxReady; }
Packet_t *UART_COM_TempHumid_GetPacket() { s_dht11RxReady = 0; return &s_dht11Pkt; }

uint8_t UART_COM_RTC_isReady()        { return s_rtcRxReady; }
Packet_t *UART_COM_RTC_GetPacket()    { s_rtcRxReady = 0; return &s_rtcPkt; }

uint8_t UART_COM_FAN_isReady()        { return s_fanRxReady; }
Packet_t *UART_COM_FAN_GetPacket()    { s_fanRxReady = 0; return &s_fanPkt; }

void UART_COM_Sendpacket(uint8_t cmd, const uint8_t *payload, uint8_t payloadLen)
{
    uint16_t pktLen = Proto_BuildPacket(s_txBuf, cmd, payload, payloadLen);
    HAL_UART_Transmit(s_huart, s_txBuf, pktLen, 100);
}

void UART_COM_RxEventHandler(uint16_t size)
{
    if (size == 0) {
        HAL_UARTEx_ReceiveToIdle_DMA(s_huart, s_rxBuf, UART_RX_DMA_BUF_SIZE);
        __HAL_DMA_DISABLE_IT(s_huart->hdmarx, DMA_IT_HT);
        return;
    }

    Packet_t tempPkt;
    for (int i = 0; i < size; i++) {
        if (!Proto_ParseByte(&s_parseCtx, s_rxBuf[i], &tempPkt)) continue;

        if (tempPkt.cmd >= CMD_TEMP_HUMID_MIN && tempPkt.cmd <= CMD_TEMP_HUMID_MAX) {
            s_dht11Pkt = tempPkt;
            s_dht11RxReady = 1;
        } else if (tempPkt.cmd >= CMD_RTC_MIN && tempPkt.cmd <= CMD_RTC_MAX) {
            s_rtcPkt = tempPkt;
            s_rtcRxReady = 1;
        } else if (tempPkt.cmd >= CMD_FAN_MIN && tempPkt.cmd <= CMD_FAN_MAX) {
            s_fanPkt = tempPkt;
            s_fanRxReady = 1;
        }
    }
    HAL_UARTEx_ReceiveToIdle_DMA(s_huart, s_rxBuf, UART_RX_DMA_BUF_SIZE);
    __HAL_DMA_DISABLE_IT(s_huart->hdmarx, DMA_IT_HT);
}