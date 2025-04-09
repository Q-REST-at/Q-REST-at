#!/usr/bin/env bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A40:1
#SBATCH -t 0-01:00:00

ml purge # good practice

file="./logs/nvidia/job-new.log"
rm $file
PROBE_INTERVAL_MS=1000

__monitor() {
    echo $QUERY # CSV header
    QUERY="timestamp,gpu_uuid,utilization.gpu,utilization.memory,memory.used,temperature.gpu"
    nvidia-smi --query-gpu=$QUERY --format=csv,noheader --loop-ms=$PROBE_INTERVAL_MS >> $file
}

__monitor &
MONITOR_PID=$!

PROJ_PATH="/mimer/NOBACKUP/groups/naiss2025-22-104/REST/REST-at"

SESSION_NAME=$1
MODEL=$2
DATA=$3
CONTAINER_NAME=$4

PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$1 \
    python -m src.send_data --model mixtral22 --data bths --sessionName bths

# Clean up
kill $MONITOR_PID 2>/dev/null
wait $MONITOR_PID 2>/dev/null
