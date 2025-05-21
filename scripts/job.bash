#!/bin/bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A100:1
#SBATCH -t 0-02:00:00

ml purge # good practice

PROJ_PATH="/mimer/NOBACKUP/groups/naiss2025-22-104/REST/REST-at"

SESSION_NAME=$1; MODEL=$2; DATA=$3
CONTAINER_NAME=$4
QUANT=$5
ITER_PER_SESSION=$6

if [[ -z "$ITER_PER_SESSION" ]]; then ITER_PER_SESSION=1; fi

date="$(date '+%Y-%m-%d')"
time="$(date '+%H:%M:%S')"
datetime="$date/$time"

LOG_DIR="./out/${SESSION_NAME}/${datetime}"

for iter in $(seq 1 $ITER_PER_SESSION); do
    iter_padded=$(printf "%02d" $iter)
    LOG_DIR_ITER="${LOG_DIR}/${iter_padded}"

    PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
        python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME \
                                --quant $QUANT --logDir $LOG_DIR_ITER --subset $iter
done
