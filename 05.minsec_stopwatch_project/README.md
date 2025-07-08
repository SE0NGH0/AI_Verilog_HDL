# ⏱ MINSEC_WATCH / STOPWATCH for Basys3 FPGA

> 4-digit 7-segment display 기반 **분·초 시계(MINSEC_WATCH)** 및 **스톱워치(STOPWATCH)** 시스템  
> Verilog HDL 기반 FSM 설계 | Basys3 FPGA 개발보드 사용

---

## 📌 프로젝트 개요

본 프로젝트는 **Basys3 (100MHz)** FPGA 보드와 4자리 7-Segment Display를 활용하여 3가지 디지털 시계 모드를 구현합니다:

1. **IDLE 모드**: CIRCLE 애니메이션 (회전 점 표시)
2. **MINSEC_WATCH 모드**: 분·초 단위 디지털 시계
3. **STOPWATCH 모드**: 스톱워치 (시작, 정지, 초기화 기능 포함)

---

## 🔧 시스템 구성

### ✅ 입력 (버튼)
- `BTN[0]`: 모드 전환 (IDLE → WATCH → STOPWATCH → IDLE)
- `BTN[1]`: STOPWATCH 시작/정지 토글
- `BTN[2]`: STOPWATCH 초기화
- `BTN[3]`: IDLE 모드 회전 속도 변경
- `RESET`: 모든 모드에서 IDLE로 복귀

### ✅ 출력
- `FND[3:0]`, `SEG[6:0]`: 7-세그먼트 디스플레이

---

## 🧠 FSM 설계

모든 동작은 Finite State Machine(FSM) 기반으로 제어되며, 버튼 에지 검출 및 각 모드별 동작을 Verilog로 세분화하여 구현하였습니다.

| 모드        | 기능 설명 |
|-------------|-----------|
| `IDLE`      | 회전 애니메이션, 속도 4단계 조절 가능 |
| `MINSEC_WATCH` | 00:00 ~ 59:59까지 분·초 디지털 시계 |
| `STOPWATCH` | 최대 30초까지 스톱워치, 무동작 시 자동 IDLE 복귀 |

---

## 📁 주요 소스코드

### ▶ `btn_command_controller.v`

- FSM 모드 전환
- 버튼 에지 검출 (prev_btnL)
- STOPWATCH 실행/정지, 초기화 제어
- 30초 무동작 시 자동 IDLE 복귀
- 속도 테이블 기반 회전 속도 제어

### ▶ `fnd_controller.v`

- 모드별로 FND 표시 위치 및 값 설정
- 분리된 자리수 연산 및 BCD 변환
- 회전 애니메이션 or 숫자 표시용 `seg_data` 생성

---

## 🧮 하드웨어/소프트웨어 개념 요약

| 항목 | 설명 |
|------|------|
| **FPGA vs C언어** | 병렬 vs 순차, 회로 정의 vs 명령어 나열 |
| **Latch vs Flip-Flop** | 레벨 트리거 vs 엣지 트리거 |
| **Blocking (=) vs Non-blocking (<=)** | 순차 실행 vs 병렬 실행 |
| **조합 vs 순차 회로** | 기억 기능 없음 vs 있음 |
| **Setup/Hold Time** | 클럭 엣지 전/후 데이터 안정 시간 |

---

## 📸 결과 영상

> 📽 [시연 영상 보러가기](https://youtu.be/3Lz6mxAgbA8)

---
