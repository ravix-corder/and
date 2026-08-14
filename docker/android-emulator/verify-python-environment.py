#!/usr/bin/env python3
"""Read-only verification for the Android automation Python environment."""

from __future__ import annotations

import importlib.metadata
import json
import os

import mss
import openai
import pyautogui
import transformers
from huggingface_hub import HfApi


def package_version(name: str) -> str:
    return importlib.metadata.version(name)


def main() -> None:
    if not os.environ.get("DISPLAY"):
        raise RuntimeError("DISPLAY must be set for mss and pyautogui")

    # Read display properties only: no mouse clicks, key input, or API request is sent.
    screen_size = pyautogui.size()
    mouse_position = pyautogui.position()
    with mss.mss() as screenshotter:
        monitor = screenshotter.monitors[1]
        image = screenshotter.grab(monitor)

    result = {
        "display": os.environ["DISPLAY"],
        "screen": {"width": screen_size.width, "height": screen_size.height},
        "pointer": {"x": mouse_position.x, "y": mouse_position.y},
        "capture": {"width": image.width, "height": image.height},
        "packages": {
            "mss": package_version("mss"),
            "pyautogui": package_version("PyAutoGUI"),
            "openai": openai.__version__,
            "huggingface_hub": package_version("huggingface_hub"),
            "transformers": transformers.__version__,
        },
        "huggingface_client": HfApi.__name__,
        "api_network_calls": False,
        "input_actions": False,
    }
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
