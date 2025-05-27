import re
import pandas as pd

file_path = "./analysis/summary_table.csv"

df = pd.read_csv(file_path)

numeric_cols = list(df.columns)
numeric_cols.remove('Treatment')

def format_latex_mathmode(t: tuple[float, float]) -> str:
    return f"${t[0]}\\pm{t[1]}$"

def parse_uncertainty(value: str) -> tuple[float, float]:
    # Allow for both "±" and "+/-" symbols
    pattern = r"^\s*([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*(?:±|\+/-)\s*([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*$"
    
    match = re.match(pattern, value)
    if not match:
        raise ValueError(f"Invalid uncertainty format: '{value}'")
    
    mean = float(match.group(1))
    uncertainty = float(match.group(2))
    return mean, uncertainty


# for n_col in numeric_cols:
#     df[n_col] = df[n_col].apply(format_latex_mathmode)


highlight_colors = [
    "fff2ac",  # pale yellow
    "c2f0c2",  # light green
    "add8e6",  # light blue
    "f7c6c7",  # light pink
    "e0bbff",  # light purple
    "ffd9b3",  # light orange
]

df['dataset'] = df['Treatment'].apply(lambda x: x.split("_")[2])
df['Treatment'] = df['Treatment'].apply(lambda x: x.split("_")[1])
group_by_dataset = df.groupby('dataset')

tables: list[str] = []

for dataset, df in group_by_dataset:
    del df['dataset']

    for i, n_col in enumerate(numeric_cols):
        df[f'{n_col}_tuple'] = df[n_col].apply(parse_uncertainty)
        best = max(df[f'{n_col}_tuple'], key=lambda x : (x[0], -x[1]))

        df[f'{n_col}_str'] = df[f'{n_col}_tuple'].apply(
            lambda x: f"\\colorbox{{color{i+1}}}{{{format_latex_mathmode(x)}}}" if x == best else format_latex_mathmode(x)
        )

    df = df[[col for col in df.columns if col.endswith('_str')]]
    df.columns = [col.replace("_str", "") for col in df.columns]

    latex_table = df.to_latex(
        index=False,
        escape=False,
        column_format='l'*len(df.columns),
        caption=str(dataset)
    )

    table = (
        "\\begin{subtable}{\\textwidth}\n"
        "\\centering\n"
        + latex_table +
        "\\end{subtable}\n"
    )
    tables.append(table)

colors = (
    f"\\definecolor{{color{i+1}}}{{HTML}}{{{color}}}\n" for i, color in enumerate(highlight_colors)
)

final_table: str = (
    "".join(colors) + "\n" +
    "\\begin{table*}[ht]\n"
    "\\centering\n"
    + "\n".join(table.replace("\\begin{table}", "").replace("\\end{table}", "") for table in tables) +
    "\\caption{Key metrics summary table}\n"
    "\\label{tab:metric_summary}\n"
    "\\end{table*}\n"
)

with open(f"tables/summary_table.tex", 'w') as f:
   f.write(final_table)
