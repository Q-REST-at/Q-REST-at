#!/usr/bin/env python3

import csv
from collections import defaultdict
from typing import Final

"""
If len(test_ids) == 0: "unassigned"
If len(test_ids) == 1 and test_id used by only 1 Req ID → 1:1
If len(test_ids)  > 1 and all test_ids used only by this Req ID → 1:M
If len(req_ids)   > 1 and len(test_ids) == 1 → M:1
If len(req_ids)   > 1 and len(test_ids) > 1 → M:M
"""
MAPPING_TYPES: Final[list[str]] = ['1:1', '1:n', 'n:1', 'n:m']

datasets: Final[list[str]] = ["AMINA", "BTHS", "HealthWatcher", "Mozilla"]

ITERATIONS: int = 10

"""
BTHS simplified.
"""
test_csv_data = """
Req ID,Test ID
1,"A,B,C,D,E,F"
2,"B,C,D"
3,
4,"E,F"
5,"G,H,I"
6,J
7,"K,L"
8,"M,N,O"
"""

Mapping = dict[str, tuple[str,...]]
Classification = dict[str, int | float | tuple[int, int]]


def parse_csv_to_mapping(csv_text: str) -> Mapping:
    reader = csv.reader(csv_text.strip().splitlines())
    next(reader)

    mapping: Mapping = {}
    for req_id, test_ids in reader:
        req_id = req_id.strip()
        if not test_ids.strip():
            mapping[req_id] = tuple()
        else:
            test_id_list = [t.strip() for t in test_ids.split(',')]
            mapping[req_id] = tuple(sorted(test_id_list))

    return mapping


def classify_mappings(mapping: Mapping) -> Classification:
    req_to_test = mapping
    test_to_req = defaultdict(set)

    # Invert mapping: Test ID --> set of Req IDs
    for req_id, test_ids in req_to_test.items():
        for test_id in test_ids:
            test_to_req[test_id].add(req_id)

    # Initialize classification 'buckets'
    classifications: dict[str, set[str]] = {
        **{ k: set() for k in MAPPING_TYPES },
        "unassigned": set()
    }

    for req_id, test_ids in req_to_test.items():
        if not test_ids:
            classifications['unassigned'].add(req_id)
            continue

        is_test_ids_shared = any(len(test_to_req[t_id]) > 1 for t_id in test_ids)

        if len(test_ids) == 1:
            if len(test_to_req[test_ids[0]]) == 1:
                classifications['1:1'].add(req_id)
            else:
                classifications['n:1'].add(req_id)
        elif not is_test_ids_shared:
            classifications['1:n'].add(req_id)
        else:
            classifications['n:m'].add(req_id)

    # Count unique test IDs used per category
    test_ids_by_class: dict[str, set[str]] = {
        key: set(
            t_id for req_id in reqs for t_id in req_to_test.get(req_id, [])
        )
        for key, reqs in classifications.items() if key != 'unassigned'
    }

    # Final reporting
    results: Classification = {}
    for key in MAPPING_TYPES:
        reqs: set[str] = classifications[key]
        tests: set[str] = test_ids_by_class.get(key, set())
        results[key] = (len(reqs), len(tests))

    # Get Ps, Ns, and Prevalence (P + (P + N))
    P = sum(len(tests) for tests in req_to_test.values())
    results['positive'] = P

    req_count = len(req_to_test)
    test_count = len(
        {_id for t_ids in req_to_test.values() for _id in t_ids}
    )
    results['req_count'] = req_count
    results['test_count'] = test_count

    # All other are not mapped, hence negatives
    all_mappings = req_count * test_count
    results['negative'] = N = all_mappings - P
    
    results['prevalence'] = round((P / (P + N) if (P + N) != 0 else .0) * 100, 2)
    
    # Get the of tests cases that don't have a req mapped to
    results['unassigned'] = len(classifications['unassigned'])

    return results


def load_file(filepath: str) -> str:
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return f.read().strip()
    except Exception:
        print(Exception);
        return ""


def get_filepaths(dataset: str) -> list[str]:
    prefix: str = f"./data/{dataset}"
    if dataset == "BTHS" or dataset == "HealthWatcher":
        return [f"{prefix}/mapping.csv"] # omit samples
    else:
        return [f"{prefix}/{i:02}/mapping.csv" for i in range(1, ITERATIONS + 1)]


ORDERED_KEYS: Final[list[str]] = [
    "req_count", "test_count", "positive", "negative", "prevalence"
] + [k for k in MAPPING_TYPES] + ['unassigned']


def get_latex_trow(classification: Classification) -> str:
    return " & ".join([
        str(classification[k]) if k not in MAPPING_TYPES
                               else f"{classification[k][0]}:{classification[k][1]}"
        for k in ORDERED_KEYS
    ]) + "\\\\"


LATEX_HEADER: Final[str] = "RE & ST & P & N & Prevalence ($\\%$) & $1{:}1$ & $1{:}M$ & $M{:}1$ & $N{:}M$ & Unassigned \\\\"


def get_latex_table(dataset: str, data: list[Classification]) -> str:
    has_subsets = len(data) > 1
    return """
\\begin{table}[h]
  \\centering
  \\caption{Dataset Specification: <DATASET>}
  \\begin{tabular}{@{}l|<HEADER_LEN>@{}}
  \\toprule
  <HEADER>
  \\midrule
  <BODY>
  \\bottomrule
  \\end{tabular}
  \\label{tab:<DATASET>}
\\end{table}
""".replace("<DATASET>", dataset)\
   .replace("<HEADER>", f"{'Dataset' if not has_subsets else 'Sample'} & {LATEX_HEADER}") \
   .replace("<HEADER_LEN>", "c" * len(ORDERED_KEYS)) \
   .replace("<BODY>", f"{dataset} & {get_latex_trow(data[0])}"
            if not has_subsets
            else "\n".join(f"\t{i+1:02} & {get_latex_trow(row)}" for i, row in enumerate(data)))


if __name__ == "__main__":
    for dataset in datasets:
        filepaths = get_filepaths(dataset)
        # Load contents of all CSV files to memory
        csv_files: list[str] = [load_file(file) for file in filepaths]
    
        # Get classification results on each CSV file
        results: list[Classification] = [
            classify_mappings(parse_csv_to_mapping(csv)) for csv in csv_files
        ] 
        print(get_latex_table(dataset, results))
