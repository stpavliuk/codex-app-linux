#!/usr/bin/env python3

from pathlib import Path
import re
import sys


PATCH_MARKERS = (
    "function linuxCodeDetect(){",
    "function linuxHelixOpen({path:e,location:t})",
    "linuxClionTarget",
)

IDENT = r"[A-Za-z_$][A-Za-z0-9_$]*"


def require_match(text: str, pattern: str, description: str) -> re.Match[str]:
    match = re.search(pattern, text, re.DOTALL)
    if match is None:
        raise ValueError(description)
    return match


def extract_builder_args(text: str, builder_name: str, description: str) -> str:
    match = require_match(
        text,
        rf"function {builder_name}\([^)]*\)\{{.*?args:(?:{IDENT}\?\?)?(?P<args>{IDENT})",
        description,
    )
    return match.group("args")


def extract_metadata(text: str) -> dict[str, str]:
    registry = require_match(
        text,
        rf"var (?P<catalog>{IDENT})=\[(?P<entries>[^\]]+)\],(?P<logger>{IDENT})=(?P<logger_expr>{IDENT}\.{IDENT}\(`open-in-targets`\));",
        "open target registry not found",
    )
    vscode = require_match(
        text,
        rf"var (?P<var>{IDENT})=(?P<builder>{IDENT})\(\{{id:`vscode`,label:`VS Code`.*?\}}\);",
        "VS Code target definition not found",
    )
    zed = require_match(
        text,
        rf"var (?P<var>{IDENT})=\{{id:`zed`,platforms:\{{darwin:\{{.*?detect:(?P<detect>{IDENT}),args:(?P<args>{IDENT}),open:.*?\}},win32:\{{.*?args:(?P=args)\}}\}}\}};",
        "Zed target definition not found",
    )
    intellij = require_match(
        text,
        rf"(?P<var>{IDENT})=(?P<builder>{IDENT})\(\{{id:`intellij`,label:`IntelliJ IDEA`.*?\}}\)",
        "IntelliJ IDEA target definition not found",
    )
    which_helper = require_match(
        text,
        rf"function {zed.group('detect')}\(\)\{{return (?P<which>{IDENT})\(`zed`\)",
        "shell lookup helper not found",
    )
    runner = require_match(
        text,
        rf"await (?P<runner>{IDENT})\(`open`,",
        "process runner helper not found",
    )
    return {
        "catalog": registry.group("catalog"),
        "entries": registry.group("entries"),
        "logger": registry.group("logger"),
        "logger_expr": registry.group("logger_expr"),
        "vscode_var": vscode.group("var"),
        "vscode_args": extract_builder_args(text, vscode.group("builder"), "VS Code args helper not found"),
        "zed_var": zed.group("var"),
        "zed_args": zed.group("args"),
        "intellij_var": intellij.group("var"),
        "intellij_args": extract_builder_args(text, intellij.group("builder"), "IntelliJ IDEA args helper not found"),
        "which": which_helper.group("which"),
        "runner": runner.group("runner"),
    }


def build_replacement(metadata: dict[str, str]) -> str:
    which = metadata["which"]
    runner = metadata["runner"]
    vscode_var = metadata["vscode_var"]
    vscode_args = metadata["vscode_args"]
    zed_var = metadata["zed_var"]
    zed_args = metadata["zed_args"]
    intellij_var = metadata["intellij_var"]
    intellij_args = metadata["intellij_args"]
    catalog = metadata["catalog"]
    entries = metadata["entries"]
    logger = metadata["logger"]
    logger_expr = metadata["logger_expr"]

    return "\n".join(
        [
            f"function linuxCodeDetect(){{return {which}(`code`)??{which}(`code-oss`)??null}}",
            f"function linuxZedDetect(){{return {which}(`zeditor`)??{which}(`zed`)??null}}",
            f"function linuxIdeaDetect(){{return {which}(`idea`)??null}}",
            f"function linuxClionDetect(){{return {which}(`clion`)??null}}",
            f"function linuxTerminalDetect(){{return {which}(`ghostty`)??{which}(`alacritty`)??{which}(`konsole`)??{which}(`gnome-terminal`)??null}}",
            "function linuxHelixPath(e,t){return t?`${e}:${t.line}:${t.column}`:e}",
            f"function linuxHelixDetect(){{let e={which}(`hx`);return e!=null&&linuxTerminalDetect()!=null?e:null}}",
            f"async function linuxHelixOpen({{path:e,location:t}}){{let n=linuxTerminalDetect(),r={which}(`hx`);if(!n||!r)throw Error(`Open target \"helix\" is not available`);let i=linuxHelixPath(e,t);if(n.endsWith(`gnome-terminal`)){{await {runner}(n,[`--`,r,i]);return}}await {runner}(n,[`-e`,r,i])}}",
            f"{vscode_var}.platforms.linux={{label:`VS Code`,icon:`apps/vscode.png`,kind:`editor`,detect:linuxCodeDetect,args:{vscode_args},supportsSsh:!0}};",
            f"{zed_var}.platforms.linux={{label:`Zed`,icon:`apps/zed.png`,kind:`editor`,detect:linuxZedDetect,args:{zed_args}}};",
            f"{intellij_var}.platforms.linux={{label:`IntelliJ IDEA`,icon:`apps/intellij.png`,kind:`editor`,detect:linuxIdeaDetect,args:{intellij_args}}};",
            "var linuxHelixTarget={id:`helix`,platforms:{linux:{label:`Helix`,icon:`apps/terminal.png`,kind:`editor`,detect:linuxHelixDetect,open:linuxHelixOpen,args:e=>[e]}}},",
            f"linuxClionTarget={{id:`clion`,platforms:{{linux:{{label:`CLion`,icon:`apps/intellij.png`,kind:`editor`,detect:linuxClionDetect,args:{intellij_args}}}}}}},",
            f"{catalog}=[{entries},linuxHelixTarget,linuxClionTarget],{logger}={logger_expr};",
        ]
    )


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch-linux-editor-targets.py <main-bundle.js>")

    target = Path(sys.argv[1])
    text = target.read_text()

    if all(marker in text for marker in PATCH_MARKERS):
        print(f"{target}: already patched")
        return 0

    try:
        metadata = extract_metadata(text)
    except ValueError as exc:
        print(f"{target}: {exc}; leaving bundle unpatched", file=sys.stderr)
        return 1

    stock_catalog = require_match(
        text,
        rf"var {metadata['catalog']}=\[[^\]]+\],{metadata['logger']}={re.escape(metadata['logger_expr'])};",
        "open target registry not found",
    ).group(0)
    patched = text.replace(stock_catalog, build_replacement(metadata), 1)
    target.write_text(patched)
    print(f"{target}: patched")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
