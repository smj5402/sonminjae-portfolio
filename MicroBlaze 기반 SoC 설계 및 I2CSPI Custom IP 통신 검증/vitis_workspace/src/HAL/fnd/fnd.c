/*
 * fnd.c
 *
 *  Created on: 2026. 2. 15.
 *      Author: kccistc
 */


#include "fnd.h"

void FND_COM_write(FND_TypeDef *FNDx, uint32_t data)
{
	FNDx->COM = data;
}

void FND_SEG1_write(FND_TypeDef *FNDx ,uint32_t data)
{
	FNDx->SEG1 = data;
}

void FND_SEG2_write(FND_TypeDef *FNDx ,uint32_t data)
{
	FNDx->SEG2 = data;
}

void FND_SEG3_write(FND_TypeDef *FNDx ,uint32_t data)
{
	FNDx->SEG3 = data;
}

void FND_SEG4_write(FND_TypeDef *FNDx ,uint32_t data)
{
	FNDx->SEG4 = data;
}
