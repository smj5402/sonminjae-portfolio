/*
* LCD.h
*
* Created on: Mar 24, 2026
* Author: kccistc
*/

#ifndef DRIVER_LCD_LCD_H_
#define DRIVER_LCD_LCD_H_

#include "stm32f4xx_hal.h"

void LCD_Init(I2C_HandleTypeDef *hI2C);
void LCD_SendI2C(uint8_t data);
void LCD_BackLight_On();
void LCD_BackLight_Off();
void LCD_CmdMode();
void LCD_CharMode();
void LCD_WriteMode();
void LCD_E_HIGH();
void LCD_E_LOW();
void LCD_SendNibbleData(uint8_t data);
void LCD_SendData(uint8_t data);
void LCD_WriteCmdData(uint8_t data);
void LCD_CharCmdData(uint8_t data);
void LCD_WriteString(char *str);
void LCD_WriteStringXY(uint8_t row, uint8_t col, char *str);
void LCD_gotoXY(uint8_t row, uint8_t col);
void LCD_Clear();
void LCD_Home();

#endif /* DRIVER_LCD_LCD_H_ */