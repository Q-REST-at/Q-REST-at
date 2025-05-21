#!/bin/bash
ml purge

datasets=("AMINA" "MOZILLA")
sample_sizes=(5 10 15 25 50 75 100)

ITER_PER_SESSION=10

echo "RQ3 Pipeline Started."

mkdir -p "./logs"

for dataset in "${datasets[@]}"; do
    for sample_size in "${sample_sizes[@]}"; do

        echo "dataset: $dataset, sample: $sample_size"

        session="RQ3_${dataset}_${sample_size}"
        new_dataset="RQ3:${dataset}:${sample_size}"
        REST_AT_FLAGS="$session $model $new_dataset gptq.sif GPTQ"

        sbatch -o logs/$sesson.log ./scripts/job.bash $REST_AT_FLAGS $ITER_PER_SESSION
        sleep 30
    done
done

echo "Done!"
