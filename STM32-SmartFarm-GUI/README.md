# 🌱 STM32 SmartFarm GUI

> STM32 기반 스마트팜 농장 관리 시스템 — Python GUI와 UART 패킷 통신으로 연동

**임베디드 시스템 반도체 2팀** | 손민재, 박인범, 오수혁, 최무영 | 2026.03.31

---

## 📌 프로젝트 개요

STM32 마이크로컨트롤러와 Python GUI를 UART 프로토콜로 연동하여 **3개 구역의 온·습도를 실시간 모니터링하고 DC 팬 모터를 자동/수동으로 제어**하는 스마트팜 시스템입니다.

---

## ⚙️ 주요 기능

| 분류 | 기능 |
|------|------|
| **센서** | DHT11 온·습도 센서 (3구역 독립 측정) |
| **디스플레이** | I2C LCD — 구역별 온습도 + 모드(A/M) 표시, 순환 출력 |
| **팬 제어** | TIM3 기반 PWM DC 모터 3채널 — AUTO / MANUAL 모드 전환 |
| **버튼 입력** | Zone 선택, 모드 전환, 속도 UP/DOWN (GPIO) |
| **LED 표시** | 현재 선택된 제어 구역 LED로 표시 (Zone1~3) |
| **RTC** | STM32 내장 RTC — 시간/날짜 조회·설정 |
| **UART 통신** | DMA + ReceiveToIdle — 패킷 단위 양방향 통신 |
| **Python GUI** | 드래그바·버튼으로 PWM 제어, 온습도 실시간 모니터링, 로그 출력 |
| **게임 시스템** | 가상 펫(알→애벌레→번데기→나비) — 환경에 따라 HP 변동 |

---

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────┐
│         Application / Service Layer      │
│   TempHumid_SVC │ RtcClock_SVC │ Fan_SVC │
├─────────────────────────────────────────┤
│                Driver Layer              │
│  DHT11 │ LCD │ Button │ LED │ Motor      │
│  UART_COM │ UART_PROTO │ RTC            │
├─────────────────────────────────────────┤
│                  HAL Layer               │
│   GPIO │ I2C │ UART │ RTC │ TIMER │ DWT │
├─────────────────────────────────────────┤
│              Device Hardware             │
│  DHT11 │ LCD │ LED │ Button │ DC Motor  │
└─────────────────────────────────────────┘
```

---

## 📡 UART 패킷 구조

```
| SOF  | LEN | CMD | PAYLOAD (가변) | CRC8 |
| 0xAA |     |     |                |      |
```

### CMD 코드 요약

**PC → STM32**

| CMD | 코드 | 설명 |
|-----|------|------|
| CMD_REQUEST_DATA | 0x10 | 전체 구역 온습도 즉시 요청 |
| CMD_SET_INTERVAL | 0x11 | 자동 전송 주기 설정 |
| CMD_SET_BACKLIGHT | 0x12 | LCD 백라이트 ON/OFF |
| CMD_PING | 0x13 | 연결 확인 |
| CMD_FAN_SET_MODE | 0x30 | 팬 모드 설정 (MANUAL/AUTO) |
| CMD_FAN_SET_SPEED | 0x31 | 팬 속도 설정 (0~100) |
| CMD_FAN_GET_STATUS | 0x32 | 팬 상태 요청 |

**STM32 → PC**

| CMD | 코드 | 설명 |
|-----|------|------|
| CMD_SENSOR_DATA | 0x81 | DHT11 온습도 데이터 |
| CMD_ACK | 0x82 | 명령 수신 확인 |
| CMD_ERROR | 0x83 | 오류 발생 |
| CMD_PONG | 0x84 | PING 응답 |
| CMD_TIME_DATA | 0x85 | RTC 시간 데이터 |
| CMD_DATE_DATA | 0x86 | RTC 날짜 데이터 |
| CMD_FAN_STATUS | 0x87 | 팬 상태 응답 |

---

## 🔌 하드웨어 핀 매핑

| 주변장치 | 포트/핀 | 설명 |
|----------|---------|------|
| DHT11 Zone1 | GPIOA PIN10 | 온습도 센서 1 |
| DHT11 Zone2 | GPIOC PIN4 | 온습도 센서 2 |
| DHT11 Zone3 | GPIOB PIN13 | 온습도 센서 3 |
| BTN Select | GPIOD PIN2 | 구역 선택 버튼 |
| BTN Mode | GPIOC PIN10 | AUTO/MANUAL 전환 |
| BTN Speed UP | GPIOC PIN11 | 팬 속도 증가 (+5%) |
| BTN Speed DOWN | GPIOC PIN12 | 팬 속도 감소 (-5%) |
| LED Zone1 | GPIOC PIN0 | Zone1 선택 표시 |
| LED Zone2 | GPIOC PIN2 | Zone2 선택 표시 |
| LED Zone3 | GPIOC PIN3 | Zone3 선택 표시 |
| LCD | I2C1 (hi2c1) | I2C LCD 디스플레이 |
| FAN PWM | TIM3 CH1/CH2/CH3 | DC 모터 3채널 |
| UART | USART2 + DMA | PC 통신 |

---

## 🚀 빌드 및 실행 환경

- **STM32 펌웨어:** STM32CubeIDE (STM32F4xx 시리즈)
- **Python GUI:** VSCode + Python 3.x
- **통신:** USART2, Baud rate 설정에 따라 조정

---

## 📂 디렉터리 구조

```
📦 STM32-SmartFarm-GUI
├── 📂 stm32/App/
│   ├── ap_main.c / ap_main.h          # 애플리케이션 메인 진입점
│   ├── Temp_HUMI_SVC/
│   │   ├── temp_humi_svc.c            # DHT11 온습도 서비스
│   │   └── temp_humi_svc.h
│   ├── FAN_SVC/
│   │   ├── fan_svc.c                  # FAN PWM 제어 서비스
│   │   └── fan_svc.h
│   └── RTC_CLOCK_SVC/
│       ├── rtc_clock_svc.c            # RTC 시계 서비스
│       └── rtc_clock_svc.h
└── 📂 python/                         # Python GUI (예정)
```

---

## ⚠️ 트러블슈팅 기록

### ZONE Index 불일치 문제
- **원인:** STM32는 존 번호를 1, 2, 3으로 전송하나, Python 리스트는 0-based 인덱스 사용 → Offset 발생
- **해결:** Python 수신부에서 `raw_id - 1` 처리, 제어 명령 송신 시 `+ 1` 복원

---

## 🎮 게임 시스템

실제 환경(온·습도)에 반응하는 디지털 펫 성장 시스템
- 쾌적 범위 이탈 시 HP 감소
- 진화 단계: 알 → 애벌레 → 번데기 → 나비 🦋
