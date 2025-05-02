#!/bin/bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A100:1
#SBATCH -t 0-02:00:00
#SBATCH -o alvis-pipeline.log

: '
            _   __  _ __ __  ___   ___  __ ___  ___  __   __ _  __ ___
          .' \ / / /// // /,' _/  / o |/ // o |/ _/ / /  / // |/ // _/
         / o // /_| V // /_\ `.  / _,'/ // _,'/ _/ / /_ / // || // _/ 
        /_n_//___/|_,'/_//___,' /_/  /_//_/  /___//___//_//_/|_//___/ 
 '

ml purge

# Define entry vectors. These should correlate to the expected format of the
# REST-at tool.
dataset=("BTHS" "ENCO" "SNAKE")
models=("mis")
# models=("mis" "mixtral")
quant=("NONE" "AWQ")

ITER_PER_SESSION=10

_log_err() {
    local msg=$1

    local red="\033[0;31m"
    local reset="\033[0m"

    echo -e "${red}[ERROR]${reset} $msg"
}

echo "Alvis Pipeline Started."

mkdir -p "./logs" "./profiles"

for dataset in "${dataset[@]}"; do
    for model in "${models[@]}"; do
        for quant in "${quant[@]}"; do

            echo ""
            echo "******* Session config *******"
            echo "Model:    $model"
            echo "Quant:    $quant"
            echo "Dataset:  $dataset"
            echo "******************************"
            echo ""

            session="${model^^}_${quant}_${dataset}"
            
            # TODO: add support for more containers
            if [[ "$quant" == "AWQ" ]]; then
                container="awq.sif"
            else
                container="container.sif" # default
            fi

            if [ ! -f "$container" ]; then
                _log_err "Container $container does not exist. Skipping.."
                continue
            fi

            REST_AT_FLAGS="$session $model $dataset"

            bash ./scripts/job-prof.bash $REST_AT_FLAGS $container $quant $ITER_PER_SESSION
        done
    done
done

echo "Done!"
