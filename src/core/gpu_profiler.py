"""
TODO: finish the documentation
"""

import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import find_peaks
from json import dumps

from os import PathLike
from typing import Final


ProfileDict = dict[str, dict[str, dict[str, float] | float | int]]
ProfileResponse = None | str | ProfileDict


class GPUProfiler:
    """
    TODO: write
    """

    __slots__ = "path", "interval", "gpu_count", "df"

    def __init__(self,
                 path      : PathLike | str | None = None,
                 interval  : int                   = 1   ,
                 gpu_count : int                   = 1   ,
                 ) -> None:
        self.path      = path
        self.interval  = interval
        self.gpu_count = gpu_count
        
        # Empty df, just columns to prevent indexing errors
        self.df: pd.DataFrame = pd.DataFrame(columns=[
            "timestamp",
            "gpu_uuid",
            "utilization.gpu",
            "utilization.memory",
            "memory.used",
            "temperature.gpu"
        ])

        self.load_to_memory()


    def load_to_memory(self) -> None:
        _df = self.read_csv()
        if _df is not None:
            self.df = _df
        else:
            print('Reading failed. Using an empty DataFrame.')


    def compute(self, jsonify = False) -> ProfileResponse:
        df = self.df

        result: ProfileDict = {
            "GPU": {
                "utilization": {
                    "avg": float(df["utilization.gpu"].mean()),
                    "std": float(df["utilization.gpu"].std()),
                    "max": float(df["utilization.gpu"].max())
                },
                "avg_temperature": float(df["temperature.gpu"].mean())
            },
            "vRAM": {
                # TODO: revisit this if the last is actually the sought after value
                "max_allocated_MiB": float(df["memory.used"].iloc[-1]),
                "utilization": {
                    "avg": float(df["utilization.memory"].mean()),
                    "std": float(df["utilization.memory"].std()),
                    "max": float(df["utilization.memory"].max())
                }
            }
        }

        if jsonify:
            return dumps(result, indent=4)
        else:
            return result


    def read_csv(self) -> pd.DataFrame | None:
        try:
            df: pd.DataFrame = pd.read_csv(self.path)
        except Exception:
            return None
        
        for col in [
            "utilization.gpu",
            "utilization.memory",
            # add more if needed
        ]:
            df[col] = df[col].astype(str).str.replace(" %", "", regex=False)


        df["memory.used"] = df["memory.used"].astype(str).\
                replace(" MiB", "", regex=False)

        # Cols to convert to numeric datatype
        cols_to_convert_numeric: Final[list[str]] = [
            "utilization.gpu",
            "utilization.memory",
            "memory.used", 
            "temperature.gpu"
        ]

        df[cols_to_convert_numeric] = df[cols_to_convert_numeric].\
                apply(pd.to_numeric, errors="coerce")

        df = df.sort_values("timestamp").reset_index(drop=True)

        # Average deltas
        df["gpu_util_rate"]    = df["utilization.gpu"].diff() / self.interval
        df["memory_util_rate"] = df["utilization.memory"].diff() / self.interval

        return df


    def get_peaks(self):
        cols: Final[list[str]] = ["utilization.gpu", "utilization.memory"]
        return tuple(
                find_peaks(self.df[col].fillna(0))[0] # get 1st param
                for col in cols
        )


    def visualize(self):
        df = self.df

        peaks_gpu, peaks_memory = self.get_peaks()

        fig, axes = plt.subplots(2, 1, figsize=(14, 10), sharex=True)
        fig.suptitle(self.path, fontsize=16)

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
