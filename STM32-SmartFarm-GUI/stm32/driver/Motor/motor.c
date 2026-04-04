/*
* motor.c
*
* Created on: Mar 27, 2026
* Author: kccistc
*/

#include "motor.h"

TIM_HandleTypeDef *s_htim;
uint8_t s_speed = 0;

void Motor_Init(TIM_HandleTypeDef *htim)
{
    s_htim = htim;
    Motor_SetSpeed(0);
    HAL_TIM_PWM_Start(s_htim, TIM_CHANNEL_2);
}

void Motor_SetSpeed(uint8_t speed)
{
    if (speed > 100) speed = 100;
    s_speed = speed;
    uint32_t ccr = (uint32_t)speed * MOTOR_PWM_PERIOD / 100;
    __HAL_TIM_SET_COMPARE(s_htim, TIM_CHANNEL_2, ccr);
}

uint8_t Motor_GetSpeed()
{
    return s_speed;
}