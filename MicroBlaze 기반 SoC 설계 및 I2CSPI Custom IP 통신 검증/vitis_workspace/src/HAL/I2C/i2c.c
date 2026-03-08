#include "i2c.h"
#include "sleep.h" 

void I2C_Transmit(uint8_t data) {
    I2C->TXD = data;

    I2C->CR = 0x05;


    usleep(3000);

    I2C->CR = 0x00;

    usleep(1000);
}
