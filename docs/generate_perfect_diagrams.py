"""
Generate production-quality ER diagrams.

Figure 3.5a (Peter Chen) is print-sized in generate_chen_print.py.
Figure 3.5b (Crow's Foot) is print-sized in generate_crows_print.py.
"""

import importlib.util
from pathlib import Path

DOCS = Path(r"c:\Users\KHAYSON\Desktop\tippertruck\docs")


def _load(name: str, file: str):
    spec = importlib.util.spec_from_file_location(name, DOCS / file)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def generate_crows_foot():
    _load("crows_print", "generate_crows_print.py").generate_crows_erd(DOCS / "erd_crows_foot.png")


def generate_chen():
    _load("chen_print", "generate_chen_print.py").generate_chen_erd(DOCS / "erd_chen.png")


if __name__ == "__main__":
    generate_crows_foot()
    generate_chen()
    print("Diagrams up to date.")
