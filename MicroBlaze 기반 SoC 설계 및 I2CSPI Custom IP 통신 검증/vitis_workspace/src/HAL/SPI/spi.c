#include "spi.h"
#include "sleep.h" 

void SPI_Transmit(uint8_t data) {
    SPI->TXD = data;

    SPI->CR = 0x01;

    usleep(1000);

    SPI->CR = 0x00;

    usleep(1000);
}
