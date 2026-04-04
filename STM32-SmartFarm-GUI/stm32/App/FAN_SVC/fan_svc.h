/*
* fan_svc.h
*
* Created on: Mar 27, 2026
* Author: kccistc
*/

#ifndef APP_FAN_SVC_FAN_SVC_H_
#define APP_FAN_SVC_FAN_SVC_H_

#include "stm32f4xx_hal.h"

#include "../../driver/Button/Button.h"
#include "../../driver/Led/Led.h"
#include "../../driver/Motor/motor.h"
#include "../../driver/DHT11/DHT11.h"

#include "../../driver/UART_COM/uart_com.h"
#include "../../driver/UART_COM/uart_protocol.h"
#include "../Temp_HUMI_SVC/temp_humi_svc.h"

#define MAX_FANS 3

#define BTN_SELECT_ZONE_GPIO     GPIOD
#define BTN_SELECT_ZONE_GPIO_PIN GPIO_PIN_2   // 선택

#define BTN_FAN_MODE_GPIO        GPIOC
#define BTN_FAN_MODE_GPIO_PIN    GPIO_PIN_10  // 모드

#define BTN_FAN_SPEED_UP_GPIO    GPIOC
#define BTN_FAN_SPEED_UP_GPIO_PIN GPIO_PIN_11 // UP

#define BTN_FAN_SPEED_DOWN_GPIO  GPIOC
#define BTN_FAN_SPEED_DOWN_GPIO_PIN GPIO_PIN_12 // DOWN

#define LED_ZONE1_GPIO           GPIOC
#define LED_ZONE1_GPIO_PIN       GPIO_PIN_0  // Z1

#define LED_ZONE2_GPIO           GPIOC
#define LED_ZONE2_GPIO_PIN       GPIO_PIN_2  // Z2

#define LED_ZONE3_GPIO           GPIOC
#define LED_ZONE3_GPIO_PIN       GPIO_PIN_3  // Z3

typedef enum{
    FAN_MODE_MANUAL = 0,
    FAN_MODE_AUTO
} FanMode_t;

typedef struct {
    TIM_HandleTypeDef *htim;
    uint32_t channel;
    FanMode_t mode;
    uint8_t speed;
} Fan_t;

extern uint8_t g_selected_control; // 0:Z1, 1:Z2, 2:Z3, 3:순환모드

void Fan_Init(TIM_HandleTypeDef *htim);
void Fan_Excute();
void Fan_ManualMode(uint8_t idx);
void Fan_AutoMode(uint8_t idx);
void Fan_HandleCmd(Packet_t *pkt);

#endif /* APP_FAN_SVC_FAN_SVC_H_ */