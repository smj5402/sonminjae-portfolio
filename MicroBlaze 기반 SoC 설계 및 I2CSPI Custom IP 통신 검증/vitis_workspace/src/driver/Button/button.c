/*
 * button.c
 *
 *  Created on: 2026. 2. 12.
 *      Author: kccistc
 */


#include "button.h"
#include "sleep.h"



void Button_Init(button_handler_t *hBtn, GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin)
{
	hBtn->GPIOx = GPIOx;
	hBtn->GPIO_Pin = GPIO_Pin;
	hBtn->PrevButtonState = RELEASED; 
	GPIO_Init(hBtn->GPIOx, hBtn->GPIO_Pin, INPUT_MODE);
}

button_act_t Button_GetState(button_handler_t *hBtn)
{
	button_state_t curButtonState = GPIO_ReadPin(hBtn->GPIOx, hBtn->GPIO_Pin);

	if((curButtonState == PUSHED) && (hBtn->PrevButtonState == RELEASED)) {
		usleep(10000);
		hBtn->PrevButtonState = PUSHED;
		return ACT_PUSHED;
	}
	else if((curButtonState == RELEASED) && (hBtn->PrevButtonState == PUSHED)) {
		usleep(10000);
		hBtn->PrevButtonState = RELEASED;
		return ACT_RELEASED;
	}
	return NO_ACT;
}
