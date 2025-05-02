#!/usr/bin/env bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A40:1
#SBATCH -t 0-01:00:00

ml purge # good practice

PROJ_PATH="/mimer/NOBACKUP/groups/naiss2025-22-104/REST/REST-at"

SESSION_NAME=$1
MODEL=$2
DATA=$3
CONTAINER_NAME=$4

PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/$CONTAINER_NAME \
    python -m src.send_data --model $MODEL --data $DATA --sessionName $SESSION_NAME
