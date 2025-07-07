# Verilog 프로젝트 포트폴리오
이 포트폴리오는 Verilog HDL을 활용하여 구현한 5개의 디지털 설계 프로젝트와 각 프로젝트의 동작 검증을 위한 Testbench, 시뮬레이션 결과를 포함하고 있습니다.

---

## 사용 툴 및 개발 환경
설계 툴 
- Visual Studio code (Windows)
- Vim (Linux Ubuntu 환경)

시뮬레이션 툴 
- Modelsim
- Vivado Simulator

---

## 프로젝트 목록
### 1. [**Digital Clock (12시간 형식 디지털 시계)**](./Project_01_Digital_Clock/README.md)  
- 1Hz 펄스 발생기, BCD counter(시,분,초 구성), AM/PM 전환 로직으로 구성
- 각 기능별 모듈의 계층적 설계를 통해 top_module에서 통합
- BCD counter 간 carry 연계를 통해 시간의 흐름 구현

---

### 2. [**Serial Receiver with Odd Parity Check**](./Project_02_Serial_Rx_Parity/README.md)  
- 시리얼 입력 데이터를 수신하고 홀수 패리티 검사를 통해 데이터의 유효성 판단
- FSM 구조로 동작 ( 'IDLE -> START -> DATA 수신 -> PARITY -> STOP' )

---

### 3. [**BRAM Controller**](./Project_03_BRAM_Controller/README.md)  
- BRAM에 데이터 읽기 및 쓰기를 제어하는 컨트롤러
- FSM 구조로 동작 ( 'IDLE -> WRITE -> READ -> DONE' )

---

### 4. [**Parameterized Exponential Pipelining**](./Project_04_param_exp_pipe/README.md)  
- 입력 데이터 i_data를 받아 파이프라인 구조를 통해 i^8 계산 수행
- LATENCY의 파라미터 기반 설계로 확장성, 재사용성 고려

---

### 5. [**Gshare Branch Predictor**](./Project_05_Gshare_branch_predictor/README.md)  
- Global History Register(GHR)과 Pattern History Table(PHT)을 기반으로 한 분기 예측기
- 2비트 포화 카운터를 이용한 예측 및 학습 기능 구현

---

각 프로젝트의 상세 내용과 Testbench, 파형 결과 등은 각 디렉토리의 'README.md'를 참고하세요.
감사합니다.
