#!/usr/bin/env bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A40:1
#SBATCH -t 0-01:00:00

ml purge # good practice

SESSION_NAME=$1; MODEL=$2; DATA=$3
CONTAINER_NAME=$4
PROFILE_FILEPATH=$5

PROJ_PATH="/mimer/NOBACKUP/groups/naiss2025-22-104/REST/REST-at"
QUERY="timestamp,gpu_uuid,utilization.gpu,utilization.memory,memory.used,temperature.gpu"

PROBE_INTERVAL_MS=1000

__monitor() {
    # Print raw 'CSV' header 
    echo $QUERY > $PROFILE_FILEPATH
    
    # Query in CSV format in a loop and continually append to filepath
    nvidia-smi --query-gpu=$QUERY --format=csv,noheader \
        --loop-ms=$PROBE_INTERVAL_MS \
        >> $PROFILE_FILEPATH
}

# Spawn process in background
__monitor & MONITOR_PID=$!

PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
    python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME

# Clean up after the script is executed
kill $MONITOR_PID 2>/dev/null; wait $MONITOR_PID 2>/dev/null
