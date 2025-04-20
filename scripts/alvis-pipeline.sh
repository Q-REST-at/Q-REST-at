#!/bin/bash
#SBATCH -A NAISS2025-22-104 -p alvis
#SBATCH --gpus-per-node=A100:2
#SBATCH -t 0-01:00:00
#SBATCH -o alvis-pipeline.log

ml purge # good practice; removes all activated modules

dataset=("BTHS" "ENCO" "SNAKE")
models=("mis")
quant=("NONE" "AWQ")

ITER_PER_SESSION=10

_log_err() {
    local msg=$1

    local red="\033[0;31m"
    local reset="\033[0m"

    echo -e "${red}[ERROR]${reset} $msg"
}

echo "Alvis Pipeline Started."

# Ensure logs and profiles folders exist
mkdir -p "./logs" "./profiles"

for ds in "${dataset[@]}"; do
  for m in "${models[@]}"; do
      for q in "${quant[@]}"; do
		echo -e "\n******* Session config *******\nModel:    $m\nQuant:    $q\nDataset:  $ds"
		echo -e "*****************************\n"

		m_upper="${m^^}"
		session="${m_upper}_${q}_${ds}"

		if [[ "$q" == "AWQ" ]]; then
    		container="awq.sif"
		else
    		container="container.sif"
		fi
		datetime="$(date '+%Y-%m-%d_%H-%M')"

		if [ ! -f "$container" ]; then
			echo "Container $container does not exist. Skipping.."
			continue
		fi

		REST_AT_FLAGS="$session $m $ds"

		bash ./scripts/job-prof.bash $REST_AT_FLAGS $container $session $q $ITER_PER_SESSION
     done
  done
done

echo "Done!"

