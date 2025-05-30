import pandas as pd

# Path to your ground truth CSV file
ground_truth_path = "mapping.csv"

# Load CSV
df = pd.read_csv(ground_truth_path)

# Drop rows without a Req ID
df = df.dropna(subset=["Req ID"])

# Count number of requirements (rows)
num_reqs = len(df)

# Count total number of test links (splitting multiple test IDs in a cell)
total_links = 0
for test_ids in df["Test ID"].dropna():
    test_list = [t.strip() for t in str(test_ids).split(",")]
    total_links += len(test_list)

print(f"Total number of requirements: {num_reqs}")
print(f"Total number of test links: {total_links}")
