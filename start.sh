#!/usr/bin/env bash
# Levanta backend (4000), frontend (5173) y agente Streamlit (8501). Ctrl+C detiene todo.
ROOT="$(cd "$(dirname "$0")" && pwd)"

trap 'kill 0' INT TERM EXIT

(cd "$ROOT/backend" && npm run dev) &
(cd "$ROOT/frontend" && npm run dev) &
(cd "$ROOT/agente_crovn" && python3 -m streamlit run app.py) &

wait
