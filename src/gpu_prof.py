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

    with open(logfile, 'r+') as file:
        data = json.load(file)
        data.update(res)
        file.seek(0)
        json.dump(data, file, indent=4)
        file.truncate()
