#Requires -Version 5.1
<#
.SYNOPSIS
  Populate third_party/ from a core checkout or a release tag asset (multi-platform).
.EXAMPLE
  .\sync-core.ps1 -CoreDir C:\Dev\libs\hakodb
  .\sync-core.ps1 -Tag v0.9.0
  .\sync-core.ps1 -Tag v0.9.0 -Platform linux
#>
param(
    [string]$CoreDir = "",
    [string]$Tag = "",
    [string]$Platform = "",
    [string]$LibTag = "linux-glibc2.28-el8"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Inc = Join-Path $Root "third_party\include"
$Lib = Join-Path $Root "third_party\lib"
New-Item -ItemType Directory -Force $Inc, $Lib | Out-Null

# Header is platform-independent C (superset decls); the flat release
# header is the linux-generated one. -CoreDir takes the locally built one.
function Sync-Header($base, $CoreDir) {
    if ($CoreDir -ne "") {
        $hdr = Join-Path $CoreDir "target\release\hakodb.h"
        if (-not (Test-Path $hdr)) { throw "no generated header at $hdr (cargo build --release first)" }
        Copy-Item $hdr $Inc -Force
    } else {
        Invoke-WebRequest -Uri "$base/hakodb.h" -OutFile (Join-Path $Inc "hakodb.h")
    }
}

if ($CoreDir -ne "") {
    Sync-Header -base $null -CoreDir $CoreDir
    $dll = Join-Path $CoreDir "target\release\hakodb.dll"
    $so = Join-Path $CoreDir "target\release\libhakodb.so"
    $found = @($dll, $so) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $found) { throw "no release library under $CoreDir\target\release (cargo build --release first)" }
    Copy-Item $found $Lib -Force
    Write-Output "synced from checkout: $CoreDir"
} elseif ($Tag -ne "") {
    if ($Platform -eq "") {
        if ($IsWindows -or $env:OS -eq "Windows_NT") { $Platform = "win32" }
        elseif ($IsLinux) { $Platform = "linux" }
        elseif ($IsMacOS) { $Platform = "darwin" }
        else { $Platform = "win32" }
    }
    $base = "https://github.com/hakodb/hakodb/releases/download/$Tag"
    Sync-Header -base $base -CoreDir ""
    if ($Platform -eq "win32") {
        Invoke-WebRequest -Uri "$base/hakodb-x86_64-pc-windows-msvc.dll" -OutFile (Join-Path $Lib "hakodb.dll")
    } elseif ($Platform -eq "linux") {
        # el8 build runs on glibc >= 2.28 everywhere; override -LibTag for an exact distro.
        Invoke-WebRequest -Uri "$base/libhakodb-x86_64-unknown-$LibTag.so" -OutFile (Join-Path $Lib "libhakodb.so")
    } elseif ($Platform -eq "android") {
        Invoke-WebRequest -Uri "$base/libhakodb-aarch64-linux-android.so" -OutFile (Join-Path $Lib "libhakodb.so")
    } elseif ($Platform -eq "darwin") {
        throw "no macOS prebuilt (no CI job yet) - build from source and use -CoreDir on a Mac"
    } else {
        throw "unknown -Platform '$Platform' (win32|linux|android|darwin)"
    }
    Write-Output "synced from release asset: $Tag ($Platform)"
} else {
    throw "pass -CoreDir or -Tag"
}
