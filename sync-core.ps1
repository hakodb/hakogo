#Requires -Version 5.1
<#
.SYNOPSIS
  Populate third_party/ from a core checkout or a release tag asset.
.EXAMPLE
  .\sync-core.ps1 -CoreDir C:\Dev\libs\firelite
  .\sync-core.ps1 -Tag v0.8.20
#>
param(
    [string]$CoreDir = "",
    [string]$Tag = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Inc = Join-Path $Root "third_party\include"
$Lib = Join-Path $Root "third_party\lib"
New-Item -ItemType Directory -Force $Inc, $Lib | Out-Null

if ($CoreDir -ne "") {
    Copy-Item (Join-Path $CoreDir "include\hakodb.h") $Inc -Force
    $dll = Join-Path $CoreDir "target\release\hakodb.dll"
    if (-not (Test-Path $dll)) { throw "no release DLL at $dll (cargo build --release first)" }
    Copy-Item $dll $Lib -Force
    Write-Output "synced from checkout: $CoreDir"
} elseif ($Tag -ne "") {
    $base = "https://github.com/hakodb/hakodb/releases/download/$Tag"
    Invoke-WebRequest -Uri "$base/hako.h" -OutFile (Join-Path $Inc "hako.h")
    Invoke-WebRequest -Uri "$base/hakodb-x86_64-pc-windows-msvc.dll" -OutFile (Join-Path $Lib "hakodb.dll")
    Write-Output "synced from release asset: $Tag"
} else {
    throw "pass -CoreDir or -Tag"
}
