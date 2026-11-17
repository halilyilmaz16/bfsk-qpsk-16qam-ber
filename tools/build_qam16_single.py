#!/usr/bin/env python3
"""Build the portable MATLAB GUI from the project's maintained sources."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = {
    "qam16_standalone": ROOT / "teslim" / "qam16_standalone.m",
    "qam16_tek_dosya": ROOT / "teslim" / "qam16_tek_dosya.m",
}
SOURCES = (
    "gui/qam16_gui.m",
    "src/qam16_experiment.m",
    "src/qam16_mod.m",
    "src/qam16_demod.m",
    "src/ber_theory.m",
)
FUNCTION = re.compile(
    r"^\s*function\s+(?:(?:\[[^\]]+\]|[A-Za-z]\w*)\s*=\s*)?"
    r"([A-Za-z]\w*)\s*(?:\(|$)",
    re.MULTILINE,
)


def gui_source(source: str, entry: str) -> str:
    """Rename the entry point and remove only the project path bootstrap."""
    declaration = "function fig = qam16_gui(options)"
    if not source.startswith(declaration + "\n"):
        raise ValueError("GUI entry point changed; review the bundler.")
    source = source.replace(declaration, f"function fig = {entry}(options)", 1)
    bootstrap = (
        "    rootDir = fileparts(fileparts(mfilename('fullpath')));\n"
        "    addpath(fullfile(rootDir, 'src'));\n"
    )
    if source.count(bootstrap) != 1:
        raise ValueError("GUI path bootstrap changed; review the bundler.")
    source = source.replace(bootstrap, "", 1)
    source = source.replace("%QAM16_GUI", "%"+entry.upper(), 1)
    source = source.replace("%   fig = qam16_gui(", f"%   fig = {entry}(")
    declaration, body = source.split("\n", 1)
    header = (
        "% Single-file use: copy this file to a folder and select that folder\n"
        f"% as MATLAB's Current Folder, then enter {entry}.\n"
        f"% Automatic experiment: {entry}(struct('AutoRun',true))\n"
        "% Options: Visible ('on'/'off'), AutoRun, ExportDir.\n"
        "% Project contribution: Emir Dündar.\n"
        "% Generator: tools/build_qam16_single.py (Python 3; no extra packages).\n"
        "% Rebuild after source changes; do not edit this generated output.\n"
        "%\n"
        "% === Source: gui/qam16_gui.m (portable entry point) ===\n"
    )
    return declaration + "\n" + header + body


def build(entry: str) -> str:
    sections = []
    original_functions = []
    for relative in SOURCES:
        source = (ROOT / relative).read_text(encoding="utf-8-sig").rstrip() + "\n"
        original_functions.extend(FUNCTION.findall(source))
        if relative == SOURCES[0]:
            sections.append(gui_source(source, entry))
        else:
            sections.append(f"% === Source: {relative} ===\n" + source)
    result = "\n".join(sections)
    functions = FUNCTION.findall(result)
    expected = [entry if n == "qam16_gui" else n for n in original_functions]
    if functions != expected:
        raise ValueError("A source function was lost or reordered during bundling.")
    if len({n.casefold() for n in functions}) != len(functions):
        raise ValueError("Duplicate MATLAB function names in the combined file.")
    if "rootDir" in result or re.search(r"^\s*addpath\s*\(", result, re.MULTILINE):
        raise ValueError("The standalone file still changes the MATLAB path.")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check output without rewriting it.")
    args = parser.parse_args()
    for entry, output in OUTPUTS.items():
        result = build(entry)
        if args.check:
            if not output.is_file() or output.read_text(encoding="utf-8") != result:
                parser.exit(1, "Standalone MATLAB output is missing or stale.\n")
            print(f"Up to date: {output.relative_to(ROOT)}")
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(result, encoding="utf-8", newline="\n")
            print(f"Built {output.relative_to(ROOT)} ({len(result.splitlines())} lines)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
