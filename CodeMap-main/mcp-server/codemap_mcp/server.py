from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP


REPO_ROOT = Path(__file__).resolve().parents[2]
WINDOWS = os.name == "nt"
WRAPPER_PATH = REPO_ROOT / "bin" / ("codegraph.cmd" if WINDOWS else "codegraph")
LOCAL_BINARIES = [
    REPO_ROOT / "rust-cli" / "target" / "release" / ("codegraph.exe" if WINDOWS else "codegraph"),
    REPO_ROOT / "rust-cli" / "target" / "debug" / ("codegraph.exe" if WINDOWS else "codegraph"),
]

mcp = FastMCP(
    "CodeMap",
    instructions=(
        "Expose CodeMap's AST graph workflow over MCP. "
        "Use scan before first analysis, update after edits, slice to load compact context, "
        "query for symbols/modules, and impact to estimate refactor blast radius."
    ),
    json_response=True,
)


class CodegraphError(RuntimeError):
    """Raised when the underlying codegraph CLI fails."""


def _resolve_project_dir(project_dir: str) -> Path:
    return Path(project_dir).expanduser().resolve()


def _wrapper_command(path: Path) -> list[str]:
    if WINDOWS:
        return ["cmd", "/c", str(path)]
    return ["bash", str(path)]


def _resolve_codegraph_command() -> list[str]:
    env_bin = os.environ.get("CODEMAP_BIN")
    if env_bin:
        env_path = Path(env_bin).expanduser()
        if not env_path.exists():
            raise CodegraphError(f"CODEMAP_BIN does not exist: {env_path}")
        if WINDOWS and env_path.suffix.lower() in {".cmd", ".bat"}:
            return ["cmd", "/c", str(env_path)]
        return [str(env_path)]

    if WRAPPER_PATH.exists():
        return _wrapper_command(WRAPPER_PATH)

    for candidate in LOCAL_BINARIES:
        if candidate.exists():
            return [str(candidate)]

    path_bin = shutil.which("codegraph")
    if path_bin:
        return [path_bin]

    cargo = shutil.which("cargo")
    manifest = REPO_ROOT / "rust-cli" / "Cargo.toml"
    if cargo and manifest.exists():
        return [cargo, "run", "--quiet", "--manifest-path", str(manifest), "--"]

    raise CodegraphError(
        "Unable to locate codegraph. Set CODEMAP_BIN, build rust-cli, or use the bundled bin wrapper."
    )


def _run_codegraph(args: list[str]) -> str:
    command = [*_resolve_codegraph_command(), *args]
    result = subprocess.run(
        command,
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )

    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or f"exit code {result.returncode}"
        raise CodegraphError(detail)

    return result.stdout.strip()


def _run_json(args: list[str]) -> Any:
    raw = _run_codegraph(args)
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise CodegraphError(f"Failed to parse JSON output: {exc}\nRaw output:\n{raw}") from exc


def _exclude_args(exclude: list[str] | None) -> list[str]:
    if not exclude:
        return []
    return ["--exclude", *exclude]


@mcp.tool()
def scan_project(project_dir: str = ".", exclude: list[str] | None = None) -> dict[str, Any]:
    """Scan a project and persist its .codemap graph."""
    project = _resolve_project_dir(project_dir)
    return _run_json(["scan", str(project), "--json", *_exclude_args(exclude)])


@mcp.tool()
def get_graph_status(project_dir: str = ".") -> dict[str, Any]:
    """Return graph metadata, summary counts, and freshness details."""
    project = _resolve_project_dir(project_dir)
    return _run_json(["status", str(project), "--json"])


@mcp.tool()
def load_graph_slice(
    project_dir: str = ".",
    module: str | None = None,
    with_dependencies: bool = True,
) -> dict[str, Any]:
    """Load the project overview or a module slice as structured JSON."""
    project = _resolve_project_dir(project_dir)
    args = ["slice"]
    if module:
        args.append(module)
        if with_dependencies:
            args.append("--with-deps")
    args.extend(["--dir", str(project)])
    return _run_json(args)


@mcp.tool()
def query_symbol(
    symbol: str,
    project_dir: str = ".",
    symbol_type: str | None = None,
) -> dict[str, Any]:
    """Search functions, classes, types, or variables by name."""
    project = _resolve_project_dir(project_dir)
    args = ["query", symbol, "--dir", str(project), "--json"]
    if symbol_type:
        args.extend(["--type", symbol_type])
    return _run_json(args)


@mcp.tool()
def query_module(module: str, project_dir: str = ".") -> dict[str, Any]:
    """Return files and dependency relationships for a module."""
    project = _resolve_project_dir(project_dir)
    return _run_json(["query", module, "--module", "--dir", str(project), "--json"])


@mcp.tool()
def update_project(project_dir: str = ".", exclude: list[str] | None = None) -> dict[str, Any]:
    """Incrementally refresh the graph using file hashes."""
    project = _resolve_project_dir(project_dir)
    return _run_json(["update", str(project), "--json", *_exclude_args(exclude)])


@mcp.tool()
def analyze_impact(target: str, project_dir: str = ".", depth: int = 3) -> dict[str, Any]:
    """Estimate affected modules and files before changing a module or file."""
    project = _resolve_project_dir(project_dir)
    return _run_json(["impact", target, "--dir", str(project), "--depth", str(depth), "--json"])


def main() -> None:
    """Entry point for direct stdio execution."""
    mcp.run()


if __name__ == "__main__":
    main()
