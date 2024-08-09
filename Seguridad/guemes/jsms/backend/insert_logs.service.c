[Unit]
Description=Servicio para ejecutar insert_logs
After=network.target

[Service]
ExecStart=/home/jlb/venv/bin/python3 /home/jlb/insert_logs.py
WorkingDirectory=/home/jlb/
Restart=always
User=root

[Install]
WantedBy=multi-user.target
