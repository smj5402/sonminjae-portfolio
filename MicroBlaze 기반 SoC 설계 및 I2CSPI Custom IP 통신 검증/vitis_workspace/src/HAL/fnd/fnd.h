/*
 * fnd.h
 *
 *  Created on: 2026. 2. 15.
 *      Author: kccistc
 */
#include <stdint.h>
#include "xparameters.h"

#ifndef SRC_HAL_FND_H_
#define SRC_HAL_FND_H_

typedef struct{
	volatile uint32_t CR;
	volatile uint32_t COM;
	volatile uint32_t SEG1;
	volatile uint32_t SEG2;
	volatile uint32_t SEG3;
	volatile uint32_t SEG4;
}FND_TypeDef;

#define FND_BASEADDR XPAR_S_FND_0_S00_AXI_BASEADDR
#define FND (FND_TypeDef *)FND_BASEADDR

void FND_COM_write(FND_TypeDef *FNDx, uint32_t data);
void FND_SEG1_write(FND_TypeDef *FNDx ,uint32_t data);
void FND_SEG2_write(FND_TypeDef *FNDx ,uint32_t data);
void FND_SEG3_write(FND_TypeDef *FNDx ,uint32_t data);
void FND_SEG4_write(FND_TypeDef *FNDx ,uint32_t data);


#endif /* SRC_HAL_FND_H_ */
