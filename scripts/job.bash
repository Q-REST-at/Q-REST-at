#!/usr/bin/env bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A100:2
#SBATCH -t 0-01:00:00

ml purge # good practice

# === ARGUMENTS ===
SESSION_NAME=$1
MODEL=$2
DATA=$3
CONTAINER_NAME=$4

# === MONITOR FUNCTION ===
__monitor() {
    while true; do
        echo "[MONITOR] $(date): Script is running..."
        sleep 1 # interval to sleep
    done
}

__monitor & MONITOR_PID=$!

PYTHONPATH=$PROJ_PATH apptainer exec "$PROJ_PATH/$CONTAINER_NAME" \
    python -m src.send_data --sessionName "$SESSION_NAME" --model "$MODEL" --data "$DATA"

# === CLEAN UP MONITOR ===
kill $MONITOR_PID 2>/dev/null
wait $MONITOR_PID 2>/dev/null

echo "[MONITOR] $(date): Main process finished. Monitor stopped."
