from flask import Flask, request, jsonify
import psycopg2

app = Flask(__name__)

# Configuración de la base de datos
DB_HOST = '10.10.10.6'
DB_NAME = 'suricata_alerts'
DB_USER = 'suricata'
DB_PASSWORD = 'murdok44'

# Función para conectar a la base de datos
def get_db_connection():
    conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD)
    return conn

@app.route('/suricata/alerts', methods=['POST', 'GET'])
def handle_alerts():
    if request.method == 'POST':
        data = request.get_json()
        if 'alerts' in data:
            alerts = data['alerts']
            conn = get_db_connection()
            cur = conn.cursor()
            for alert in alerts:
                cur.execute(
                    "INSERT INTO alerts (timestamp, src_ip, dst_ip, message) VALUES (%s, %s, %s, %s)",
                    (alert.get('timestamp'), alert.get('src_ip'), alert.get('dst_ip'), alert.get('message'))
                )
            conn.commit()
            cur.close()
            conn.close()
            return jsonify({'status': 'success'}), 200
        else:
            return jsonify({'error': 'No alerts found in data'}), 400
    elif request.method == 'GET':
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM alerts")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(rows), 200

@app.route('/suricata/drops', methods=['POST', 'GET'])
def handle_drops():
    if request.method == 'POST':
        data = request.get_json()
        if 'drops' in data:
            drops = data['drops']
            conn = get_db_connection()
            cur = conn.cursor()
            for drop in drops:
                cur.execute(
                    "INSERT INTO drops (timestamp, src_ip, dst_ip, reason) VALUES (%s, %s, %s, %s)",
                    (drop.get('timestamp'), drop.get('src_ip'), drop.get('dst_ip'), drop.get('reason'))
                )
            conn.commit()
            cur.close()
            conn.close()
            return jsonify({'status': 'success'}), 200
        else:
            return jsonify({'error': 'No drops found in data'}), 400
    elif request.method == 'GET':
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM drops")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(rows), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)