"""
protocol.py - DHT11 모니터 통신 프로토콜 구현
===============================================
STM32 uart_protocol.h/.c 와 동일한 프로토콜을 Python으로 구현합니다.

패킷 구조:
    +------+------+------+-------------+------+
    | SOF  | LEN  | CMD  |   PAYLOAD   | CRC8 |
    | 0xAA |  1B  |  1B  |  LEN bytes  |  1B  |
    +------+------+------+-------------+------+
    CRC-8/SMBUS (poly=0x07): [LEN, CMD, PAYLOAD...] 에 대해 계산
"""

from __future__ import annotations
from dataclasses import dataclass


# ── 프레임 상수 ─────────────────────────────────────────────────────────────
SOF           = 0xAA
MAX_PAYLOAD   = 32

# ── PC → STM32 명령 ─────────────────────────────────────────────────────────
CMD_REQUEST_DATA    = 0x10   # 즉시 센서 데이터 요청 (payload: 없음)
CMD_SET_INTERVAL    = 0x11   # 측정 주기 설정      (payload: 1B, 초)
CMD_SET_BACKLIGHT   = 0x12   # LCD 백라이트 제어   (payload: 1B, 0=OFF/1=ON)
CMD_PING            = 0x13   # 연결 확인           (payload: 없음)

# ── STM32 → PC 응답 ─────────────────────────────────────────────────────────
CMD_SENSOR_DATA     = 0x81   # 센서 데이터  (payload: 2B = temp, humi)
CMD_ACK             = 0x82   # 명령 완료    (payload: 1B = 처리된 CMD)
CMD_ERROR           = 0x83   # 오류 응답    (payload: 1B = error code)
CMD_PONG            = 0x84   # PING 응답    (payload: 없음)

# ── 오류 코드 ───────────────────────────────────────────────────────────────
ERR_DHT11_TIMEOUT   = 0x01
ERR_DHT11_CHECKSUM  = 0x02
ERR_INVALID_CMD     = 0x03
ERR_INVALID_CRC     = 0x04
ERR_INVALID_LEN     = 0x05

CMD_NAMES: dict[int, str] = {
    CMD_REQUEST_DATA:  "REQUEST_DATA",
    CMD_SET_INTERVAL:  "SET_INTERVAL",
    CMD_SET_BACKLIGHT: "SET_BACKLIGHT",
    CMD_PING:          "PING",
    CMD_SENSOR_DATA:   "SENSOR_DATA",
    CMD_ACK:           "ACK",
    CMD_ERROR:         "ERROR",
    CMD_PONG:          "PONG",
}

ERR_NAMES: dict[int, str] = {
    ERR_DHT11_TIMEOUT:  "DHT11_TIMEOUT",
    ERR_DHT11_CHECKSUM: "DHT11_CHECKSUM",
    ERR_INVALID_CMD:    "INVALID_CMD",
    ERR_INVALID_CRC:    "INVALID_CRC",
    ERR_INVALID_LEN:    "INVALID_LEN",
}


# ── 패킷 데이터 클래스 ───────────────────────────────────────────────────────

@dataclass
class Packet:
    cmd:     int
    payload: bytes = b""

    @property
    def cmd_name(self) -> str:
        return CMD_NAMES.get(self.cmd, f"0x{self.cmd:02X}")

    def __repr__(self) -> str:
        pl = self.payload.hex(" ") if self.payload else "-"
        return f"Packet(cmd={self.cmd_name}, payload=[{pl}])"


# ── CRC-8/SMBUS ─────────────────────────────────────────────────────────────

def crc8(data: bytes) -> int:
    """XOR 체크섬 - 모든 바이트를 XOR 연산"""
    checksum = 0x00
    for byte in data:
        checksum ^= byte
    return checksum


# ── 패킷 빌드 ────────────────────────────────────────────────────────────────

def build_packet(cmd: int, payload: bytes = b"") -> bytes:
    """
    패킷 직렬화.
    Returns: SOF + LEN + CMD + PAYLOAD + CRC8 바이트열
    """
    length   = len(payload)
    crc_data = bytes([length, cmd]) + payload
    checksum = crc8(crc_data)
    return bytes([SOF, length, cmd]) + payload + bytes([checksum])


# ── 스트리밍 파서 (상태 머신) ────────────────────────────────────────────────

class PacketParser:
    """
    바이트 스트림에서 패킷을 추출하는 상태 머신 파서.
    바이트 단위로 feed()를 호출하면 완성된 패킷을 반환합니다.

    DMA + IDLE 방식처럼 버스트 단위로 도착하는 데이터도 처리 가능합니다.
    """
    _WAIT_SOF     = 0
    _WAIT_LEN     = 1
    _WAIT_CMD     = 2
    _WAIT_PAYLOAD = 3
    _WAIT_CRC     = 4

    def __init__(self) -> None:
        self._reset()

    def _reset(self) -> None:
        self._state      = self._WAIT_SOF
        self._length     = 0
        self._cmd        = 0
        self._payload    = bytearray()

    def feed(self, byte: int) -> Packet | None:
        """
        1바이트 입력.
        Returns: 완성된 Packet (CRC 유효) 또는 None
        """
        if self._state == self._WAIT_SOF:
            if byte == SOF:
                self._state = self._WAIT_LEN

        elif self._state == self._WAIT_LEN:
            if byte > MAX_PAYLOAD:
                self._reset()
            else:
                self._length = byte
                self._state  = self._WAIT_CMD

        elif self._state == self._WAIT_CMD:
            self._cmd     = byte
            self._payload = bytearray()
            self._state   = self._WAIT_CRC if self._length == 0 else self._WAIT_PAYLOAD

        elif self._state == self._WAIT_PAYLOAD:
            self._payload.append(byte)
            if len(self._payload) >= self._length:
                self._state = self._WAIT_CRC

        elif self._state == self._WAIT_CRC:
            # CRC 검증
            crc_data = bytes([self._length, self._cmd]) + bytes(self._payload)
            expected = crc8(crc_data)

            cmd     = self._cmd
            payload = bytes(self._payload)
            self._reset()

            if byte == expected:
                return Packet(cmd=cmd, payload=payload)
            # CRC 불일치 → 파기

        return None

    def feed_bytes(self, data: bytes) -> list[Packet]:
        """
        여러 바이트를 한 번에 입력.
        Returns: 수신된 유효 패킷 목록
        """
        result = []
        for b in data:
            pkt = self.feed(b)
            if pkt is not None:
                result.append(pkt)
        return result
