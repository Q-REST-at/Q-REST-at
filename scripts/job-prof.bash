#!/usr/bin/env bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A100:2
#SBATCH -t 0-01:00:00

ml purge # good practice

SESSION_NAME=$1; MODEL=$2; DATA=$3
CONTAINER_NAME=$4
QUANT=$5
ITER_PER_SESSION=$6

PROJ_PATH="/mimer/NOBACKUP/groups/naiss2025-22-104/REST/REST-at"
QUERY="timestamp,gpu_uuid,utilization.gpu,utilization.memory,memory.used,temperature.gpu"

PROBE_INTERVAL_MS=1000

monitor() {
    # Print raw 'CSV' header
    echo $QUERY > $1

    # Query in CSV format in a loop and continually append to filepath
    nvidia-smi --query-gpu=$QUERY \
               --format=csv,noheader \
               --loop-ms=$PROBE_INTERVAL_MS \
               >> $1
}

if [[ -z "$ITER_PER_SESSION" ]]; then ITER_PER_SESSION=0; fi

if [[ "$ITER_PER_SESSION" -gt 0 ]]; then

	datetime="$(date '+%Y-%m-%d_%H-%M')"

	for iter in $(seq 1 $ITER_PER_SESSION); do
        iter_padded=$(printf "%02d" $iter)
        
		LOG_DIR="./out/${SESSION_NAME}/${datetime}/iter_${iter_padded}"
        PROFILE_DIR="./profiles/${SESSION_NAME}"
        
        # Ensure dirs exist
		mkdir -p "$LOG_DIR"
        mkdir -p "$PROFILE_DIR"

		echo "Running: ds=$DATA, model=$MODEL, iter=$iter"
        
        # Attach monitor
        monitor "$PROFILE_DIR/${iter_padded}.csv" &
        MONITOR_PID=$!

		PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
		    python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME \
                                    --quant $QUANT --logDir $LOG_DIR
            
        # Detach monitor
        kill $MONITOR_PID 2>/dev/null
        wait $MONITOR_PID 2>/dev/null

	done
else
    PROFILE_DIR="./profiles/${SESSION_NAME}.csv"

	# Spawn process in background
	monitor "$PROFILE_DIR" & MONITOR_PID=$!

	PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
        python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME

    # Detach monitor
    kill $MONITOR_PID 2>/dev/null
    wait $MONITOR_PID 2>/dev/null
fi

echo "Done!"
