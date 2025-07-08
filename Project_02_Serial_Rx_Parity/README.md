# Project_02_Serial_Rx_Parity

## 1. 프로젝트 개요

이 프로젝트는 **Odd parity 검사를 포함한 8비트 시리얼 수신기(Serial Receiver)**를 구현한 것입니다.  
입력은 일정한 순서로 `start bit(0) → data bit(8개, LSB-first) → parity bit(1개) → stop bit(1)`로 구성되어 있으며,  
이를 순차적으로 수신하여 상태를 관리하고 데이터 유효성을 판단하는 **FSM 기반 설계**를 적용하였습니다.
초기에는 하나의 `always` 블록에 모든 로직을 담아 구현했으나, 설계 및 시뮬레이션 중 타이밍 오류나 디버깅의 어려움을 경험하며 **상태별 동작을 명확히 분리한 FSM 구조**로 재설계하였습니다.  
이를 통해 입력 시점에 따른 데이터 처리 흐름과 조건 분기 처리를 훨씬 직관적으로 구현할 수 있었습니다.

---

## 2. 설계 목표

* `start bit = 0` 감지 시 시리얼 수신 시작
* 시리얼로 전송된 8비트 데이터 수신 (LSB-first)
* 수신된 8비트 데이터 + 1비트 패리티를 통해 **Odd parity 검사 수행**
* `stop bit  =1`가 1이면 데이터 유효성 판별, 유효한 경우 `done` 출력

---

## 3. 설계 구현

### 3.1. FSM 구조

전체 수신 프로토콜을 처리하기 위해 **13개 상태로 구성된 FSM**을 설계하였습니다:

| 상태 이름       | 설명                             |
|----------------|-----------------------------------|
| `IDLE`         | 입력 대기 (i_data = 1 유지)        |
| `START_BIT`    | start bit 수신 (0인지 확인)        |
| `B0_RECEIVED` ~ `B7_RECEIVED`    | 8비트 데이터 순차 수신 완료(LSB first)  |
| `PARITY_BIT`   | 패리티 비트 수신                   |
| `STOP_BIT`     | stop bit 수신 및 패리티 검증       |
| `WAIT`         | stop bit가 1이 아닐 경우 대기      |

각 상태는 입력 신호 `i_data`와 클럭 에지(`posedge clk`)에 따라 다음 상태로 전이됩니다.  
수신 중인 데이터는 내부 레지스터에 순차적으로 저장되고, **패리티 비트는 따로 저장**됩니다.

### 3.2. 패리티 검사 및 출력 로직

Odd parity system 이므로 각 데이터 비트들과 parity bit를 합한 `parity_check_bit`의 XOR 연산이 1이면 (1의 개수가 홀수개) Odd parity 조건을 만족하므로 
유효한 데이터로 판단하고 현재 상태가 `STOP_BIT`일 때, `done=1`을 출력합니다.

```verilog
wire [8:0] parity_check_bit;
assign parity_check_bit = {r_out_byte, parity};
assign done = (c_state == STOP_BIT) && ^parity_check_bit;
```
---

## 4. 시뮬레이션 및 검증 결과


![FSM Diagram](sim_waves/1.FSM_Diagram.jpg)
해당 프로젝트 FSM의 전체 구조입니다.

---

![data=8'b01010101, parity bit=1](sim_waves/2.Test_1.jpg)
`out_byte=8'b0101_0101 (0x55)`, `parity=1`인 경우 Odd parity 조건을 만족하므로 `done=1`을 출력합니다.

---

![data=8'b10101010, parity bit=1](sim_waves/3.Test_2.jpg)
`out_byte=8'b1010_1010 (0xAA)`, `parity=1`인 경우 Odd parity 조건을 만족하므로 `done=1`을 출력합니다.

---

![data=8'b00000001, parity=0](sim_waves/4.Test_3.jpg)
`out_byte=8'b0000_0001 (0x01)`, `parity=1`인 경우 Odd parity 조건을 만족하지 않습니다. 그러므로 `done`을 출력하지 않습니다.

---

## 5. 결론

