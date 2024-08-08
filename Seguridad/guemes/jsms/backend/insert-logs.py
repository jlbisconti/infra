#!/usr/bin/env python3

import time
import json
import psycopg2
import logging
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configuración de conexión a la base de datos
db_config = {
    'host': "10.10.10.6",
    'dbname': 'suricata',
    'user': 'suricata',
    'password': 'murdok44'
}

# Configuración de logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

class LogHandler(FileSystemEventHandler):
    def __init__(self, conn, positions):
        self.conn = conn
        self.positions = positions

    def on_modified(self, event):
        if event.src_path == '/var/log/suricata/eve.json':
            process_eve_log(event.src_path, self.conn, 'eve_position', self.positions)
        elif event.src_path == '/var/log/suricata/fast.log':
            process_fast_log(event.src_path, self.conn, 'fast_position', self.positions)

def connect_db():
    try:
        conn = psycopg2.connect(**db_config)
        return conn
    except Exception as e:
        logging.error(f"Error conectando a la base de datos: {e}")
        return None

def insert_alert(record, conn):
    try:
        cursor = conn.cursor()
        timestamp = datetime.strptime(record['timestamp'], '%Y-%m-%dT%H:%M:%S.%f%z')
        src_ip = record['src_ip']
        src_port = record['src_port']
        dest_ip = record['dest_ip']
        dest_port = record['dest_port']
        protocol = record['proto']
        alert_signature = record['alert']['signature']
        alert_category = record['alert'].get('category', '')
        alert_severity = record['alert']['severity']

        cursor.execute("""
            INSERT INTO alerts (timestamp, src_ip, src_port, dest_ip, dest_port, protocol, alert_signature, alert_category, alert_severity)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (timestamp, src_ip, src_port, dest_ip, dest_port, protocol, alert_signature, alert_category, alert_severity))
        conn.commit()
    except Exception as e:
        logging.error(f"Error insertando alerta: {record} - {e}")
        conn.rollback()

def insert_drop(record, conn):
    try:
        cursor = conn.cursor()
        timestamp = datetime.strptime(record['timestamp'], '%Y-%m-%dT%H:%M:%S.%f%z')
        src_ip = record['src_ip']
        src_port = record['src_port']
        dest_ip = record['dest_ip']
        dest_port = record['dest_port']
        protocol = record['proto']
        drop_reason = record.get('drop_reason', '')

        cursor.execute("""
            INSERT INTO drops (timestamp, src_ip, src_port, dest_ip, dest_port, protocol, drop_reason)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (timestamp, src_ip, src_port, dest_ip, dest_port, protocol, drop_reason))
        conn.commit()
    except Exception as e:
        logging.error(f"Error insertando drop: {record} - {e}")
        conn.rollback()

def process_eve_log(log_file, conn, position_key, positions):
    try:
        with open(log_file, 'r') as f:
            f.seek(positions.get(position_key, 0))
            for line in f:
                try:
                    record = json.loads(line)
                    if record['event_type'] == 'alert':
                        insert_alert(record, conn)
                    elif record['event_type'] == 'drop':
                        insert_drop(record, conn)
                except json.JSONDecodeError:
                    logging.warning(f"Línea mal formateada en {log_file}: {line.strip()}")
            positions[position_key] = f.tell()
    except Exception as e:
        logging.error(f"Error procesando el archivo {log_file}: {e}")

def process_fast_log(log_file, conn, position_key, positions):
    try:
        with open(log_file, 'r') as f:
            f.seek(positions.get(position_key, 0))
            for line in f:
                # Fast.log parsing is different, not JSON formatted
                if "[Drop]" in line:
                    try:
                        timestamp_str = line.split(' ')[0]
                        timestamp = datetime.strptime(timestamp_str, '%m/%d/%Y-%H:%M:%S.%f')
                        src_ip = line.split(' ')[-5].split(':')[0]
                        src_port = int(line.split(' ')[-5].split(':')[1])
                        dest_ip = line.split(' ')[-3].split(':')[0]
                        dest_port = int(line.split(' ')[-3].split(':')[1])
                        protocol = line.split(' ')[-2].strip("{}")
                        drop_reason = line.split('**')[1].strip()

                        cursor = conn.cursor()
                        cursor.execute("""
                            INSERT INTO drops (timestamp, src_ip, src_port, dest_ip, dest_port, protocol, drop_reason)
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """, (timestamp, src_ip, src_port, dest_ip, dest_port, protocol, drop_reason))
                        conn.commit()
                    except Exception as e:
                        logging.error(f"Error insertando drop desde fast.log: {line} - {e}")
                        conn.rollback()
            positions[position_key] = f.tell()
    except Exception as e:
        logging.error(f"Error procesando el archivo {log_file}: {e}")

def main():
    conn = connect_db()
    if not conn:
        return

    positions = {
        'eve_position': 0,
        'fast_position': 0
    }

    event_handler = LogHandler(conn, positions)
    observer = Observer()
    observer.schedule(event_handler, path='/var/log/suricata/', recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

if __name__ == "__main__":
    main()
