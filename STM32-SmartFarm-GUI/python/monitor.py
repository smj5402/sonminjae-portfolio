"""
monitor.py - DHT11 온습도 모니터 (프로토콜 기반)
=================================================
Nucleo-F411RE와 구조화된 패킷 프로토콜로 통신합니다.

키보드 명령:
    r  - 즉시 센서 데이터 요청
    i  - 측정 주기 변경
    b  - LCD 백라이트 ON/OFF 토글
    p  - PING 전송
    q  - 종료

설치:
    pip install pyserial

실행:
    python monitor.py
    python monitor.py --port COM3
    python monitor.py --port COM3 --baud 115200
"""

import serial
import serial.tools.list_ports
import argparse
import sys
import threading
import queue
import msvcrt
from datetime import datetime

import protocol as proto


# ── ANSI 색상 ───────────────────────────────────────────────────────────────

class C:
    RESET  = "\033[0m"
    BOLD   = "\033[1m"
    RED    = "\033[91m"
    GREEN  = "\033[92m"
    YELLOW = "\033[93m"
    BLUE   = "\033[94m"
    CYAN   = "\033[96m"
    WHITE  = "\033[97m"
    GRAY   = "\033[90m"

def clr(text: str, color: str) -> str:
    return f"{color}{text}{C.RESET}"


# ── 포트 탐색 ────────────────────────────────────────────────────────────────

def find_nucleo_port() -> str | None:
    for p in serial.tools.list_ports.comports():
        desc = (p.description or "").upper()
        mfr  = (p.manufacturer or "").upper()
        if any(kw in desc or kw in mfr for kw in ["STM", "ST-LINK", "NUCLEO"]):
            return p.device
    ports = serial.tools.list_ports.comports()
    return ports[0].device if ports else None

def list_ports() -> None:
    ports = serial.tools.list_ports.comports()
    if not ports:
        print(clr("  사용 가능한 포트 없음", C.RED))
        return
    print(clr("\n사용 가능한 시리얼 포트:", C.CYAN))
    for p in sorted(ports, key=lambda x: x.device):
        print(f"  {clr(p.device, C.GREEN):20s}  {p.description}")


# ── 모니터 클래스 ────────────────────────────────────────────────────────────

class DHT11Monitor:
    def __init__(self, port: str, baud: int) -> None:
        self._ser     = serial.Serial(port, baud, timeout=0.1)
        self._parser  = proto.PacketParser()
        self._rxq:     queue.Queue[proto.Packet] = queue.Queue()
        self._running  = True
        self._backlight_on = True

        # 통계
        self._temps:  list[int] = []
        self._humis:  list[int] = []
        self._errors: int = 0
        self._count:  int = 0

    # ── 시리얼 수신 스레드 ───────────────────────────────

    def _rx_thread(self) -> None:
        while self._running:
            try:
                data = self._ser.read(64)
                for pkt in self._parser.feed_bytes(data):
                    self._rxq.put(pkt)
            except serial.SerialException:
                self._running = False
                break

    # ── 패킷 전송 헬퍼 ──────────────────────────────────

    def _send(self, cmd: int, payload: bytes = b"") -> None:
        raw = proto.build_packet(cmd, payload)
        self._ser.write(raw)

    # ── 수신 패킷 처리 ──────────────────────────────────

    def _handle_packet(self, pkt: proto.Packet) -> None:
        self._count += 1
        now = datetime.now().strftime("%H:%M:%S")
        prefix = f"  [{clr(now, C.GRAY)}]  #{self._count:<4d}"

        if pkt.cmd == proto.CMD_SENSOR_DATA and len(pkt.payload) >= 2:
            temp = pkt.payload[0]
            humi = pkt.payload[1]
            self._temps.append(temp)
            self._humis.append(humi)

            temp_color = C.BLUE if temp < 10 else (C.GREEN if temp < 28 else C.RED)
            humi_color = C.YELLOW if humi < 30 else (C.GREEN if humi < 70 else C.BLUE)

            print(f"{prefix}  "
                  f"온도: {clr(f'{temp:3d} °C', temp_color)}   "
                  f"습도: {clr(f'{humi:3d} %', humi_color)}")

        elif pkt.cmd == proto.CMD_ACK and len(pkt.payload) >= 1:
            acked = proto.CMD_NAMES.get(pkt.payload[0], f"0x{pkt.payload[0]:02X}")
            print(f"{prefix}  {clr(f'[ACK] {acked}', C.GREEN)}")

        elif pkt.cmd == proto.CMD_ERROR and len(pkt.payload) >= 1:
            err = proto.ERR_NAMES.get(pkt.payload[0], f"0x{pkt.payload[0]:02X}")
            self._errors += 1
            print(f"{prefix}  {clr(f'[ERROR] {err}', C.RED)}")

        elif pkt.cmd == proto.CMD_PONG:
            print(f"{prefix}  {clr('[PONG] 연결 확인됨', C.CYAN)}")

        else:
            pl = pkt.payload.hex(" ") if pkt.payload else "-"
            print(f"{prefix}  {clr(f'[{pkt.cmd_name}] payload=[{pl}]', C.GRAY)}")

    # ── 키보드 명령 처리 ────────────────────────────────

    def _handle_key(self, key: bytes) -> bool:
        """Returns False if quit requested."""
        ch = key.lower()

        if ch == b'r':
            self._send(proto.CMD_REQUEST_DATA)
            print(clr("  → 즉시 센서 데이터 요청", C.YELLOW))

        elif ch == b'b':
            self._backlight_on = not self._backlight_on
            val = 1 if self._backlight_on else 0
            self._send(proto.CMD_SET_BACKLIGHT, bytes([val]))
            state = "ON" if self._backlight_on else "OFF"
            print(clr(f"  → LCD 백라이트 {state}", C.YELLOW))

        elif ch == b'p':
            self._send(proto.CMD_PING)
            print(clr("  → PING 전송", C.YELLOW))

        elif ch == b'i':
            print(clr("\n  측정 주기(초, 1~255): ", C.YELLOW), end="", flush=True)
            try:
                val = int(input())
                if 1 <= val <= 255:
                    self._send(proto.CMD_SET_INTERVAL, bytes([val]))
                    print(clr(f"  → 주기 {val}초 설정 요청", C.YELLOW))
                else:
                    print(clr("  유효 범위: 1~255", C.RED))
            except ValueError:
                print(clr("  숫자를 입력하세요", C.RED))

        elif ch == b'q':
            return False

        elif ch == b'h':
            self._print_help()

        return True

    def _print_help(self) -> None:
        print(clr("\n  ─── 키보드 명령 ──────────────────────────────", C.CYAN))
        print("    r  즉시 센서 데이터 요청")
        print("    i  측정 주기 변경")
        print("    b  LCD 백라이트 ON/OFF")
        print("    p  PING 전송")
        print("    h  도움말")
        print(clr("    q  종료\n", C.GRAY))

    # ── 통계 출력 ────────────────────────────────────────

    def _print_stats(self) -> None:
        total = len(self._temps) + self._errors
        if total == 0:
            return
        print()
        print(clr("─── 통계 ──────────────────────────────────────", C.CYAN))
        print(f"  총 수신: {total}회  "
              f"(정상: {clr(str(len(self._temps)), C.GREEN)}  "
              f"오류: {clr(str(self._errors), C.RED)})")
        if self._temps:
            avg = sum(self._temps) / len(self._temps)
            print(f"  온도  최소: {min(self._temps):3d}°C  "
                  f"최대: {max(self._temps):3d}°C  평균: {avg:.1f}°C")
        if self._humis:
            avg = sum(self._humis) / len(self._humis)
            print(f"  습도  최소: {min(self._humis):3d}%   "
                  f"최대: {max(self._humis):3d}%   평균: {avg:.1f}%")
        print()

    # ── 메인 루프 ────────────────────────────────────────

    def run(self) -> None:
        print()
        print(clr("╔══════════════════════════════════════════════╗", C.CYAN))
        print(clr("║    DHT11 온습도 모니터  (Nucleo-F411RE)      ║", C.CYAN))
        print(clr("╚══════════════════════════════════════════════╝", C.CYAN))
        print(f"  포트: {clr(self._ser.port, C.GREEN)}  "
              f"보드레이트: {clr(str(self._ser.baudrate), C.GREEN)}")
        print(clr("  h = 도움말  /  q = 종료\n", C.GRAY))
        print(clr("─── 수신 데이터 ────────────────────────────────", C.CYAN))

        # 수신 스레드 시작
        t = threading.Thread(target=self._rx_thread, daemon=True)
        t.start()

        try:
            while self._running:
                # 수신 패킷 처리
                try:
                    while True:
                        pkt = self._rxq.get_nowait()
                        self._handle_packet(pkt)
                except queue.Empty:
                    pass

                # 키보드 입력 처리 (논블로킹)
                if msvcrt.kbhit():
                    key = msvcrt.getch()
                    if not self._handle_key(key):
                        break

        except KeyboardInterrupt:
            pass
        finally:
            self._running = False
            self._print_stats()
            self._ser.close()


# ── 진입점 ───────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="DHT11 온습도 모니터")
    parser.add_argument("--port", "-p", type=str, default=None)
    parser.add_argument("--baud", "-b", type=int, default=115200)
    parser.add_argument("--list", "-l", action="store_true", help="포트 목록 출력")
    args = parser.parse_args()

    if args.list:
        list_ports()
        return

    port = args.port or find_nucleo_port()
    if port is None:
        print(clr("오류: 시리얼 포트를 찾을 수 없습니다.", C.RED))
        list_ports()
        sys.exit(1)

    try:
        monitor = DHT11Monitor(port, args.baud)
        monitor.run()
    except serial.SerialException as e:
        print(clr(f"포트 열기 실패: {e}", C.RED))
        list_ports()
        sys.exit(1)


if __name__ == "__main__":
    main()
