/*
* motor.h
*
* Created on: Mar 27, 2026
* Author: kccistc
*/

#ifndef DRIVER_MOTOR_MOTOR_H_
#define DRIVER_MOTOR_MOTOR_H_

#include "stm32f4xx_hal.h"

#define MOTOR_PWM_PERIOD 999

void    Motor_Init(TIM_HandleTypeDef *htim);
void    Motor_SetSpeed(uint8_t speed);
uint8_t Motor_GetSpeed();

#endif /* DRIVER_MOTOR_MOTOR_H_ */