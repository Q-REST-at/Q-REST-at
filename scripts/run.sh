#!/usr/bin/env bash

# From REST-at (see send_data.py)
session=""
model="mistral"
data="ENCO"

# Other
profile=""                              # disabled by default
container="container.sif"               # container.sif in project's root is default
logfile="job-$(date '+%Y-%m-%d_%H-%M')" # default logfile (always required)

_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --session-name=NAME, -s=NAME   Customize the session name."
    echo "  --model=NAME, -m=NAME          Set the model to use. Default: mistral"
    echo "  --data=NAME, -d=NAME           Select dataset (MIX, Mix-small, BTHS, ENCO). Not case sensitive. Default: ENCO"
    echo "  --container=PATH, -c=PATH      Specify relative path to an Apptainer-based container to use. Defauklt: \`container.sif\`"
    echo "  --profile=NAME, -p=NAME        Specify the profile name, placed to profiles/*"
    echo "  --log-file=NAME, -l=NAME       Specify the log file name, plcaed to logs/*. Default: job-(+%Y-%m-%d_%H-%M)"
    echo "  --help, -h                     Show this help message and exit"
}

for arg in "$@"; do
    case $arg in
        --profile=*)
            profile="${arg#--profile=}"
            ;;
        -p=*)
            profile="${arg#-p=}"
            ;;
        --log-file=*)
            logfile="${arg#--log-file=}"
            ;;
        -l=*)
            logfile="${arg#-l=}"
            ;;
        --container=*)
            container="${arg#--container=}"
            ;;
        -c=*)
            container="${arg#-c=}"
            ;;
        --session-name=*)
            session="${arg#--session-name=}"
            ;;
        -s=*)
            session="${arg#-s=}"
            ;;
        --model=*)
            model="${arg#--model=}"
            ;;
        -m=*)
            model="${arg#-m=}"
            ;;
        --data=*)
            data="${arg#--data=}"
            ;;
        -d=*)
            data="${arg#-d=}"
            ;;
        --help|-h)
            _help; exit 0
            ;;
        *)
            echo "Unknown option: $arg"; _help; exit 1
            ;;
    esac
done

REST_AT_FLAGS="$session $model $data"

if [[ -n "$session" ]]; then
    echo "Session not specified. Aborting..."
    exit 1
fi

echo "Logfile name set to \`logs/$logfile\`"

if [[ -n "$profile" ]]; then
    echo "Profiling ENABLED: \`profiles/$profile\`"
    sbatch -o "logs/$logfile.log" ./scripts/job-prof.bash $REST_AT_FLAGS $container $profile
else
    echo "Profiling DISABLED."
    sbatch -o "logs/$logfile.log" ./scripts/job.bash $REST_AT_FLAGS $container
fi
