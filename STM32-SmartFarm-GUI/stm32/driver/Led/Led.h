/*
* Led.h
*
* Created on: Mar 23, 2026
* Author: kccistc
*/

#ifndef DRIVER_LED_LED_H_
#define DRIVER_LED_LED_H_

#include "stm32f4xx_hal.h"

typedef struct {
    GPIO_TypeDef *GPIOx;
    uint16_t      GPIO_Pin;
} hLed_Def;

void Led_Init(hLed_Def *hLed, GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin);
void Led_On(hLed_Def *hLed);
void Led_Off(hLed_Def *hLed);
void Led_Toggle(hLed_Def *hLed);

#endif /* DRIVER_LED_LED_H_ */