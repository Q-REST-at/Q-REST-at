#!/usr/bin/env python

import pandas as pd
import matplotlib.pyplot as plt

from scipy.signal import find_peaks
from json import dumps
from sys import argv # TODO: use argvparser if needed

CONSTANT_INTERVAL: int = 1
FILE_PATH: str | None = argv[1] if len(argv) >= 2 else None

if not FILE_PATH: exit(1)

try:
    df: pd.DataFrame = pd.read_csv(FILE_PATH)
except Exception:
    print('Error loading file.'); exit(1)

# Strip trailing percentage sign
df["utilization.gpu"]    = df["utilization.gpu"].str.replace(" %", "", regex=False)
df["utilization.memory"] = df["utilization.memory"].str.replace(" %", "", regex=False)

# Strip trailing MiB unit
df["memory.used"]  = df["memory.used"].str.replace(" MiB", "", regex=False)

# Convert the cleaned columns to numeric data types
df["utilization.gpu"]    = pd.to_numeric(df["utilization.gpu"], errors="coerce")
df["utilization.memory"] = pd.to_numeric(df["utilization.memory"], errors="coerce")
df["memory.used"]        = pd.to_numeric(df["memory.used"], errors="coerce")
df["temperature.gpu"]    = pd.to_numeric(df["temperature.gpu"], errors="coerce")

df = df.sort_values("timestamp").reset_index(drop=True)

# Average deltas
df["gpu_util_rate"]    = df["utilization.gpu"].diff() / CONSTANT_INTERVAL
df["memory_util_rate"] = df["utilization.memory"].diff() / CONSTANT_INTERVAL

# Identify peaks in the GPU utilization and memory usage data.
peaks_gpu, _    = find_peaks(df["utilization.gpu"].fillna(0))
peaks_memory, _ = find_peaks(df["utilization.memory"].fillna(0))

# Compute peak (maximum) and average values
max_gpu_util = df["utilization.gpu"].max()
avg_gpu_util = df["utilization.gpu"].mean()
gpu_util_std = df["utilization.gpu"].std()

max_memory_used = df["utilization.memory"].max()
avg_memory_used = df["utilization.memory"].mean()
memory_used_std = df["utilization.memory"].std()

# Compute average rate of change (ignoring the first NaN value)
avg_gpu_util_rate    = df["gpu_util_rate"][1:].mean()
avg_memory_util_rate = df["memory_util_rate"][1:].mean()

avg_gpu_temp         = df["temperature.gpu"].mean()
max_memory_allocated = df["memory.used"].iloc[-1]


RES: dict[str, dict[str, dict[str, float] | float | int]] = {
    "GPU": {
        "utilization": {
            "avg": float(avg_gpu_util),
            "std": float(gpu_util_std),
            "max": float(max_gpu_util),
        },
        "rate-of-change": float(avg_gpu_util_rate),
        "local_peak_count": len(peaks_gpu),
        "avg_tmp": float(avg_gpu_temp),
    },
    "vRAM": {
        "utlization": {
            "avg": float(avg_memory_used),
            "std": float(memory_used_std),
            "max": float(max_memory_used),
        },
        "rate-of-change": float(avg_memory_util_rate),
        "local_peak-count": len(peaks_memory),
        "max-allocated": float(max_memory_allocated),
    },
}

RES_JSON: str = dumps(RES, indent=4)
print(RES_JSON)

if not('--graph' in argv or '-g' in argv): exit(0)

fig, axes = plt.subplots(2, 1, figsize=(14, 10), sharex=True)

axes[0].plot(df.index, df["utilization.gpu"], marker="o", label="GPU Utilization (%)", zorder=1)
axes[0].scatter(
    df.index[peaks_gpu],
    df["utilization.gpu"].iloc[peaks_gpu],
    color="red",
    s=80,
    label="Peaks",
    zorder=2
)
axes[0].set_title("GPU Utilization Over Samples")
axes[0].set_ylabel("Utilization (%)")
axes[0].legend()
axes[0].grid(True)

axes[1].plot(
    df.index, df["utilization.memory"],
    marker="o", label="GPU Memory Utilization (%)",
    color="tab:purple", zorder=1
)
axes[1].scatter(
    df.index[peaks_memory],
    df["utilization.memory"].iloc[peaks_memory],
    color="red", s=80, label="Peaks", zorder=2
)
axes[1].set_title("GPU Memory Utilization Over Samples")
axes[1].set_xlabel("Sample Index")
axes[1].set_ylabel("Utilization (%)")
axes[1].legend()
axes[1].grid(True)

plt.tight_layout()
plt.show()
