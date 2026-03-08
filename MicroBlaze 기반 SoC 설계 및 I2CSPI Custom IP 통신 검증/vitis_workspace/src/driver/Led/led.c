/*
 * led.c
 *
 *  Created on: 2026. 2. 12.
 *      Author: kccistc
 */


#include "led.h"

void Led_Init(led_handler_t *hLed, GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin)
{
	hLed->GPIOx = GPIOx;
	hLed->GPIO_Pin = GPIO_Pin;
	GPIO_Init(hLed->GPIOx, hLed->GPIO_Pin, OUTPUT_MODE);
}

void Led_On(led_handler_t *hLed)
{
	GPIO_WritePin(hLed->GPIOx, hLed->GPIO_Pin, HIGH);
}


void Led_Off(led_handler_t *hLed)
{
	GPIO_WritePin(hLed->GPIOx, hLed->GPIO_Pin, LOW);
}


void Led_Toggle(led_handler_t *hLed)
{
	GPIO_TogglePin(hLed->GPIOx, hLed->GPIO_Pin);
}


void Led_Write(led_handler_t *hled, uint8_t data)
{
	hled->GPIOx->ODR = data;
}
