#include "apMain.h"
#include <stdio.h>


button_handler_t hBtn; 
button_handler_t hSw;  

void App_Init()
{
    printf("System Initialization Start...\n");

    Button_Init(&hBtn, GPIOA, 0);

    Button_Init(&hSw, GPIOB, 0);

    printf("System Initialization Complete!\n");
}

void App_Excute()
{

    if(Button_GetState(&hBtn) == ACT_PUSHED)
    {
        printf("[SPI] Button Pushed! Transmitting data...\n");
        SPI_Transmit(0xF0); 
        printf("[SPI] Transmission Done.\n");
    }


    if(Button_GetState(&hSw) == ACT_PUSHED)
    {
        printf("[I2C] Switch UP! Transmitting data...\n");
        I2C_Transmit(0x7E); 
        printf("[I2C] Transmission Done.\n");
    }
}
