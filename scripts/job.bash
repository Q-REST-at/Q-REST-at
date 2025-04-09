#!/usr/bin/env bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A100:2
#SBATCH -t 0-01:00:00

# ---------- WIP ---------------- #

ml purge # good practice

datetime=$(date)

file="./logs/nvidia/job2.log"
echo "" > $file

# === MONITOR FUNCTION ===
# https://nvidia.custhelp.com/app/answers/detail/a_id/3751/~/useful-nvidia-smi-queries
monitor() {
    # Use --loop flag
    # nvidia-smi --query-gpu=timestamp,name,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv --loop 1 >> $file
    # TODO other script here to ensure that the csv entries collide to a one BIG CSV
    # GPU_usage | timestamp
    # x         | y
    # .         | .
    i=1
    while true; do
    # What I used before
    # nvidia-smi --query-compute-apps=pid,gpu_uuid,gpu_name,used_gpu_memory --format=csv,noheader
       echo "=*=" >> $file
       sleep 1 # interval to sleep
       ((i++))
    done
}

monitor &
MONITOR_PID=$!

PROJ_PATH="/mimer/NOBACKUP/groups/naiss2025-22-104/REST/REST-at"

# === ARGUMENTS ===
SESSION_NAME=$1
MODEL=$2
DATA=$3
CONTAINER_NAME=$4

PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$1 \
    python -m src.send_data --model mixtral22 --data bths --sessionName bths

# Clean up
kill $MONITOR_PID 2>/dev/null
wait $MONITOR_PID 2>/dev/null
