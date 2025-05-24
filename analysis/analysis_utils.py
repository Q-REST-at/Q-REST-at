"""
experiment_utils.py

This module contains utility functions for loading and processing experiment data.
Functions included:
- load_experiment_data: Loads experiment data from a `res/` directory.
- load_treatment_data: Extracts treatment data from specific session directories.
- save_dataframe_to_csv: Saves a pandas DataFrame to a CSV file.
"""

import os
import json
import pandas as pd


# Utility functions: loading data

def load_treatment_data(directory: str) -> tuple[dict[str, pd.DataFrame], dict[str, pd.DataFrame]]:
    """
    Extracts experiment data from a particular directory filepath given as argument.

    Constructs dataframes holding statistical summary and individual measurements, 
    adds them to the corresponding `dict` using `<SESSION_NAME>` as the key.

    Args:
        directory (str): Directory path containing the experiment data files.

    Returns:
        tuple: A tuple containing two dictionaries:
            - summary_dataframes (dict): Statistical summary dataframes for each session.
            - detailed_dataframes (dict): Detailed dataframes with individual measurements
              for each session.

    ---

    **Notes**:
        - Omits "prevalence", "population", and "frequency_table" fields from the \<session_name>.json \
            file and extracts only the statistical metrics.
        - This function can identify and handle multiple session files in the same directory.
    """

    # Dictionaries to store dataframes 
    # (this function supports loading multiple treatment data files from same dir)
    summary_dataframes: dict[str, pd.DataFrame] = {}  # Statistical summary (<session_name>.json)
    detailed_dataframes: dict[str, pd.DataFrame] = {} # All individual data points (all_data_<session_name>.json)
    raw_metric_data = {}
    
    # Get all files in the given directory
    files = os.listdir(directory)

    # Find all session names based on filenames
    sessions = set()
    for file in files:
        # Find the files with only the "session" name
        if file.endswith(".json") and not file.startswith("all_data_"):
            session = file.replace(".json", "")
            # If the corresponding "all_data" file exists, add the session key
            if f"all_data_{session}.json" in files:
                sessions.add(session)

    # Load data for each session
    for session in sessions:
        # Concatenate file paths based on the session keys
        summary_path = os.path.join(directory, f"{session}.json")
        detail_path = os.path.join(directory, f"all_data_{session}.json")

        # Load summary statistics -> "<session_name>.json"
        with open(summary_path, "r") as f:
            summary_json = json.load(f)

        # Convert summary metrics to a dataframe
        # Note: this currently excludes "prevalence" and the "frequency_table"
        metric_rows = []
        raw_metric_data[session] = {}

        for _, value in summary_json.items():
            # Only process dictionaries with a "name" field (i.e., metrics)
            if isinstance(value, dict) and "name" in value: 
                metric_rows.append({
                    # Adds metric key with the corresponding metric name as value,
                    # otherwise the resulting df has a "name" column instead of "metric"
                    "metric": value["name"], 
                    # Exclude unnecessary fields and flatten the dictionary
                    **{k: v for k, v in value.items() if k != "name" and k != "population"}
                })
                raw_metric_data[session][value["name"]] = value

        
        # Add the session dataframe to dictionary containing all sessions,
        # using the session name as key
        summary_df = pd.DataFrame(metric_rows)
        summary_dataframes[session] = summary_df

        # Load detailed individual measurements -> "all_data<session_name>.json"
        with open(detail_path, "r") as f:
            detail_json = json.load(f)

        # Add the detailed session data dataframe to the dictionary containing all sessions,
        # using the session name as key
        detail_df = pd.DataFrame(detail_json)
        detailed_dataframes[session] = detail_df
        detailed_dataframes[session] = detail_df
    return summary_dataframes, detailed_dataframes, raw_metric_data



def load_experiment_data(base_dir: str, iteration_structure: bool = True) -> \
        tuple[dict[str, pd.DataFrame], dict[str, pd.DataFrame]]:
    """
    Loads all the experiment data for each treatment/session inside of the given directory.

    Args:
        base_dir (str): Relative filepath to the base data directory, e.g., `../res`.
        iteration_structure (bool, optional): Flag signifying whether the directory structure 
            uses the "iterations" format. Defaults to True.

    Returns:
        tuple: A tuple containing two dictionaries:
            - stat_sum_dfs (dict): Statistical summary dataframes per treatment.
            - all_data_dfs (dict): All data points dataframes per treatment.
    """

    # Dictionaries to store dataframes per treatment 
    stat_sum_dfs: dict[str, pd.DataFrame] = {} # statistical summary dataframes
    all_data_dfs: dict[str, pd.DataFrame] = {} # all individual data points dataframes
    raw_metric_data: dict[str, pd.DataFrame] = {}
    # Traverse all the sub-directories
    for day in os.listdir(f"{base_dir}"):
        for timestamp in os.listdir(f"{base_dir}/{day}"):

            # If the experiment was run in iterations, 
            # there is an additional level of sub-directories to loop over
            if iteration_structure:
                for session in os.listdir(f"{base_dir}/{day}/{timestamp}"):

                    # Skip current iteration if we encountered a file
                    if not os.path.isdir(f"{base_dir}/{day}/{timestamp}/{session}"): continue

                    # Construct the path to the current directory and load the data
                    files_path = f"{base_dir}/{day}/{timestamp}/{session}"
                    temp_sum_df, temp_all_df, temp_raw_metrics = load_treatment_data(files_path)
                    
                    # Append the new data to the dictionaries
                    stat_sum_dfs |= temp_sum_df
                    all_data_dfs |= temp_all_df
                    raw_metric_data |= temp_raw_metrics  # new!
            
            else:
                # Skip current iteration if we encountered a file
                if not os.path.isdir(f"{base_dir}/{day}/{timestamp}"): continue

                # Construct the path to the current directory and load the data
                files_path = f"{base_dir}/{day}/{timestamp}"
                temp_sum_df, temp_all_df = load_treatment_data(files_path)

                # Append the new data to the dictionaries
                stat_sum_dfs |= temp_sum_df
                all_data_dfs |= temp_all_df
    
    return stat_sum_dfs, all_data_dfs, raw_metric_data


# Utility functions: storing data

def save_dataframe_to_csv(df: pd.DataFrame, dest_path: str = ".", filename: str = "output", overwrite: bool = False):
    """
    Save a pandas DataFrame to a CSV file.

    Args:
        df (pd.DataFrame): The DataFrame to be saved.
        dest_path (str, optional): Destination directory path. Defaults to current directory.
        filename (str, optional): Name of the output file (without extension). Defaults to `"output"`.
        overwrite (bool, optional): If True, overwrite the file if it already exists. Defaults to False.

    Raises:
        FileExistsError: If the file already exists and `overwrite` is False.
    """

    file_path = os.path.join(dest_path, f"{filename}.csv")

    if os.path.exists(file_path) and not overwrite:
        raise FileExistsError(f"[{filename}.csv] already exists in the specified path: [{dest_path}]")

    os.makedirs(dest_path, exist_ok=True)

    df.to_csv(file_path, index=False)
