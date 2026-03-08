#ifndef SRC_HAL_I2C_I2C_HAL_H_
#define SRC_HAL_I2C_I2C_HAL_H_

#include <stdint.h>
#include "xparameters.h"

// Verilog에서 설계한 레지스터 맵
typedef struct {
    volatile uint32_t CR;   // 0x00: Control (bit0: I2C_En, bit1: start, bit2: stop)
    volatile uint32_t SR;   // 0x04: Status  (bit0: tx_ready, bit1: tx_done, bit2: rx_done)
    volatile uint32_t RXD;  // 0x08: RX Data
    volatile uint32_t TXD;  // 0x0C: TX Data
} I2C_TypeDef;

#define I2C_BASEADDR XPAR_MY_I2C_0_S00_AXI_BASEADDR
#define I2C          ((I2C_TypeDef *) I2C_BASEADDR)

void I2C_Transmit(uint8_t data);

#endif /* SRC_HAL_I2C_I2C_HAL_H_ */
