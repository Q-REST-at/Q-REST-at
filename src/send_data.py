"""
Script for running REST-at using a local model specified through the command line.
System prompt and user prompt are also specified through the command line.
The dataset and session name to use are also specified through the command line.

# Environment variables required for the application to work:
```python
# Paths to local models
MODEL_PATH_{MODEL_NAME}_{QUANT_TYPE}    # Path to quantized model, e.g., MODEL_PATH_MIS_AWQ
MODEL_PATH_{MODEL_NAME}                 # Path to the original model, e.g., MODEL_PATH_MIS

# Maximum token limits for different models
TOKEN_LIMIT_{MODEL_NAME}: int           # Max tokens for the model e.g., TOKEN_LIMIT_MIS

# Data paths for REST spec files
{DATASET}_REQ_PATH: Path                # Path to the dataset request file, e.g., ENCO_REQ_PATH
{DATASET}_TEST_PATH: Path               # Path to the dataset test file, e.g., ENCO_TEST_PATH
{DATASET}_MAP_PATH: Path                # Path to the dataset map file, e.g., ENCO_MAP_PATH
```

Copyright:
----------
(c) 2024 Anonymous software testing consultancy company

License:
--------
MIT (see LICENSE for more information)
"""
import datetime
import os
import json
import argparse
import traceback

from dotenv import load_dotenv

from .core.rest import RESTSpecification, Response


def main() -> None:
    parser = argparse.ArgumentParser(description="Process file information.")
    parser.add_argument("--sessionName", "-s", dest="session", type=str, default="MistralAI-REST-at-BTHS-eval", help="Customize the session name")
    parser.add_argument("--model", "-m", dest="model", type=str, default="mistral", help="Set the model to use")
    parser.add_argument("--data", "-d", dest="data", type=str, default="ENCO", help="Customize the dataset, not case sensitive. Use MIX for the mix dataset, Mix-small for mix-small-dataset, BTHS for the BTHS dataset, and ENCO for the ENCO dataset. Default is ENCO.")
    parser.add_argument("--quant", "-q", dest="quant", type=str, default="AWQ", help="Set the quantization method to use")
    parser.add_argument("--logDir", "-l", dest="log_dir", type=str, default=None, help="Set the output directory")
    parser.add_argument("--system", "-S", dest="system", type=str, default=None, help="Path to the system prompt used. Falls back on a default if not provided.")
    parser.add_argument("--prompt", "-p", dest="prompt", type=str, default=None, help="Path to the prompt used. Include `{req}` in place of the requirement and `{tests}` in place of the tests. Falls back on a default if not provided.")

    args = parser.parse_args()

    load_dotenv()
    session_name = args.session
    model: str = args.model.lower()
    data: str = args.data.lower()
    quant: str = args.quant.lower()
    log_dir: str = args.log_dir
    system_prompt_path: str = args.system
    prompt_path: str = args.prompt

    # *************************************************************************
    # Dynamically construct model path and retrieve a corresponding env variable
    # *************************************************************************

    # Define valid models and quant types
    valid_models = ["mis", "mixtral", "mixtral22", "llama"]
    valid_quant = ["none", "awq", "gptq", "gguf"]

    if model in valid_models and quant in valid_quant:

        quantized_model_path = f"MODEL_PATH_{model.upper()}_{quant.upper()}" # Ex. MODEL_PATH_MIS_AWQ
        default_model_path = f"MODEL_PATH_{model.upper()}" # Ex. MODEL_PATH_MIS - original model
        model_token_limit = f"TOKEN_LIMIT_{model.upper()}"
        default_token_limit = "TOKEN_LIMIT"

        if quant.lower() == "none":
            model_path = os.getenv(default_model_path)
            token = int(os.getenv(default_token_limit))
        else:
            model_path = os.getenv(quantized_model_path, os.getenv(default_model_path))
            token = int(os.getenv(model_token_limit, os.getenv(default_token_limit)))
            
    else:
        model_path = os.getenv("MODEL_PATH_MIS")
        token = int(os.getenv("TOKEN_LIMIT_MIS"))

    print(f"Info - Using {model.capitalize()} model. Session name: {session_name}")

    req_path: str
    test_path: str
    mapping_path: str

    # *************************************************************************
    # Dynamically construct data path and retrieve a corresponding env variable
    # *************************************************************************

    valid_data = ["mix", "mix-small", "bths", "enco", "snake"]

    if data in valid_data:
        d_up = data.upper()
        print(f"Info - Using {d_up} data")
        req_path = os.getenv(f"{d_up}_REQ_PATH") # Ex. BTHS_REQ_PATH
        test_path = os.getenv(f"{d_up}_TEST_PATH") #Ex. BTHS_TEST_PATH
        mapping_path = os.getenv(f"{d_up}_MAP_PATH") #Ex. BTHS_MAP_PATH
    else:
        print("Info - Using ENCO data")
        req_path = os.getenv("ENCO_REQ_PATH")
        test_path = os.getenv("ENCO_TEST_PATH")
        mapping_path = os.getenv("ENCO_MAP_PATH")
  
    debug_mode: bool = False
    try:
        mode = int(os.getenv("DEBUG_MODE"))
        debug_mode = mode == 1 # 1 for True/ON
    except Exception:
        pass

    print(f"Model path: {model_path}")
    print(f"Token limit: {token}")
    print(f"Requirements path: {req_path}")
    print(f"Tests path: {test_path}")
    print(f"Debug mode: {'ON' if debug_mode else 'OFF'}")

    # Load the REST specifications
    specs: RESTSpecification = RESTSpecification.load_specs(
        req_path,
        test_path
    )

    # Set system prompt if one was passed
    if system_prompt_path:
        try:
            system_prompt: str
            # Read the prompt from the specified file
            with open(system_prompt_path) as f:
                system_prompt = f.read()

            # Set the system prompt
            specs.system_prompt = system_prompt
            print(f"Using the following system prompt:\n{system_prompt}")
        except Exception:
            print(f"Error loading system prompt from {system_prompt_path}")
            traceback.print_exc()
    # Otherwise, use the default system prompt
    else:
        try:
            system_prompt: str
            # Read the prompt from the default file
            with open("./prompts/system/list/default.txt") as f:
                system_prompt = f.read()

            # Set the system prompt
            specs.system_prompt = system_prompt
            print(f"Using the default system prompt:\n{system_prompt}")
        except Exception:
            print(f"Error loading default system prompt")
            traceback.print_exc()

    # Set prompt if one was passed
    if prompt_path:
        try:
            prompt: str
            # Read the prompt from the specified file
            with open(prompt_path) as f:
                prompt = f.read()

            # Set the prompt
            specs.prompt = prompt
            print(f"Using the following prompt:\n{prompt}")
        except Exception:
            print(f"Error loading prompt")
            traceback.print_exc()
    # Otherwise, use the default prompt
    else:
        try:
            prompt: str
            # Read the prompt from the default file
            with open("./prompts/user/list/default.txt") as f:
                prompt = f.read()

            # Set the prompt
            specs.prompt = prompt
            print(f"Using the default prompt:\n{prompt}")
        except Exception:
            print(f"Error loading default prompt")
            traceback.print_exc()

    # Send data to local model
    res, t = specs.to_local(model_path, token, debug_mode)

    payload: dict[str, dict] = { # = res.json
        "meta": {
            "req_path": req_path,
            "test_path": test_path,
            "mapping_path": mapping_path
        },
        "data": {
            **res.as_dict,           # efficacy data
            **{"time-to-analyze": t} # efficiency data
        }
    }

    # Log response to a file
    now: datetime.datetime = datetime.datetime.now()
    date: str = str(now.date())
    time: str = str(now.time())

    if not log_dir:
        log_dir = f"./out/{session_name}/{date}/{time}"

    os.makedirs(log_dir, exist_ok=True)

    with open(f"{log_dir}/res.json", "w+") as out:
        json.dump(payload, out, indent=2)


if __name__ == "__main__":
    main()
