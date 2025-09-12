#!/bin/sh
set -eu
echo "klipper entrypoint starting"
if [ ! -x /work/target/debug/rk-mcu ]; then echo "rk-mcu binary missing; waiting for builder"; fi
i=0
while [ $i -lt 600 ] && [ ! -x /work/target/debug/rk-mcu ]; do
  sleep 1
  i=$((i+1))
done
echo "Starting rk-mcu..."
RK_MCU_SLAVE_PATH_FILE=/opt/printer_data/run/mcu_slave_path /work/target/debug/rk-mcu &
i=0
while [ $i -lt 120 ] && [ ! -s /opt/printer_data/run/mcu_slave_path ]; do
  sleep 1
  i=$((i+1))
done
PTY="$(cat /opt/printer_data/run/mcu_slave_path 2>/dev/null || true)"
echo "rk-mcu PTY: $PTY"
if [ -n "$PTY" ]; then ln -sf "$PTY" /opt/printer_data/run/klipper_host_mcu.tty; fi
ls -l /opt/printer_data/run || true
echo "Launching klippy"
umask 000
exec /opt/venv/bin/python klipper/klippy/klippy.py -I printer_data/run/klipper.tty -a printer_data/run/klipper.sock printer_data/config/printer.cfg -l printer_data/logs/klippy.log
