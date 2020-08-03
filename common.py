"""
shared resources
"""
# stdlib
import sqlite3
from contextlib import contextmanager

# 3rd party
import RPi.GPIO as GPIO

# local

PIN = 3
MAIN_DB = "/home/pi/webui/main.db"


@contextmanager
def db_conn():
    conn = sqlite3.connect(MAIN_DB)
    yield conn
    conn.close()


# numbers seem reversed here, 1 == off and 0 == on. This is a result of
# using the "Nomally on" outlet on the relay. This configuration sets the
# device OFF when the OS is down (rebooting, etc) but the raspi has power.
# This ensures that the device doesn't defualt to being on while the pi
# boots up.
def off():
    GPIO.output(PIN, 1)


def on():
    GPIO.output(PIN, 0)


def setup_gpio():
    GPIO.cleanup()
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(PIN, GPIO.OUT)
    off()


def is_on():
    return GPIO.input(PIN) == 0
