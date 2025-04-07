#!/usr/bin/env bash

profile=""                              # disabled by default
container=""                            # empty by default
logfile="job-$(date '+%Y-%m-%d_%H-%M')" # default logfile (always required)

_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --container=PATH, -c=PATH    Specify relative path to an Apptainer-based container to use."
    echo "  --profile=NAME, -p=NAME      Specify the profile name, placed to profiles/*"
    echo "  --log-file=NAME, -l=NAME     Specify the log file name, plcaed to logs/*. Default: job-(+%Y-%m-%d_%H-%M)"
    echo "  --help, -h                   Show this help message and exit"
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
        --help|-h)
	    _help; exit 0
            ;;
        *)
            echo "Unknown option: $arg"; _help; exit 1
            ;;
    esac
done

echo "Logfile name set to \`logs/$logfile\`"

if [[ -z "$container" ]]; then
    echo "Please, select an Apptainer-based container!"
    _help; exit 1
fi

if [[ -n "$profile" ]]; then
    echo "Profiling ENABLED: \`profiles/$profile\`"
    sbatch -o "logs/$logfile.log" ./scripts/job-prof.bash $container $profile
else
    echo "Profiling DISABLED."
    sbatch -o "logs/$logfile.log" ./scripts/job.bash $container
fi
