/* GPIO.h */
#ifndef SRC_HAL_GPIO_GPIO_H_
#define SRC_HAL_GPIO_GPIO_H_

#include <stdint.h>
#include "xparameters.h"

typedef struct {
    volatile uint32_t MODER; // 0x00
    volatile uint32_t IDR;   // 0x04
    volatile uint32_t ODR;   // 0x08
} GPIO_TypeDef;

#define GPIOA_BASEADDR XPAR_MY_GPIO_0_S00_AXI_BASEADDR // BTN ����
#define GPIOB_BASEADDR XPAR_MY_GPIO_1_S00_AXI_BASEADDR // SW ����

#define GPIOA          ((GPIO_TypeDef *) GPIOA_BASEADDR)
#define GPIOB          ((GPIO_TypeDef *) GPIOB_BASEADDR)

typedef enum { INPUT_MODE = 0, OUTPUT_MODE } gpio_dir_t;
typedef enum { LOW = 0, HIGH } gpio_level_t;

void GPIO_Init(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin, gpio_dir_t direction);
void GPIO_WritePin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin, gpio_level_t level);
gpio_level_t GPIO_ReadPin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin);
void GPIO_TogglePin(GPIO_TypeDef *GPIOx, uint32_t GPIO_Pin);
void GPIO_WritePort(GPIO_TypeDef *GPIOx, uint32_t data);
uint32_t GPIO_ReadPort(GPIO_TypeDef *GPIOx, uint32_t data);

#endif /* SRC_HAL_GPIO_GPIO_H_ */
