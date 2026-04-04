/*
* uart_protocol.h
*
* Created on: Mar 25, 2026
* Author: kccistc
*/
#include "stm32f4xx_hal.h"
#include "string.h"

#ifndef DRIVER_UART_COM_UART_PROTOCOL_H_
#define DRIVER_UART_COM_UART_PROTOCOL_H_

//프레임 상수
#define PROTO_SOF 0XAA
#define PROTO_MAX_PAYLOAD 32
#define PROTO_HEADER_SIZE 3
#define PROTO_CRC_SIZE 1
#define PROTO_MAX_PKT_SIZE (PROTO_HEADER_SIZE + PROTO_MAX_PAYLOAD + PROTO_CRC_SIZE)

//PC -> STM32 TEMP & HUMID CMD CODE
#define CMD_TEMP_HUMID_MIN 0X10
#define CMD_REQUEST_DATA   0X10
#define CMD_SET_INTERVAL   0X11
#define CMD_SET_BACKLIGHT  0X12
#define CMD_PING           0X13
#define CMD_TEMP_HUMID_MAX 0x1F

//PC -> STM32 RTC CMD CODE
#define CMD_RTC_MIN  0X20
#define CMD_GET_TIME 0X20
#define CMD_SET_TIME 0X21
#define CMD_GET_DATE 0X22
#define CMD_SET_DATE 0X23
#define CMD_RTC_MAX  0X2F

//PC-> STM32 FAN CMD
#define CMD_FAN_MIN        0X30
#define CMD_FAN_SET_MODE   0X30
#define CMD_FAN_SET_SPEED  0X31
#define CMD_FAN_GET_STATUS 0X32
#define CMD_FAN_MAX        0X3F

//STM32 -> RESPONSE CODE
#define CMD_SENSOR_DATA 0X81
#define CMD_ACK         0X82
#define CMD_ERROR       0X83
#define CMD_PONG        0X84
#define CMD_TIME_DATA   0X85
#define CMD_DATE_DATA   0X86
#define CMD_FAN_STATUS  0X87

//ERROR CODE
#define ERR_DHT11_TIMEOUT  0X01
#define ERR_DHT11_CHECKSUM 0X02
#define ERR_INVALID_CMD    0X03
#define ERR_INVALID_CRC    0X04
#define ERR_INVALID_LEN    0X05

typedef enum
{
    PARSE_STATE_SOF = 0,
    PARSE_STATE_LEN,
    PARSE_STATE_CMD,
    PARSE_STATE_PAYLOAD,
    PARSE_STATE_CRC
} ParseState_t;

typedef struct {
    uint8_t len;
    uint8_t cmd;
    uint8_t payload[PROTO_MAX_PAYLOAD];
} Packet_t;

typedef struct {
    ParseState_t state;
    uint8_t len;
    uint8_t cmd;
    uint8_t payload[PROTO_MAX_PAYLOAD];
    uint8_t payloadIdx;
} ParseCtx_t;

uint16_t Proto_BuildPacket(uint8_t *buf, uint8_t cmd, const uint8_t *payload, uint8_t payloadLen);
uint8_t  Proto_CRC8(uint8_t *data, uint16_t len);
void     Proto_ParseReset(ParseCtx_t *ctx);
uint8_t  Proto_ParseByte(ParseCtx_t *ctx, uint8_t byte, Packet_t *out);

#endif /* DRIVER_UART_COM_UART_PROTOCOL_H_ */