"""
main webui for home automation projects
"""
# stdlib
import sqlite3
from contextlib import contextmanager
import logging

# 3rd party
from flask import Flask, render_template, redirect, url_for, jsonify
import RPi.GPIO as GPIO
import pendulum
from waitress import serve
from paste.translogger import TransLogger

# local
from common import PIN, MAIN_DB, db_conn, off, on, setup_gpio, is_on

logger = logging.getLogger("waitress")
logger.setLevel(logging.INFO)

app = Flask(__name__)


@app.route("/")
def index():
    current_state = "ON" if is_on() else "OFF"
    data = {"current_state": current_state}
    return render_template("index.j2", data=data)


@app.route("/on")
def turn_on():
    on()
    return redirect(url_for("index"))


@app.route("/off")
def turn_off():
    off()
    return redirect(url_for("index"))


@app.route("/api/latest_runs")
def latest_runs():
    with db_conn() as conn:
        c = conn.cursor()
        c.execute("SELECT * FROM cron ORDER BY start DESC LIMIT 5;")
        rows = c.fetchall()

    res = {"latest_runs": [{"start": r[0], "end": r[1]} for r in rows]}
    return jsonify(res)


setup_gpio()
serve(TransLogger(app, setup_console_handler=False))
