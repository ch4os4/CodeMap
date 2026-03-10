#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_PATH="${1:-$(pwd)}"
SERVER_NAME="${2:-codeMap}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MCP_ROOT="${REPO_ROOT}/mcp-server"
VENV_PYTHON="${MCP_ROOT}/.venv/bin/python"
VSCODE_DIR="${WORKSPACE_PATH}/.vscode"
MCP_JSON="${VSCODE_DIR}/mcp.json"

if command -v python3 >/dev/null 2>&1; then
  BOOTSTRAP_PYTHON="python3"
elif command -v python >/dev/null 2>&1; then
  BOOTSTRAP_PYTHON="python"
else
  echo "Python 3.10+ was not found in PATH." >&2
  exit 1
fi

if [ ! -x "${VENV_PYTHON}" ]; then
  "${BOOTSTRAP_PYTHON}" -m venv "${MCP_ROOT}/.venv"
fi

"${VENV_PYTHON}" -m pip install -e "${MCP_ROOT}"

mkdir -p "${VSCODE_DIR}"

"${VENV_PYTHON}" - "${MCP_JSON}" "${SERVER_NAME}" "${VENV_PYTHON}" "${MCP_ROOT}" <<'PY'
import json
import pathlib
import sys

mcp_json = pathlib.Path(sys.argv[1])
server_name = sys.argv[2]
python_path = sys.argv[3]
mcp_root = sys.argv[4]

config = {"servers": {}}
if mcp_json.exists():
    raw = mcp_json.read_text(encoding="utf-8").strip()
    if raw:
        config = json.loads(raw)

servers = config.setdefault("servers", {})
servers[server_name] = {
    "type": "stdio",
    "command": python_path,
    "args": ["-m", "codemap_mcp.server"],
    "cwd": mcp_root,
}

mcp_json.write_text(json.dumps(config, indent=2), encoding="utf-8")
PY

echo ""
echo "CodeMap MCP installed for VS Code Copilot."
echo "Workspace: ${WORKSPACE_PATH}"
echo "Config: ${MCP_JSON}"
echo "Server name: ${SERVER_NAME}"
