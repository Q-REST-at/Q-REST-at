# TODO: finish the documentation

import json
from sys import argv

from .core.gpu_profiler import GPUProfiler, ProfileResponse

if __name__ == '__main__':
    if (len(argv)) < 3:
        exit(1)

    profile = argv[1]
    logfile = argv[2]

    gpu: GPUProfiler = GPUProfiler(profile)
    res: ProfileResponse = gpu.compute() 

    if res is None: exit(1)

    with open(logfile, 'r+') as file:
        ctx = json.load(file)
        ctx['data'].update(res)

        file.seek(0)
        json.dump(ctx, file, indent=4)
        file.truncate()
