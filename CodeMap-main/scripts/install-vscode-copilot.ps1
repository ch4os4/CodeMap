[CmdletBinding()]
param(
    [string]$WorkspacePath = (Get-Location).Path,
    [string]$ServerName = "codeMap"
)

$ErrorActionPreference = "Stop"

function Get-PythonBootstrapCommand {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return @("python")
    }
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return @("py", "-3")
    }
    throw "Python 3.10+ was not found in PATH."
}

function Invoke-CommandArray {
    param(
        [string[]]$Command,
        [string]$WorkingDirectory
    )

    $exe = $Command[0]
    $args = @()
    if ($Command.Length -gt 1) {
        $args = $Command[1..($Command.Length - 1)]
    }

    Write-Host ">" $exe ($args -join " ")
    Push-Location $WorkingDirectory
    try {
        & $exe @args
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

function ConvertTo-HashtableDeep {
    param(
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $Value.Keys) {
            $result[$key] = ConvertTo-HashtableDeep -Value $Value[$key]
        }
        return $result
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = @()
        foreach ($item in $Value) {
            $items += ,(ConvertTo-HashtableDeep -Value $item)
        }
        return $items
    }

    if ($Value -is [psobject]) {
        $props = $Value.PSObject.Properties
        if ($props.Count -gt 0) {
            $result = @{}
            foreach ($prop in $props) {
                $result[$prop.Name] = ConvertTo-HashtableDeep -Value $prop.Value
            }
            return $result
        }
    }

    return $Value
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$McpRoot = Join-Path $RepoRoot "mcp-server"
$WorkspaceRoot = [System.IO.Path]::GetFullPath($WorkspacePath)
$VSCodeDir = Join-Path $WorkspaceRoot ".vscode"
$McpJsonPath = Join-Path $VSCodeDir "mcp.json"
$VenvPython = Join-Path $McpRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $WorkspaceRoot)) {
    New-Item -ItemType Directory -Force -Path $WorkspaceRoot | Out-Null
}

if (-not (Test-Path $VenvPython)) {
    $bootstrap = Get-PythonBootstrapCommand
    Invoke-CommandArray -Command ($bootstrap + @("-m", "venv", (Join-Path $McpRoot ".venv"))) -WorkingDirectory $McpRoot
}

Invoke-CommandArray -Command @($VenvPython, "-m", "pip", "install", "-e", $McpRoot) -WorkingDirectory $McpRoot

New-Item -ItemType Directory -Force -Path $VSCodeDir | Out-Null

$config = @{
    servers = @{}
}

if (Test-Path $McpJsonPath) {
    $raw = Get-Content -Raw -Path $McpJsonPath
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $parsed = $raw | ConvertFrom-Json
        if ($null -ne $parsed) {
            $config = ConvertTo-HashtableDeep -Value $parsed
        }
    }
}

if (-not $config.ContainsKey("servers") -or $null -eq $config.servers) {
    $config["servers"] = @{}
}

$config["servers"][$ServerName] = @{
    type = "stdio"
    command = $VenvPython
    args = @("-m", "codemap_mcp.server")
    cwd = $McpRoot
}

$json = $config | ConvertTo-Json -Depth 10
Set-Content -Path $McpJsonPath -Value $json -Encoding utf8

Write-Host ""
Write-Host "CodeMap MCP installed for VS Code Copilot."
Write-Host "Workspace:" $WorkspaceRoot
Write-Host "Config:" $McpJsonPath
Write-Host "Server name:" $ServerName
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Open the workspace in VS Code."
Write-Host "2. Open Chat and switch to Agent mode."
Write-Host "3. Confirm the '$ServerName' MCP tools are available."
