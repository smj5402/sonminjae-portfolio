/*
 * button.h
 *
 *  Created on: 2026. 2. 12.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_BUTTON_BUTTON_H_
#define SRC_DRIVER_BUTTON_BUTTON_H_

#include <stdint.h>
#include <stdbool.h>
#include "../../HAL/GPIO/GPIO.h"

typedef enum{
	RELEASED = 0,
	PUSHED
}button_state_t;

typedef enum{
	NO_ACT = 0,
	ACT_RELEASED,
	ACT_PUSHED
}button_act_t;

typedef struct {
	GPIO_TypeDef *GPIOx;
	uint32_t GPIO_Pin;
	button_state_t PrevButtonState;
}button_handler_t;

void Button_Init(button_handler_t *hBtn, GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin);
button_act_t Button_GetState(button_handler_t *hBtn);


#endif /* SRC_DRIVER_BUTTON_BUTTON_H_ */
