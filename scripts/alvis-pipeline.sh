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

# Usage:
# $ sbatch ./alvis-ipeline.sh 
#
# Feel free to add support for --help | -h with helper msg, but not necessarily
# required. 
#
# Note: you could add flag to enable/disable profiling if needed. Then we call
# ./scripts/job.bash without the last flag.

# Define entry vectors; ensure that they are supported by REST-at!
# For the time being, let's add minimal support. We'll expand on this later.
# These correspond to the command-line args passed to REST-at (apart from
# quant).
models=()

# This would assume, e.g., containers/AWQ.sif, containers/NONE.sif
quant=("NONE" "AWQ")

dataset=() # BTHS, ENCO?

ITER_PER_SESSION=10 # let's start with this

# You can use this function to log errors. Use it like so:
# _log_err "This is an error"
#
# Yields `<RED>[ERROR]<RED> This is an error`
_log_err() {
    local msg=$1

    local red="\033[0;31m"
    local reset="\033[0m"

    echo "${red}[ERROR]${reset} $msg"
}

echo "Alvis Pipeline Started."

# Before going further...
# 0) [ ] Write to console about what models, qauntization methods, and datasets
#        this pipeline will use; it'll be saved to the log file; very useful for
#        debugging.
# 1) [ ] Ensure folders `logs` and `profiles` exist (that's where we output stuff)
# 2) [ ] Ensure that .env contains all the key-pair values. See send_data.py #71--#109.
# 3) [ ] I very much recommend echoing as much as possible; great for debugging.
# 4) [ ] Make the script as robust as possible and check for errors whenever possible.
# 5) Get creative =))
# ??

# for ds in dataset: # we can for now specify (control) which to use. This may change later (especially when using subsets)
#   for m in models:
#       for q in quant:
#           session   = `{m}-{q}-{ds}`     # something like this, feel free to decide
#           container = `./containers/{q}` # maybe like this, but then ensure that all containers are named this way 
#           
#           # Ensure that $container exists!
#
#           # Now, you should have all the ingredients to call `run.sh`
#           for iter in ITER_PER_SESSION:
#               # Something like this. The idea is that using a common $session
#               # with multiple runs, we generate (note: this is handled by src.send_data.py):
#               # .
#               # |  my-session-name
#               # |    - datetime
#               # |      - iter1 -> res.json
#               # |      - iter2 -> res.json
#               # |      - ...
#               # |  other-session-name
#               # |     - datetime
#               # |        - ...
#               # .
#               #
#               # --> All of this ultimately boils down to:
#               bash ./scripts/job-prof $session $m $d $container $session-prof_$iter
#               # ^
#               # You can also reuse ./scripts/run.sh, but disable `sbatch`
#               # there; this would create a new job for every iteration (and
#               # we'd most likely get banned from Alvis) :D!
#
# Any clean-up commands? If needed.
#
# Keep in mind that when testing this, don't add too many options. Start with
# one model, quant. method, ds!

echo "Done!"
