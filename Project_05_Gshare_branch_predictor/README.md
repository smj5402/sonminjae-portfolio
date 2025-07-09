# Project_05_Gshare_branch_predictor

## 1. 프로젝트 개요
이 프로젝트는 **Global History Register(GHR) 및 Pattern History Table(PHT)** 을 이용하여 분기 방향을 예측하는 Gshare branch predictor를 구현한 것입니다.
현대 CPU 구조에서 branch predictor는 분기의 결과를 미리 예측하여 파이프라인 스톨(stall)을 줄이고, 고속 처리 성능을 유지하기 위해 필수적인 요소입니다. 그 중 Gshare은 PHT의 index를 결정하는 방식을 의미하며 다음과 같은 특징을 가집니다:

* 전역적인 분기 이력을 관리하는 GHR(Global History Register) 사용
* **Program Counter(PC)와 GHR을 XOR 기반 해싱(hashing) 방식으로 결합**하여 PHT 인덱스를 생성함으로써, 예측 테이블의 충돌을 줄이고 다양한 분기 패턴에 효과적으로 대응
* 각 인덱스마다 **2-bit saturating counter**로 구성된 **PHT**를 사용하여 예측 강도를 결정

---

## 2. 설계 목표

* GHR과 PHT를 활용한 Gshare 기반 branch prediction 구현  
* PC와 GHR의 XOR 결과를 PHT index로 사용  
* 각 PHT entry는 **2-bit saturating counter**로 동작
* 분기 예측 단계에서 예측에 따른 GHR 업데이트 로직
* 훈련 단계에서 훈련 값에 따라 예측 실패 판단, 실패 시 PHT 업데이트 및 GHR 복구 로직

---

## 3. 설계 구현

### 3.1. 모듈 구성

| 모듈 이름   | 설명 |
|----------------------------|------|
| `Gshare_branch_predictor`  | GHR과 2-bit PHT를 사용하여 분기 방향을 예측하고, 훈련 데이터로 업데이트하는 모듈 |
| `tb_Gshare_branch_predictor` | 다양한 분기 시나리오를 통해 예측과 훈련 과정을 시뮬레이션하는 테스트벤치 |



### 3.2. PHT 구조 및 예측 방식

* 2-bit saturating counter 정의
> `00`: Strong Not Taken

> `01`: Weak Not Taken
 
> `10`: Weak Taken

> `11`: Strong Taken 


* 예측 방식

>`PHT[index]`의 MSB가 1이면 **Taken**으로 예측, 0이면 **Not Taken**

* 훈련 방식
  
> `train_taken = 1` → counter를 +1 (최대값은 11)
> `train_taken = 0` → counter를 -1 (최소값은 00)

* 예측 실패 시
  
> GHR을 이전 GHR(예측 당시의 GHR(`train_history` + 실제 `train_taken`) 값으로 복구

```verilog
GHR <= { train_history[5:0], train_taken}; 
```

---

## 4. 시뮬레이션 및 검증 결과

![예측 실패 시 recovery logic](sim_waves/1.recovery_logic.jpg)
예측 실패 시, GHR recovery logic

---

![PHT update logic](sim_waves/2.PHT_update_logic.jpg)
PHT update logic

1. TEST_1 `predict_pc=7'd10`
   
-> PHT [10^0] = PHT[10] = 01 

-> predict_taken = 0

-> 실제 train_taken = 1

-> train_taken 1이므로 2-bit saturating counter 증가  01 -> 10

-> PHT[10] = 10

2. TEST_2 `predict_pc=7'd10`
   
-> PHT[10^1] = PHT[11]= 01

-> predict_taken = 0

-> 실제 train_taken = 0

-> train_taken 0이므로 2-bit saturating counter 감소  01 -> 00

-> PHT[11] = 00;

3. TEST_3 `predict_pc=7'd20`
   
-> PHT[20^2] = PHT[22] = 01

-> predict_taken = 0

-> 실제 train_taken = 0

-> train_taken 0이므로 2-bit saturating counter 감소  01 -> 00

->PHT[22] = 00;

4. TEST_4 `predict_pc=7'd14`
   
-> PHT[14^4]= PHT[10] = 10  (TEST_1에 의해)

-> predict_taken = 1

-> 실제 train_taken =0

-> train_taken 0이므로 2-bit saturating counter 감소 10 -> 01

-> PHT[10] = 01;

---

## 5. 결론




