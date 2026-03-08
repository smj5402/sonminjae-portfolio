/*
 * GPIO.c
 *
 *  Created on: 2026. 2. 12.
 *      Author: kccistc
 */

#include "GPIO.h"


void GPIO_Init(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin, gpio_dir_t direction)
{
	if(direction == OUTPUT_MODE) {
		GPIOx->MODER |= (1<<GPIO_Pin);
	}
	else {
		GPIOx->MODER &= ~(1<<GPIO_Pin);
	}
}


void GPIO_WritePin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin, gpio_level_t level)
{
	if(level == HIGH){
		GPIOx ->ODR |= (1<<GPIO_Pin);
	}
	else {
		GPIOx ->ODR &= ~(1<<GPIO_Pin);
	}
}

void GPIO_WritePort(GPIO_TypeDef *GPIOx, uint32_t data)
{
	GPIOx ->ODR = data;

}

uint32_t GPIO_ReadPort(GPIO_TypeDef *GPIOx, uint32_t data)
{
	return GPIOx ->IDR;

}

gpio_level_t GPIO_ReadPin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin)
{
	if(GPIOx->IDR & (1<<GPIO_Pin)){
		return HIGH;
	}
	else {
		return LOW;
	}
}

void GPIO_TogglePin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin)
{
	GPIOx->ODR ^= (1<<GPIO_Pin);
}
