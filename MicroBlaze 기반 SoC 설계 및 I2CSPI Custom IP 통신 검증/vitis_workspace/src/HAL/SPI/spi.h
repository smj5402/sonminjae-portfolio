#ifndef SRC_HAL_SPI_SPI_HAL_H_
#define SRC_HAL_SPI_SPI_HAL_H_

#include <stdint.h>
#include "xparameters.h"

typedef struct {
    volatile uint32_t CR;   // 0x00: Control (bit0: start, bit1: cpol, bit2: cpha)
    volatile uint32_t SR;   // 0x04: Status  (bit0: tx_ready, bit1: done)
    volatile uint32_t RXD;  // 0x08: RX Data
    volatile uint32_t TXD;  // 0x0C: TX Data
} SPI_TypeDef;

#define SPI_BASEADDR XPAR_MY_SPI2_0_S00_AXI_BASEADDR
#define SPI          ((SPI_TypeDef *) SPI_BASEADDR)

void SPI_Transmit(uint8_t data);

#endif /* SRC_HAL_SPI_SPI_HAL_H_ */
