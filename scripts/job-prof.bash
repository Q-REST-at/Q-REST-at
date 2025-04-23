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
    local PROFILE_FILEPATH="$1"

    # Print raw 'CSV' header
    echo $QUERY > $PROFILE_FILEPATH

    # Query in CSV format in a loop and continually append to filepath
    nvidia-smi --query-gpu=$QUERY \
               --format=csv,noheader \
               --loop-ms=$PROBE_INTERVAL_MS \
               >> $PROFILE_FILEPATH
}

if [[ -z "$ITER_PER_SESSION" ]]; then ITER_PER_SESSION=0; fi

date="$(date '+%Y-%m-%d')"
time="$(date '+%H:%M:%S')"
datetime="$date/$time"

LOG_DIR="./out/${SESSION_NAME}/${datetime}"
PROFILE_DIR="./profiles/${SESSION_NAME}"

mkdir -p "profiles"
mkdir -p "$LOG_DIR"

if [[ "$ITER_PER_SESSION" -gt 0 ]]; then

    mkdir -p "$PROFILE_DIR"
	for iter in $(seq 1 $ITER_PER_SESSION); do
        iter_padded=$(printf "%02d" $iter)
        
        LOG_DIR_ITER="${LOG_DIR}/${iter_padded}"
        
		mkdir -p "$LOG_DIR_ITER"

		echo "Running: ds=$DATA, model=$MODEL, iter=$iter"

        ############################# MONITOR #################################

        # Attach monitor
        monitor "$PROFILE_DIR/${iter_padded}.csv" &
        MONITOR_PID=$!

        sleep 0.25 # ensure that monitor is loaded, give it 250ms
            
        # First call `send_data.py` to prompt the model. This produces `res.json` under LOG_DIR_ITER.
		PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
		    python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME \
                                    --quant $QUANT --logDir $LOG_DIR_ITER
        
        # Detach monitor safely
        if kill "$MONITOR_PID" 2>/dev/null; then
            wait "$MONITOR_PID" 2>/dev/null
        fi

        ############################# MONITOR #################################

        # In the background, GPU metrics have been collected. Process them and
        # update the res.json file.
		PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
            python -m src.gpu_prof "$PROFILE_DIR/$iter_padded.csv" "$LOG_DIR_ITER/res.json"
	done
else
    echo "Running: ds=$DATA, model=$MODEL"

	# Spawn process in background
	monitor "${PROFILE_DIR}.csv" &
    MONITOR_PID=$!

    sleep 0.25

	PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
        python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME \
                                --quant $QUANT --logDir $LOG_DIR

    PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
        python -m src.gpu_prof "$PROFILE_DIR.csv" "$LOG_DIR/res.json"

    # Detach monitor safely
    if kill "$MONITOR_PID" 2>/dev/null; then
        wait "$MONITOR_PID" 2>/dev/null
    fi
fi

echo "Done!"
