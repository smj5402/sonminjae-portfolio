/*
* fan_svc.c
* Created on: Mar 27, 2026
* Author: kccistc
*/
#include "fan_svc.h"

Fan_t fans[MAX_FANS];
uint8_t g_selected_control = 3; // 0:Z1, 1:Z2, 2:Z3, 3:순환모드

hBtn_Def hbtn1, hbtn2, hbtn3, hbtn4;
hLed_Def hLedZ1, hLedZ2, hLedZ3;

extern Zone_t zones[MAX_ZONES];

void Fan_Init(TIM_HandleTypeDef *htim) {
    uint32_t channels[MAX_FANS] = {TIM_CHANNEL_1, TIM_CHANNEL_2, TIM_CHANNEL_3};
    for (int i = 0; i < MAX_FANS; i++) {
        fans[i].htim    = htim;
        fans[i].channel = channels[i];
        fans[i].mode    = FAN_MODE_MANUAL;
        fans[i].speed   = 0;
        HAL_TIM_PWM_Start(fans[i].htim, fans[i].channel);
    }

    Button_Init(&hbtn1, BTN_SELECT_ZONE_GPIO,    BTN_SELECT_ZONE_GPIO_PIN);
    Button_Init(&hbtn2, BTN_FAN_MODE_GPIO,       BTN_FAN_MODE_GPIO_PIN);
    Button_Init(&hbtn3, BTN_FAN_SPEED_UP_GPIO,   BTN_FAN_SPEED_UP_GPIO_PIN);
    Button_Init(&hbtn4, BTN_FAN_SPEED_DOWN_GPIO, BTN_FAN_SPEED_DOWN_GPIO_PIN);

    Led_Init(&hLedZ1, LED_ZONE1_GPIO, LED_ZONE1_GPIO_PIN);
    Led_Init(&hLedZ2, LED_ZONE2_GPIO, LED_ZONE2_GPIO_PIN);
    Led_Init(&hLedZ3, LED_ZONE3_GPIO, LED_ZONE3_GPIO_PIN);
}

void Fan_AutoMode(uint8_t idx) {
    uint8_t h = zones[idx].humi;
    if      (h > 60) fans[idx].speed = 100;
    else if (h > 40) fans[idx].speed = 85;
    else if (h > 25) fans[idx].speed = 70;
    else             fans[idx].speed = 0;
}

void Fan_ManualMode(uint8_t idx) {
    if      (Button_GetState(&hbtn3) == ACT_RELEASED) {
        fans[idx].speed = (fans[idx].speed >= 100) ? 100 : fans[idx].speed + 5;
    } else if (Button_GetState(&hbtn4) == ACT_RELEASED) {
        fans[idx].speed = (fans[idx].speed <=  5)  ?   0 : fans[idx].speed - 5;
    }
}

void Fan_Excute() {
    // 1. Zone 선택 버튼
    if (Button_GetState(&hbtn1) == ACT_RELEASED) {
        g_selected_control = (g_selected_control + 1) % 4;
    }

    // 2. 모드 전환 버튼
    if (g_selected_control < 3 && Button_GetState(&hbtn2) == ACT_RELEASED) {
        fans[g_selected_control].mode =
            (fans[g_selected_control].mode == FAN_MODE_AUTO) ? FAN_MODE_MANUAL : FAN_MODE_AUTO;
    }

    // 3. 모든 팬 업데이트 및 PWM 적용
    for (int i = 0; i < MAX_FANS; i++) {
        if (fans[i].mode == FAN_MODE_AUTO) {
            Fan_AutoMode(i);
        } else if (i == g_selected_control) {
            Fan_ManualMode(i);
        }
        __HAL_TIM_SET_COMPARE(fans[i].htim, fans[i].channel, fans[i].speed * 10);
    }

    // 4. LED 표시
    Led_Off(&hLedZ1); Led_Off(&hLedZ2); Led_Off(&hLedZ3);
    switch(g_selected_control) {
        case 0: Led_On(&hLedZ1); break;
        case 1: Led_On(&hLedZ2); break;
        case 2: Led_On(&hLedZ3); break;
        default: break;
    }

    // 5. UART 패킷 수신 처리
    if (UART_COM_FAN_isReady()) {
        Fan_HandleCmd(UART_COM_FAN_GetPacket());
    }
}

void Fan_HandleCmd(Packet_t *pkt) {
    if (pkt == NULL) return;

    uint8_t raw_id = pkt->payload[0];
    int idx = raw_id - 1;

    if (idx < 0 || idx >= MAX_FANS) return;

    switch (pkt->cmd) {
        case CMD_FAN_SET_MODE:
            fans[idx].mode = (FanMode_t)pkt->payload[1];
            break;

        case CMD_FAN_SET_SPEED:
            fans[idx].mode  = FAN_MODE_MANUAL;
            fans[idx].speed = pkt->payload[1];
            break;

        default:
            break;
    }
}