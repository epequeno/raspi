"""
scheduled tasks
"""
# stdlib
import sqlite3
from contextlib import contextmanager
from time import sleep

# 3rd party
import RPi.GPIO as GPIO
import pendulum
import schedule

# local
from common import PIN, MAIN_DB, db_conn, off, on, setup_gpio


with db_conn() as conn:
    c = conn.cursor()
    c.execute("CREATE TABLE IF NOT EXISTS cron (start INT, end INT)")
    conn.commit()

setup_gpio()


def program_a():
    """
    on 3 min
    off 3 min
    on 3 min 
    off
    """
    three_mins = 3 * 60  # in seconds

    start_time = pendulum.now().int_timestamp
    on()
    sleep(three_mins)

    off()
    sleep(three_mins)

    on()
    sleep(three_mins)

    off()
    end_time = pendulum.now().int_timestamp

    with db_conn() as conn:
        c = conn.cursor()
        values = (start_time, end_time)
        c.execute("INSERT INTO cron VALUES (?,?)", values)
        conn.commit()


schedule.every().day.at("06:00").do(program_a)
schedule.every().day.at("15:00").do(program_a)

while True:
    schedule.run_pending()
    sleep(1)
