/*
 * led.h
 *
 *  Created on: 2026. 2. 12.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_LED_LED_H_
#define SRC_DRIVER_LED_LED_H_

#include <stdint.h>
#include <stdbool.h>
#include "../../HAL/GPIO/GPIO.h"


typedef struct {
	GPIO_TypeDef *GPIOx;
	uint32_t GPIO_Pin;

}led_handler_t;

void Led_Init(led_handler_t *hLed, GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin);
void Led_On(led_handler_t *hLed);
void Led_Off(led_handler_t *hLed);
void Led_Toggle(led_handler_t *hLed);
void Led_Write(led_handler_t *hled, uint8_t data);

#endif /* SRC_DRIVER_LED_LED_H_ */
