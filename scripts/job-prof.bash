#!/usr/bin/env bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A100:2
#SBATCH -t 0-01:00:00

ml purge # good practice

PROJ_PATH="/mimer/NOBACKUP/groups/naiss2025-22-104/REST/REST-at"

PYTHONPATH=$PROJ_PATH apptainer exec $PROJ_PATH/container.sif \
    scalene --gpu --memory --outfile profiles/$1 \
    -m src.send_data --- --model mixtral22 --data bths --sessionName bths
