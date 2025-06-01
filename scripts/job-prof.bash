#!/usr/bin/env bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A100:1
#SBATCH -t 0-02:00:00

ml purge # good practice

SESSION_NAME=$1; MODEL=$2; DATA=$3
CONTAINER_NAME=$4
QUANT=$5
ITER_PER_SESSION=$6

PROJ_PATH="/mimer/NOBACKUP/groups/naiss2025-22-104/REST/REST-at"
QUERY="timestamp,gpu_uuid,utilization.gpu,utilization.memory,memory.used,temperature.gpu"

PROBE_INTERVAL_MS=250

monitor() {
    local PROFILE_FILEPATH="$1"

    # Print raw 'CSV' header
    echo $QUERY > $PROFILE_FILEPATH

    # Query in CSV format in a loop and continually append to filepath. Store
    # the PID of this subshell process.
    nvidia-smi --query-gpu=$QUERY \
               --format=csv,noheader \
               --loop-ms=$PROBE_INTERVAL_MS \
               >> $PROFILE_FILEPATH &
   local nvidia_pid=$!
   echo $nvidia_pid
}

# If the iteration is omitted, set to 0.
if [[ -z "$ITER_PER_SESSION" ]]; then ITER_PER_SESSION=0; fi

date="$(date '+%Y-%m-%d')"
time="$(date '+%H:%M:%S')"
datetime="$date/$time"

LOG_DIR="./out/${SESSION_NAME}/${datetime}"
PROFILE_DIR="./profiles/${SESSION_NAME}"

mkdir "./profiles"
mkdir -p "$LOG_DIR"

if [[ "$ITER_PER_SESSION" -gt 0 ]]; then

    mkdir -p "$PROFILE_DIR"
    for iter in $(seq 1 $ITER_PER_SESSION); do
        iter_padded=$(printf "%02d" $iter)
        
        LOG_DIR_ITER="${LOG_DIR}/${iter_padded}"
        mkdir -p "$LOG_DIR_ITER"

        echo "[i=$iter]: dataset=$DATA model=$MODEL"

        ############################# MONITOR #################################

        MONITOR_PID=$(monitor "$PROFILE_DIR/${iter_padded}.csv")
        sleep 0.1
        echo "nvidia-smi monitor started on pid=$MONITOR_PID"

        # First call `send_data.py` to prompt the model. This produces `res.json` under LOG_DIR_ITER.
        PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
            python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME \
                                    --quant $QUANT --logDir $LOG_DIR_ITER --subset $iter \
                                    --system "./prompts/system/list/PT6.txt" --prompt "./prompts/user/list/PT6.txt"
        kill "$MONITOR_PID"
        sleep 0.1

        ############################# MONITOR #################################

        # In the background, GPU metrics have been collected. Process them and
        # update the res.json file.
        PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
            python -m src.gpu_prof "$PROFILE_DIR/$iter_padded.csv" "$LOG_DIR_ITER/res.json"
    done
else
    # TODO: this could technically be part of the loop (with one iteration);
    # most of it is repeated anyway (with some extra logic).
    echo "Running: ds=$DATA, model=$MODEL"

    MONITOR_PID=$(monitor "$PROFILE_DIR.csv")
    sleep 0.1
    echo "nvidia-smi monitor started on pid=$MONITOR_PID"

    PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
        python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME \
                                --quant $QUANT --logDir $LOG_DIR \
                                --system "./prompts/system/list/PT6.txt" --prompt "./prompts/user/list/PT6.txt"

    PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
        python -m src.gpu_prof "$PROFILE_DIR.csv" "$LOG_DIR/res.json"

    kill "$MONITOR_PID"
    sleep 0.1
fi

echo "Done!"
