/*
* Led.c
*
* Created on: Mar 23, 2026
* Author: kccistc
*/

#include "Led.h"

void Led_Init(hLed_Def *hLed, GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)
{
    hLed->GPIOx    = GPIOx;
    hLed->GPIO_Pin = GPIO_Pin;
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    GPIO_InitStruct.Pin   = hLed->GPIO_Pin;
    GPIO_InitStruct.Mode  = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull  = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(hLed->GPIOx, &GPIO_InitStruct);
}

void Led_On(hLed_Def *hLed)
{
    HAL_GPIO_WritePin(hLed->GPIOx, hLed->GPIO_Pin, SET);
}

void Led_Off(hLed_Def *hLed)
{
    HAL_GPIO_WritePin(hLed->GPIOx, hLed->GPIO_Pin, RESET);
}

void Led_Toggle(hLed_Def *hLed)
{
    HAL_GPIO_TogglePin(hLed->GPIOx, hLed->GPIO_Pin);
}