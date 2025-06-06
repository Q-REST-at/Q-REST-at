# REST-at

Requirement Engineering and Software Testing Alignment Tool

## Statistical Analysis

The scripts and files used in our evaluation are in the `analysis/` folder.

### Misc

There's two separate branches:
[`data-archive`](https://github.com/SEM25-BSc/REST-at-upstream/tree/data-archive)
and [`stable`](https://github.com/SEM25-BSc/REST-at-upstream/tree/stable). The
former contains all _archived_ job runs and produced artifacts, and the latter
contains **Alvis** env. definitions.

> TBD: these may be eventually deleted; used as a handy reference. \=)

---

_(Written by Nicole \& Bao; used as a reference)_

## Models Used

The models used are stated in this section and will include the exact snapshot for the open-weight models.

- **GPT-3.5** - gpt-3.5-turbo-0125
- **GPT-4** - gpt-4-turbo-2024-04-09
- **Mistral 7B Instruct-v0.2** - [cf47bb3e18fe41a5351bc36eef76e9c900847c89](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.2/tree/cf47bb3e18fe41a5351bc36eef76e9c900847c89)
- **Mixtral 8x7B Instruct-v0.1** - [e2d44c05b53516ba61d625448a10c095aa104725](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1/tree/e2d44c05b53516ba61d625448a10c095aa104725)
- **Llama 3 70B** - [e8cf5276ae3e97cfde8a058e64a636f2cde47820](https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct/tree/e8cf5276ae3e97cfde8a058e64a636f2cde47820)

## Performance

The average performance metrics for **REST-at** using GPT-3.5, GPT-4, Mistral 7B Instruct-v0.2, Mixtral 8x7B Instruct-v0.1, and Llama 3 70B Instruct are displayed below. The metrics of interest are: recall, precision, and F<sub>1</sub>-score.

The model-wise model-prompt pairs with the best value in a certain metric has its cell highlighted in blue.

### BTHS

![BTHS performance table](./tables/BTHS_perf_metrics.png "Performance of REST-at using 5 models and 8 prompts on the BTHS dataset")

### En. Co

![En. Co. performance table](./tables/En_Co_perf_metrics.png "Performance of REST-at using 5 models and 8 prompts on the En. Co. dataset")

## Data

For our experiments, we use four datasets **(ENCO, BTHS, MOZILLA, HW)**. They are located in the `/data` folder.

**The structure of each dataset is as follows:**

```
/data
    /<dataset_name>  (e.g., BTHS, ENCO, etc.)
        - RE.csv (Requirements)
        - ST.csv (Test Cases)
        - mapping.csv
```

**File Schema**
The structure of each file is consistent across datasets to adhere to the Rest-at tool formatting requirements:

- `RE.csv` -> `ID, Feature, Description`
- `ST.csv` -> `ID, Purpose, Test steps`
- `mapping.csv` ->`Req ID,Test ID`

**Subsets**
Each dataset comes with randomly generated subsets in subdirectories indexed as `01...10`. The sampling script was introduced in this [PR](https://github.com/SEM25-BSc/REST-at-upstream/pull/14) and can be executed on new datasets by running [`sampling.ipynb` script](https://github.com/SEM25-BSc/REST-at-upstream/blob/main/data/sampling.ipynb)

### Data Sourcing

**ENCO (AMINA)**

We obtained a raw copy of the dataset from Göteborg Energi from [@fgoneto](https://github.com/fgoneto). The `ZIP` file contains two datasets, and we used `AMINA` (the other one was most likely corrupted, because it was unclear how the requirements are *mapped* to test cases).

- Using the `src/clean-AMINA.py` script, we can (i) process the the dataset to the **desired format**, (ii) computed the **mapping** (note that we assume the files to be in `.csv` already, use a viable tool to convert it.
- Note that the `.xlsx` fileformat is known to be difficult to parse and doing it programatically can result in errors; you can use an application like `Apple Numbers`, `LibreOffice` etc. to do this for you more reliably).

> You can try also `pd.read_excel('ur.xlsx')`, but we simply did `XLSX -> CSV` conversion non-programatically.

- Afterwards, `deepl.py` is applied to translate the full (Swedish) dataset (both RE & STs). Read the comments in the script for details.
- Afterwards, we set out to ensure the translations are correct manually (thanks, [@erikflind](https://github.com/erikflind)). However, we did not manage to manually check all ~500 test cases, so we only picked 100 (see `./deprecated_datasets/AMINA-100`).

**BTHS**

Bluetooth Headset Dataset was inherited from previous work by Quinstedt and Lindgren BSc Thesis. Dataset was originally sourced from this [website](https://www.bluetooth.com/specifications/specs/headset-profile-1-2/)

**MOZILLA**

We have extended our datasets by web-scraping [MozillaQA website](https://www-archive.mozilla.org/quality/browser/front-end/testcases/). This allowed us to retrieve 326 requirements and 324 test cases. Web-scraping pipeline was introduced in this [PR](https://github.com/SEM25-BSc/REST-at-upstream/pull/33), code implementation and all technical details are fully described there.

**HW (Health Watcher)**

This dataset was sourced from Zenodo research platform. We have extracted requirements and test cases from Health Watcher Product specification. Full pdf is available [here](https://zenodo.org/records/8081523)

### Dataset Organization

We've discovered that having 100 entries per job was simply too much for the models to properly execute and we decided to lower the **sample size to 25**. Hence,

- `./data/AMINA/[01-10]` contains 10 samples of size 25.
- `./data/MOZILLA/[01-10]` contains 10 samples of size 25.

#### Deprecated Datasets

We also retain the `./deprecated_datasets/*` directory which contains:

- `/AMINA-100` - contains a fully translated and manually verified requirements set; contains a sample of 100 fully translated and manually verified tests -- from `AMINA`
- `/MOZILLA-100` - contains 10 samples of the full `MOZILLA` dataset with 100 entries each
- `/SourceTracker` - this dataset was obtained from Zenodo research repository, however we later discovered that the test phrasing is not sufficient for this research purposes. Therefore, this dataset was deprecated.

** We've included the original Göteborg Energi data in `/deprecated_datasets/GE data (AMINA-Diarie) [ORIGINAL].zip` for future reference.
** Note, the `/data` folder also contains the **SnakeGame** dataset, a toy dataset commonly used to test models on a small, simplified subset of data. It is not used for conducting real experiments.

Useful references for further data sourcing: 1. Trustworthy research repositories: - https://www.msrconf.org - https://zenodo.org/ 2. Other sources - [cucumber.io/](cucumber.io/) - [Bug reports repo](https://github.com/jiwangjie/ChatBR/tree/master/questions/question1/final_sample)

### Prompt Templates

The prompt templates (PTs) used for REST-at are available in the [`prompts`](./prompts/) folder. Below are the definitions of the different templates with placeholders.

The substrings `{req}` and `{tests}` are injection points (placeholders) for requirement data and test suite data respectively.

#### BASE (DO)

<details>
    <summary>Show</summary>

System prompt:

    You are a helpful assistant.

User prompt:

    I have this requirement:

    {req}

    Would you say that any of the test cases in the file "tests.json" are testing the requirement? If yes, answer ONLY with the test case ID(s) that are testing the requirement in the following form:

    {"requirementID": "<insert requirement id>", "tests": "<insert test id 1>, <insert test id 2>, <insert test id 3>, ..."}

    DO NOT ADD ANY TEXT BEFORE OR AFTER THE BRACKETS. If no, answer ONLY in the following form:

    {"requirementID": "<insert requirement id>", "tests": ""}

    The contents of "tests.json" are:

    {tests}

    I am going to parse your input in my Python program, therefore, ONLY ANSWER IN THE FORM I GAVE YOU.

</details>

#### PT1 (NO)

<details>
    <summary>Show</summary>

System prompt:

    You are a helpful assistant.

User prompt:

    I have this requirement:

    {req}

    Would you say that any of the test cases in the file "tests.json" are testing the requirement? If yes, answer ONLY with the test case ID(s) that are testing the requirement in the following form:

    ["<insert test id 1>", "<insert test id 2>", "<insert test id 3>", ...]

    DO NOT ADD ANY TEXT BEFORE OR AFTER THE BRACKETS. If no, answer ONLY in the following form:

    []

    The contents of "tests.json" are:

    {tests}

    I am going to parse your input in my Python program, therefore, ONLY ANSWER IN THE FORM I GAVE YOU.

</details>

#### PT2 (NO + RS)

<details>
    <summary>Show</summary>

System prompt:

    You are an expert in finding trace links between software requirements and software tests.

User prompt:

    I have this requirement:

    {req}

    Would you say that any of the test cases in the file "tests.json" are testing the requirement? If yes, answer ONLY with the test case ID(s) that are testing the requirement in the following form:

    ["<insert test id 1>", "<insert test id 2>", "<insert test id 3>", ...]

    DO NOT ADD ANY TEXT BEFORE OR AFTER THE BRACKETS. If no, answer ONLY in the following form:

    []

    The contents of "tests.json" are:

    {tests}

    I am going to parse your input in my Python program, therefore, ONLY ANSWER IN THE FORM I GAVE YOU.

</details>

#### PT3 (DO + RS)

<details>
    <summary>Show</summary>

System prompt:

    You are an expert in finding trace links between software requirements and software tests.

User prompt:

    I have this requirement:

    {req}

    Would you say that any of the test cases in the file "tests.json" are testing the requirement? If yes, answer ONLY with the test case ID(s) that are testing the requirement in the following form:

    {"requirementID": "<insert requirement id>", "tests": "<insert test id 1>, <insert test id 2>, <insert test id 3>, ..."}

    DO NOT ADD ANY TEXT BEFORE OR AFTER THE BRACKETS. If no, answer ONLY in the following form:

    {"requirementID": "<insert requirement id>", "tests": ""}

    The contents of "tests.json" are:

    {tests}

    I am going to parse your input in my Python program, therefore, ONLY ANSWER IN THE FORM I GAVE YOU.

</details>

#### PT4 (NO + RS + ReOP)

<details>
    <summary>Show</summary>

System prompt:

    Act as a mapping system, that receives a requirement and test cases
    and returns a list of the test cases that test that specific requirement.

    It IS CRUCIAL that your response MUST adhere to the exact
    JSON format outlined below. Incorrect formatting may result
    in your response being improperly processed.

    If any test cases are testing the requirement, answer
    ONLY with the test case ID(s) using this format for your
    report:
    ["<test ID 1>", "<test ID 2>", "<test ID 3>", ...]

    If no test cases are testing the requirement, use this format:
    []

User prompt:

    Your task is to identify and return the test cases that directly validate the requirement
    Here are the requirements:
    {req}
    and here are the test cases:
    {tests}

    Please preserve the formatting and overall template specified above.

</details>

#### PT5 (DO + RS + ReOP)

<details>
    <summary>Show</summary>

System prompt:

    Act as a mapping system, that receives a requirement and test cases
    and returns a list of the test cases that test that specific requirement.

    It IS CRUCIAL that your response MUST adhere to the exact
    JSON format outlined below. Incorrect formatting may result
    in your response being improperly processed.

    If any test cases are testing the requirement, answer
    ONLY with the test case ID(s) using this format for your
    report:
    {"requirementID": "<insert requirement id>", "tests": "<insert test id 1>, <insert test id 2>, <insert test id 3>, ..."}

    If no test cases are testing the requirement, use this format:
    {"requirementID": "<insert requirement id>", "tests": ""}

User prompt:

    Your task is to identify and return the test cases that directly validate the requirement
    Here are the requirements:
    {req}
    and here are the test cases:
    {tests}

    Please preserve the formatting and overall template specified above.

</details>

#### PT6 (NO + RS + PP)

<details>
    <summary>Show</summary>

System prompt:

    # Role

    Act as an API for a system that identifies trace links between software requirements and system tests.


    # Input Format

    I will give you data in the following format:

    ```
    {
    "requirement": {
        "ID": "<requirement ID>",
        "Feature": "<short feature description>",
        "Description": "<full feature description>"
    },
    "tests": [
        {
        "ID": "<test ID>",
        "Purpose": "<purpose of test>",
        "Test steps": "<steps to follow when executing test>"
        }
    ]
    }
    ```
    The "tests" field is a list of test objects.


    # Task

    Analyse the requirement and test cases and determine which test cases cover the requirement.


    # Output Format

    I will expect you to respond with a list of test IDs that cover the requirement. The following response templates are wrapped in code blocks.
    DO NOT RESPOND WITH CODE BLOCKS, DO NOT EXPLAIN YOUR SOLUTION, ONLY RESPOND WITH A LIST!


    If you find trace links, insert the test IDs in the following template:
    ```
    ["<test ID 1>", "<test ID 2>", "<test ID 3>", ...]
    ```

    If you can't find trace links, respond with the following:
    ```
    []
    ```

User prompt:

    {
      "requirement": {req},
      "tests": {tests}
    }

</details>

#### PT7 (DO + RS + PP)

<details>
    <summary>Show</summary>

System prompt:

    # Role

    Act as an API for a system that identifies trace links between software requirements and system tests.


    # Input Format

    I will give you data in the following format:

    ```
    {
    "requirement": {
        "ID": "<requirement ID>",
        "Feature": "<short feature description>",
        "Description": "<full feature description>"
    },
    "tests": [
        {
        "ID": "<test ID>",
        "Purpose": "<purpose of test>",
        "Test steps": "<steps to follow when executing test>"
        }
    ]
    }
    ```
    The "tests" field is a list of test objects.


    # Task

    Analyse the requirement and test cases and determine which test cases cover the requirement.


    # Output Format

    I will expect you to respond with a JSON string of  test IDs that cover the requirement. The following response templates are wrapped in code blocks.
    DO NOT RESPOND WITH CODE BLOCKS, DO NOT EXPLAIN YOUR SOLUTION, ONLY RESPOND WITH A JSON STRING!


    If you find trace links, insert the test IDs in the following template:
    ```
    {"requirementID": "<insert requirement id>", "tests": "<insert test id 1>, <insert test id 2>, <insert test id 3>, ..."}
    ```

    If you can't find trace links, respond with the following:
    ```
    {"requirementID": "<insert requirement id>", "tests": ""}
    ```

User prompt:

    {
      "requirement": {req},
      "tests": {tests}
    }

</details>

## Running Scripts

Scripts should be run as modules to ensure that the relative imports work. E.g.:

```bash
python -m <path.to.module> # Omit the -.py file name extension
```

## Testing Modules

Currently only some of the modules in `src/core/` are partially tested. To run the tests, run the following command from `src/`:

```bash
python -m unittest discover
```

## File Structure

The following file structures are **REQUIRED** for REST-at to work properly. All input files **MUST**
be in Comma Separated Value (`.csv`) format.

### Requirements Files

Requirements files must have the following rows (case sensitive) in whichever order:

- ID
- Feature
- Description

### Test Cases Files

Test cases files must have the following rows (case sensitive) in whichever order:

- ID
- Purpose
- Test steps

### Alignment Files

Only for development evaluations.
Alignment files must have the following rows (case sensitive) in whichever order:

- Req IDs
- Test ID
  - This column must consist of a list of Test IDs separated by commas

## Getting Started

### Prerequisites

- [Python 3.10](https://www.python.org/downloads/release/python-31014/) or later
- Hardware capable of running LLMs (large amounts of VRAM)
- A virtual Python environment (optional but recommended)

### Setting Up

Make sure that you're in the correct Python environment before you begin!

1. Clone this repository.
1. `cd` into the newly created directory.
1. Run `pip install -r requirements.txt`

### Running REST-at Scripts

Make sure that you're in the correct Python environment before you begin!

1. Create a `.env` file in the project root.
1. Add the following variables to the `.env` file:

   ```
   # Paths to local models
   MODEL_PATH_{MODEL_NAME}_{QUANT_TYPE}    # Path to quantized model, e.g., MODEL_PATH_MIS_AWQ
   MODEL_PATH_{MODEL_NAME}                 # Path to the original model, e.g., MODEL_PATH_MIS

   # Maximum token limits for different models
   TOKEN_LIMIT_{MODEL_NAME}: int           # Max tokens for the model e.g., TOKEN_LIMIT_MIS

   # Data paths for REST spec files
   {DATASET}_REQ_PATH: Path                # Path to the dataset request file, e.g., ENCO_REQ_PATH
   {DATASET}_TEST_PATH: Path               # Path to the dataset test file, e.g., ENCO_TEST_PATH
   {DATASET}_MAP_PATH: Path                # Path to the dataset map file, e.g., ENCO_MAP_PATH

   # Set Debug mode ON/OFF
   DEBUG_MODE=1                            # Debug mode enabled

   # Set redirect stdout to .log files ON/OFF
   USE_LOG=1                               # Stdout redirect enabled
   ```

1. Run one of two scripts:
   - `python -m src.send_data` - To run on a local model.
     Adjust the `session_name` variable to your desired output directory name.
   - `python -m src.send_data_gpt` - To run on OpenAI's GPT. \
     Adjust the `model` variable to your desired model.

The scripts will output files in the `out/{model}/{date}/{time}/` directory.

> **Note:** You can enable DEBUG_MODE in `.env` to see more detailed logs when running the LLMs. When enabled, the following information will be printed to the console for each model run: `Iteration nr., Raw output, Req. ID, Created links, Parsed response`. This is often helpful for tracking the progress and understanding how the model is processing each request

<details>
    <summary>Example output in DEBUG_MODE</summary>

```
Iteration nr.: 1
Raw output: []
Req. ID: 4.2
Created links: []
Parsed response {'4.2': []}
Iteration nr.: 2
Raw output: ["T-2", "T-3"]
Req. ID: 4.2.1
Created links: ['HSP/AG/IAC/BV-02-I', 'HSP/HS/IAC/BV-02-I']
Parsed response {'4.2': [], '4.2.1': ['HSP/AG/IAC/BV-02-I', 'HSP/HS/IAC/BV-02-I']}
Iteration nr.: 3
Raw output: []
Req. ID: 4.2.2
Created links: []
Parsed response {'4.2': [], '4.2.1': ['HSP/AG/IAC/BV-02-I', 'HSP/HS/IAC/BV-02-I'], '4.2.2': []}
Iteration nr.: 4
Raw output: []
Req. ID: 4.3
Created links: []
Parsed response {'4.2': [], '4.2.1': ['HSP/AG/IAC/BV-02-I', 'HSP/HS/IAC/BV-02-I'], '4.2.2': [], '4.3': []} ...
```

</details>

### Automated experiments on Alvis

You can run automated experiments using:

`scripts/alvis-pipeline.sh`

This script handles experiment setup with predefined variables: `dataset, models, quant`. Ex: `dataset=("BTHS" "ENCO" "SNAKE") models=("mis") quant=("NONE" "AWQ")`. It automatically iterates over all combinations of these variables and runs each configuration for N iterations (set within the script).

Note: `MODEL_NAME`, `QUANT_TYPE`, `DATASET` variables names set in `.env` (see [Running REST-at Scripts](#running-rest-at-scripts)) must match exactly those defined in `alvis-pipeline`, as paths are constructed dynamically

**To run:**

1. Define all necessary experiment variables in `scripts/alvis-pipeline.sh`
2. Set up your `.env` file with the required paths
3. Launch the job on Alvis:
   - `sbatch scripts/alvis-pipeline.sh`

### Evaluating REST-at From Scripts

Make sure that you're in the correct Python environment before you begin!

1. Follow the steps in [Running REST-at Scripts](#running-rest-at-scripts)
1. Add the following variables to the `.env` file:
   - `MAP_PATH` - The relative path to the alignment file.
   - `USE_LOG` - Redirects `stdout` to `.log` files when set to `1`; preserves default behaviour when set to `0` (or if variable missing).
1. Run one of three scripts:
   - `python -m src.eval` - To evaluate each REST trace link.
   - `python -m src.eval_iteration` - Similar functionality to `eval.py` as well as the ability to handle output data with an _iterative_ directory structure, i.e., one additional layer of nested sub-directories containing model output — a result of generating multiple responses per treatment using multiple input data subsets.
   - `python -m src.label_eval` - To evaluate "is tested" labels.

The script will output an `eval.log` or a `label-eval.log` in `out/{model}/{date}/{time}/` for each model, date, and time, depending on the script used. The file contains key metrics of REST-at, such as accuracy and precision.

The script will also output the following files in the `res/{date}/{time}(-label)` directory:

- `eval.log` - The verbose output of the evaluation.
- `res.log` - All the evaluation results.
- `{model}.log` for each model in `out/` - The average metrics of all runs with the model.
