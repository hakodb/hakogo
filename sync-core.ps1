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
    Copy-Item (Join-Path $CoreDir "include\firelite.h") $Inc -Force
    $dll = Join-Path $CoreDir "target\release\firelite.dll"
    if (-not (Test-Path $dll)) { throw "no release DLL at $dll (cargo build --release first)" }
    Copy-Item $dll $Lib -Force
    Write-Output "synced from checkout: $CoreDir"
} elseif ($Tag -ne "") {
    $zip = Join-Path $env:TEMP "firelite-$Tag-windows.zip"
    Invoke-WebRequest -Uri "https://github.com/rizaptk/firelite/releases/download/$Tag/firelite-$Tag-x86_64-pc-windows-msvc.zip" -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $env:TEMP\firelite-rel -Force
    Copy-Item $env:TEMP\firelite-rel\firelite.h $Inc -Force
    Copy-Item $env:TEMP\firelite-rel\firelite.dll $Lib -Force
    Write-Output "synced from release asset: $Tag"
} else {
    throw "pass -CoreDir or -Tag"
}
