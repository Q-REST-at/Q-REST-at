"""
Core module for handling models.

Includes:
---------
`Model` - A class abstracting pretrained models, providing methods to load, retrieve, and prompt a model.\n
`Session` - A class for handling conversations with models.

Copyright:
----------
(c) 2024 Anonymous software testing consultancy company

License:
--------
MIT (see LICENSE for more information)
"""
from os import PathLike

from transformers import Conversation


class ModelLoadingException(Exception):
    """
    An exception raised if trying to create a Session using a model that's being loaded.
    """
    ...


class UnsupportedModelException(Exception):
    """
    An exception raised if trying to load a model that REST-at doesn't support.
    """
    ...


class Model:
    """
    A class abstracting pretrained models, providing functions to load, retrieve, and prompt a model.

    Methods:
    --------
    `static get -> Model | None` - Loads a given model if not already loaded and returns the model. Returns `None` if the model is being loaded.\n
    `prompt -> str` - Prompts the model and returns the response.
    """

    @staticmethod
    def get(model_name_or_path: str | PathLike, max_new_tokens: int = None) -> Model | None:
        """
        Loads a specified model if not already loaded.

        Parameters:
        -----------
        model_name_or_path: str | PathLike - The model to get. Can be either a model name from Hugging Face Hub or a path to a local model.\n
        max_new_tokens: int - The `max_new_tokens` parameter used when generating. Required when loading.

        Returns:
        --------
        `Model | None` The model that was loaded. None if the specified model is being loaded.

        Raises:
        -------
        `ValueError` when trying to load without `max_new_tokens`.
        """
        ...

    def prompt(self, history: list[dict[str, str]] | Conversation, prompt: str) -> str:
        """
        Prompts a the model and gets the response. Appends the messages to the history.

        Parameters:
        -----------
        history: list[dict[str, str]] | Conversation - The conversation history. Must adhere to model constraints.\n
        prompt: str - The user prompt to send to the model. Must contain non-whitespace characters.

        Returns:
        --------
        `str` - The response from the model.

        Raises:
        -------
        `ValueError` if `user_prompt` is empty, `None`, or consists of only whitespace characters.
        """
        ...


class Session:
    """
    Sessions retain interaction data from models, such as history and system prompts.

    Properties:
    -----------
    `system_prompt: str` - The system prompt of the session.\n
    `readonly history: list[dict[str, str]] - A copy of the message history of the session.

    Methods:
    --------
    `static create -> Session` - Creates a new prompting session.\n
    `static get -> Session | None` - Retrieves an existing prompting session if it exists, else `None`.\n
    `prompt -> str` - Prompts the model.
    """

    @staticmethod
    def create(
        name: str,
        model_name_or_path: str | PathLike,
        max_new_tokens: int,
        system_prompt: str = Model._SYSTEM_PROMPT
    ) -> Session:
        """
        Creates a prompting session using a specified model.

        Parameters:
        -----------
        name: str - The name to give the session.\n
        model_name_or_path: str | PathLike - The model to use. Can be either a model name from Hugging Face Hub or a path to a local model.\n
        max_new_tokens: int - The `max_new_tokens` parameter used when generating.\n
        system_prompt: str - (Optional) The system prompt to use when prompting.

        Returns:
        --------
        `Session` - A new session.

        Raises:
        -------
        `ModelLoadingException` if the specified model is currently being loaded.
        """
        ...

    @staticmethod
    def get(name: str) -> Session | None:
        """
        Retrieves an existing session.

        Parameters:
        -----------
        name: str - The name of the session to retrieve.

        Returns:
        --------
        `Session | None` - The requested session if it exists, else `None`.
        """
        ...

    @property
    def system_prompt(self) -> str:
        """
        The system prompt of the session.
        """
        ...
    
    @system_prompt.setter
    def system_prompt(self, system_prompt: str) -> None:
        """
        Sets the system prompt for the session.

        Parameters:
        -----------
        system_prompt: str - The system prompt to use. Pass `None` to use the default.
        """
        ...

    def prompt(self, prompt: str, ephemeral: bool = False) -> str:
        """
        Prompts a the model and gets the response.

        Parameters:
        -----------
        prompt: str - The user prompt to send to the model. Must contain non-whitespace characters.\n
        ephemeral: bool - Whether the prompt and response should be saved. Defaults to saving (`False`).

        Returns:
        --------
        `str` - The response from the model if the model is loaded, else `None`.

        Raises:
        -------
        `ValueError` if `user_prompt` is empty, `None`, or consists of only whitespace characters.
        """
        ...

    def clear(self) -> None:
        """
        Empties the conversation history.
        """
        ...

    @property
    def history(self) -> list[dict[str, str]]:
        """
        A copy of the message history of the session.
        """

    def delete(self) -> None:
        """
        Deletes the session from the session cache. The session is destoyed once all references to it are gone.
        """
        ...
