import tkinter as tk
from tkinter import ttk
import serial
import serial.tools.list_ports
import threading
import time
from datetime import datetime
from PIL import Image, ImageTk

# ─────────────────────────────────────────
# Protocol (STM32 규격)
# ─────────────────────────────────────────
PROTO_SOF        = 0xAA
CMD_SENSOR_DATA  = 0x81
CMD_FAN_SET_MODE = 0x30
CMD_FAN_SET_SPEED= 0x31
FAN_MODE_MANUAL  = 0
FAN_MODE_AUTO    = 1

def crc8(data: bytes) -> int:
    v = 0
    for b in data: v ^= b
    return v

def build_packet(cmd, payload=b''):
    ln  = len(payload)
    chk = crc8(bytes([ln, cmd]) + payload)
    return bytes([PROTO_SOF, ln, cmd]) + payload + bytes([chk])

# ─────────────────────────────────────────
# 색상 및 환경 설정
# ─────────────────────────────────────────
C = {
    'bg':    '#0f172a',
    'surf':  '#1e293b',
    'surf2': '#243044',
    'text':  '#ffffff',
    'text2': '#cbd5e1',
    'green': '#4ade80',
    'red':   '#f87171',
    'purple':'#a855f7',
    'blue':  '#60a5fa',
}

TARGET_TEMP_MIN, TARGET_TEMP_MAX = 18.0, 28.0
TARGET_HUMI_MIN, TARGET_HUMI_MAX = 40.0, 65.0

# ─────────────────────────────────────────
# CocoBot 상태 엔진
# ─────────────────────────────────────────
class CocoBotState:
    def __init__(self):
        self.started = False
        self._init_state()

    def _init_state(self):
        self.started           = False
        self.life              = 70.0
        self.comfort           = 100.0
        self.temp, self.humi   = 23.0, 55.0
        self.alive             = True
        self.is_complete       = False
        self.stage_index       = 0
        self.stage             = 'egg'
        self.time_spent_happy  = 0.0
        self.last_update_time  = time.time()
        self.status_message    = "대기 중.. '시작'을 눌러주세요 ⏳"
        self.comfort_history   = []
        self.health_history    = []

    def update(self, temp, humi):
        if not self.started or not self.alive or self.is_complete: return
        if temp == 0 and humi == 0: return

        self.temp, self.humi = temp, humi
        now = time.time()
        dt  = now - self.last_update_time
        self.last_update_time = now

        t_penalty = max(0, TARGET_TEMP_MIN - temp) * 4 + max(0, temp - TARGET_TEMP_MAX) * 4
        h_penalty = max(0, TARGET_HUMI_MIN - humi) * 1.5 + max(0, humi - TARGET_HUMI_MAX) * 1.5
        self.comfort = max(0, 100 - t_penalty - h_penalty)

        msg_list = []
        if   temp < TARGET_TEMP_MIN: msg_list.append("추워요 🥶")
        elif temp > TARGET_TEMP_MAX: msg_list.append("더워요 🥵")
        if   humi < TARGET_HUMI_MIN: msg_list.append("건조해요 🌵")
        elif humi > TARGET_HUMI_MAX: msg_list.append("습해요 💦")

        if self.comfort < 70:
            self.life -= 2.0 * dt
            self.status_message = " / ".join(msg_list) if msg_list else "환경이 나빠요! 🤢"
        else:
            self.life = min(100, self.life + 1.0 * dt)
            self.time_spent_happy += dt
            self.status_message = "쾌적해요 😊"

        self.comfort_history.append(self.comfort)
        self.health_history.append(self.life)

        if self.life <= 0:
            self.stage = 'dead'; self.alive = False
            self.status_message = "사망했습니다.."
        elif self.time_spent_happy >= 10.0:
            stages = ['egg', 'larva', 'pupa', 'butterfly']
            if self.stage_index < 3:
                self.stage_index += 1
                self.stage = stages[self.stage_index]
                self.time_spent_happy = 0.0
            if self.stage == 'butterfly':
                self.is_complete = True
                score = self.calculate_score()
                self.status_message = f"진화 성공! ✨\n최종 점수: {score}점"

    def calculate_score(self):
        if not self.comfort_history: return 0
        avg_c = sum(self.comfort_history) / len(self.comfort_history)
        avg_h = sum(self.health_history)  / len(self.health_history)
        return int(avg_c * 0.4 + avg_h * 0.6)

# ─────────────────────────────────────────
# 온실 패널 컴포넌트
# ─────────────────────────────────────────
class GreenHousePanel:
    def __init__(self, parent, idx, log_fn, send_fn, image_path):
        self.idx        = idx
        self.color      = [C['green'], C['blue'], C['purple']][idx]
        self.name       = f"Zone {idx+1}"
        self.icon       = ['🌿', '💧', '🌸'][idx]
        self.log_fn     = log_fn
        self.send_fn    = send_fn
        self.image_path = image_path
        self.pet        = CocoBotState()
        self._build(parent)

    def _build(self, parent):
        self.outer = tk.Frame(parent, bg=C['bg'],
                              highlightbackground=self.color, highlightthickness=1)
        self.outer.pack(fill='both', expand=True, padx=10, pady=2)
        self.cv = tk.Canvas(self.outer, bg=C['bg'], height=340, highlightthickness=0)
        self.cv.pack(fill='both', expand=True)
        self.info_box = tk.Frame(self.cv, bg=C['surf'], padx=20, pady=10)
        self.win_id   = self.cv.create_window(0, 0, window=self.info_box, anchor='center')

        tk.Label(self.info_box, text=f"{self.icon} {self.name}",
                 font=('Helvetica', 14, 'bold'), bg=C['surf'], fg=self.color).pack()
        mid_row = tk.Frame(self.info_box, bg=C['surf']); mid_row.pack(pady=5)

        # 진행도 바
        prog_f = tk.Frame(mid_row, bg=C['surf']); prog_f.pack(side='left', padx=10, pady=(15, 0))
        self.p_cv  = tk.Canvas(prog_f, width=12, height=60, bg='#000000', highlightthickness=0)
        self.p_cv.pack()
        self.p_bar = self.p_cv.create_rectangle(0, 60, 12, 60, fill=C['purple'], outline="")
        tk.Label(prog_f, text="진행도", font=('Helvetica', 8), bg=C['surf'], fg=C['purple']).pack()
        self.p_lbl = tk.Label(prog_f, text="0%", font=('Helvetica', 8, 'bold'),
                              bg=C['surf'], fg=C['purple']); self.p_lbl.pack()

        self.emoji_lbl  = tk.Label(mid_row, text='🥚', font=('Helvetica', 45),
                                   bg=C['surf'], fg='white'); self.emoji_lbl.pack(side='left')
        self.status_lbl = tk.Label(mid_row, text=self.pet.status_message,
                                   font=('Helvetica', 11, 'bold'), bg=C['surf'], fg=C['text2'],
                                   wraplength=200, justify='left'); self.status_lbl.pack(side='left', padx=10)

        self.stage_lbl = tk.Label(self.info_box, text='현재 단계: 알',
                                  font=('Helvetica', 10), bg=C['surf'], fg='white'); self.stage_lbl.pack()

        tk.Label(self.info_box, text="환경 쾌적도",
                 font=('Helvetica', 7), bg=C['surf'], fg=C['text2']).pack()
        self.c_cv  = tk.Canvas(self.info_box, width=300, height=8, bg='#000000', highlightthickness=0)
        self.c_cv.pack(pady=1)
        self.c_bar = self.c_cv.create_rectangle(0, 0, 300, 8, fill=C['green'], outline="")

        tk.Label(self.info_box, text="캐릭터 건강도",
                 font=('Helvetica', 7), bg=C['surf'], fg=C['text2']).pack()
        self.h_cv  = tk.Canvas(self.info_box, width=300, height=8, bg='#000000', highlightthickness=0)
        self.h_cv.pack(pady=1)
        self.h_bar = self.h_cv.create_rectangle(0, 0, (70/100)*300, 8, fill=C['green'], outline="")

        v_frame = tk.Frame(self.info_box, bg=C['surf']); v_frame.pack(pady=5)
        self.temp_lbl = tk.Label(v_frame, text='00°C', font=('Helvetica', 20, 'bold'),
                                 bg=C['surf'], fg=C['blue']); self.temp_lbl.pack(side='left', padx=10)
        self.humi_lbl = tk.Label(v_frame, text='00%', font=('Helvetica', 20, 'bold'),
                                 bg=C['surf'], fg=C['purple']); self.humi_lbl.pack(side='left', padx=10)

        btn_f = tk.Frame(self.info_box, bg=C['surf']); btn_f.pack(fill='x', pady=2)
        tk.Button(btn_f, text="AUTO",   bg=C['surf2'], fg='white',
                  command=self._handle_auto).pack(side='left', expand=True, fill='x', padx=1)
        tk.Button(btn_f, text="MANUAL", bg=C['surf2'], fg='white',
                  command=self._handle_manual).pack(side='left', expand=True, fill='x', padx=1)
        self.btn_start = tk.Button(btn_f, text="시작 🚀", bg=C['surf2'], fg='white',
                                   font=('bold'), command=self._handle_start_reset)
        self.btn_start.pack(side='left', expand=True, fill='x', padx=1)

        self.spd_scale = tk.Scale(self.info_box, from_=0, to=100, orient='horizontal',
                                  bg=C['surf'], fg=C['text2'], highlightthickness=0,
                                  troughcolor=C['surf2'], command=self._set_speed, length=400)
        self.spd_scale.pack(pady=(2, 10))
        self.cv.bind("<Configure>", self._on_resize)

    def _handle_auto(self):
        self._send_fan_mode(FAN_MODE_AUTO)
        self.log_fn(self.idx, "명령: AUTO 모드 활성화")

    def _handle_manual(self):
        self._send_fan_mode(FAN_MODE_MANUAL)
        current_spd = int(self.spd_scale.get())
        self._send_fan_speed(current_spd)
        self.log_fn(self.idx, f"명령: MANUAL 모드 활성화 (속도 {current_spd}% 반영)")

    def _handle_start_reset(self):
        if not self.pet.started:
            self.pet.started = True
            self.pet.status_message = "새로운 시작 🌱"
            self.btn_start.config(text="초기화 ♻️", fg=C['red'])
            self.log_fn(self.idx, "키우기 시작!")
        else:
            self.pet._init_state()
            self.btn_start.config(text="시작 🚀", fg='white')
            self.log_fn(self.idx, "상태 초기화 및 대기 모드로 전환")
            self._update_ui_display(0, 0)

    def _on_resize(self, event):
        try:
            img = Image.open(self.image_path).resize((event.width, event.height), Image.LANCZOS)
            self.tk_img = ImageTk.PhotoImage(img)
            self.cv.delete("bg")
            self.cv.create_image(0, 0, image=self.tk_img, anchor='nw', tags="bg")
            self.cv.tag_lower("bg")
        except:
            pass
        self.cv.coords(self.win_id, event.width // 2, event.height // 2)

    def update(self, t, h):
        if not self.pet.started:
            self._update_ui_display(0, 0)
            return
        self.pet.update(t, h)
        self._update_ui_display(t, h)

    def _update_ui_display(self, t, h):
        stages_kor   = {'egg':'알','larva':'애벌레','pupa':'번데기','butterfly':'나비','dead':'사망'}
        stages_emoji = {'egg':'🥚','larva':'🐛','pupa':'🫘','butterfly':'🦋','dead':'💀'}
        self.emoji_lbl.config(text=stages_emoji.get(self.pet.stage, '🥚'))
        self.temp_lbl.config(text=f"{t:02d}°C")
        self.humi_lbl.config(text=f"{h:02d}%")
        self.status_lbl.config(text=self.pet.status_message)
        self.stage_lbl.config(text=f"현재 단계: {stages_kor.get(self.pet.stage, '알')}")
        comfort_val = 100.0 if not self.pet.started else self.pet.comfort
        c_color = C['green'] if comfort_val >= 70 else C['red']
        self.c_cv.coords(self.c_bar, 0, 0, (comfort_val/100)*300, 8)
        self.c_cv.itemconfig(self.c_bar, fill=c_color)
        h_color = C['green'] if self.pet.life >= 50 else C['red']
        self.h_cv.coords(self.h_bar, 0, 0, (self.pet.life/100)*300, 8)
        self.h_cv.itemconfig(self.h_bar, fill=h_color)
        ratio = self.pet.time_spent_happy / 10.0
        self.p_cv.coords(self.p_bar, 0, 60 - (ratio*60), 12, 60)
        self.p_lbl.config(text=f"{int(ratio*100)}%")

    def _set_speed(self, v):
        spd = int(v)
        self._send_fan_speed(spd)
        if spd % 10 == 0:
            self.log_fn(self.idx, f"팬 속도 조절: {spd}%")

    def _send_fan_mode(self, mode):
        self.send_fn(build_packet(CMD_FAN_SET_MODE, bytes([self.idx + 1, mode])))

    def _send_fan_speed(self, v):
        self.send_fn(build_packet(CMD_FAN_SET_SPEED, bytes([self.idx + 1, int(v)])))

# ─────────────────────────────────────────
# 메인 GUI
# ─────────────────────────────────────────
class CocoBotGUI:
    def __init__(self, root):
        self.root   = root
        self.root.title("🌿 CocoBot Smart Farm")
        self.root.geometry("1550x1150")
        self.root.configure(bg=C['bg'])
        self.ser    = None
        self.buffer = bytearray()
        self._build_ui()

    def _build_ui(self):
        top = tk.Frame(self.root, bg='#1e293b', pady=10); top.pack(fill='x')
        self.cb_port = ttk.Combobox(top, values=self._get_ports(), width=15)
        self.cb_port.pack(side='left', padx=20)
        self.cb_port.bind("<ButtonPress>", lambda e: self.cb_port.config(values=self._get_ports()))
        self.btn_conn = tk.Button(top, text="연결하기", bg=C['green'],
                                  command=self._toggle_conn, relief='flat')
        self.btn_conn.pack(side='left')

        main_cont = tk.Frame(self.root, bg=C['bg']); main_cont.pack(fill='both', expand=True)
        self.p_frame = tk.Frame(main_cont, bg=C['bg'])
        self.p_frame.pack(side='left', fill='both', expand=True, padx=(10, 5))
        # GUI 배경 이미지는 스크립트와 같은 폴더의 farm_bg.png 를 참조
        self.panels = [GreenHousePanel(self.p_frame, i, self._add_log,
                                       self._send, "farm_bg.png") for i in range(3)]

        log_frame = tk.Frame(main_cont, bg=C['surf'], padx=5, pady=5)
        log_frame.pack(side='right', fill='both', padx=(5, 15), pady=10)
        tk.Label(log_frame, text="📋 SYSTEM LOG", font=('Consolas', 10, 'bold'),
                 bg=C['surf'], fg=C['green']).pack(pady=(0, 5))
        self.log_txt = tk.Text(log_frame, width=55, bg='#0f172a', fg=C['text2'],
                               font=('Consolas', 10), borderwidth=0)
        scrollbar = tk.Scrollbar(log_frame, command=self.log_txt.yview)
        self.log_txt.config(yscrollcommand=scrollbar.set)
        scrollbar.pack(side='right', fill='y')
        self.log_txt.pack(side='left', fill='both', expand=True)

    def _get_ports(self):
        return [p.device for p in serial.tools.list_ports.comports()]

    def _add_log(self, idx, msg):
        ts     = datetime.now().strftime("%H:%M:%S")
        prefix = f"Zone {idx+1}" if idx < 9 else "System"
        self.log_txt.insert('end', f"[{ts}] {prefix}: {msg}\n")
        self.log_txt.see('end')

    def _toggle_conn(self):
        if self.ser and self.ser.is_open:
            self._close_serial()
        else:
            port = self.cb_port.get()
            if not port:
                self._add_log(9, "포트를 선택해주세요.")
                return
            try:
                self.ser = serial.Serial(port, 115200, timeout=0.1)
                self.btn_conn.config(text="연결해제", bg=C['red'])
                self._add_log(9, f"포트 연결 성공: {port}")
                threading.Thread(target=self._read_serial, daemon=True).start()
            except Exception as e:
                self._add_log(9, f"연결 실패: {e}")
                self._close_serial()

    def _close_serial(self):
        if self.ser:
            try: self.ser.close()
            except: pass
        self.ser = None
        self.btn_conn.config(text="연결하기", bg=C['green'])
        self._add_log(9, "연결이 해제되었습니다.")

    def _read_serial(self):
        try:
            while self.ser and self.ser.is_open:
                if self.ser.in_waiting:
                    self.buffer.extend(self.ser.read(self.ser.in_waiting))
                while len(self.buffer) >= 5:
                    if self.buffer[0] == PROTO_SOF:
                        ln = self.buffer[1]
                        if len(self.buffer) < ln + 4: break
                        if crc8(self.buffer[1:3+ln]) == self.buffer[3+ln]:
                            self._handle_pkt(self.buffer[2], self.buffer[3:3+ln])
                        del self.buffer[:ln+4]
                    else:
                        del self.buffer[0]
                time.sleep(0.01)
        except:
            self.root.after(0, lambda: self._add_log(9, "통신 오류로 연결이 중단되었습니다."))
        finally:
            self.root.after(0, self._close_serial)

    def _handle_pkt(self, cmd, payload):
        if cmd == 0x81:
            idx = payload[0] - 1
            if 0 <= idx < 3:
                self.root.after(0, self.panels[idx].update, payload[1], payload[2])

    def _send(self, data):
        if self.ser and self.ser.is_open:
            try: self.ser.write(data)
            except: self._close_serial()

if __name__ == "__main__":
    root = tk.Tk()
    app  = CocoBotGUI(root)
    root.mainloop()