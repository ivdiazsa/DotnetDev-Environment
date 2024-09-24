#Requires -Version 7.0

# ********************************** #
# Set up the Dotnet Dev Environment! #
# ********************************** #

$EXT = if ($IsWindows) { ".exe" } else { "" }

$dotnetDevSrc = Join-Path $PSScriptRoot "src"
$dotnetDevApp = Join-Path $dotnetDevSrc "App" "DotnetDev$EXT"

# First, we need to build the Dotnet Dev App. All its configuration parameters are
# already set in the csproj, so calling 'dotnet build' is enough.
dotnet build (Join-Path $dotnetDevSrc "DotnetDev.csproj")

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nSomething went wrong building the Dotnet Dev Environment. Check the C# message."
    return 1
}

# ************************************ #
# Configure the Dotnet Dev Environment #
# ************************************ #

$Env:DOTNET_DEV_WHATIF_PREVIEW = 0
$Env:DOTNET_DEV_REPO = ""

$Env:DOTNET_DEV_OS = (Invoke-Expression "$dotnetDevApp getos")
$Env:DOTNET_DEV_ARCH = (Invoke-Expression "$dotnetDevApp getarch")
$Env:DOTNET_DEV_CONFIG = "Debug"

$Env:DOTNET_DEV_PLATFORM = "$Env:DOTNET_DEV_OS.$Env:DOTNET_DEV_ARCH.$Env:DOTNET_DEV_CONFIG"
$Env:DOTNET_DEV_COREROOT = ""
$Env:DOTNET_DEV_CLRBIN_ARTIFACTS = ""
$Env:DOTNET_DEV_CLRTEST_ARTIFACTS = ""

$Env:DOTNET_DEV_CLRSRC = ""
$Env:DOTNET_DEV_TESTSRC = ""
$Env:DOTNET_DEV_LIBSSRC = ""
$Env:DOTNET_DEV_MONOSRC = ""

function Set-OS([string]$OsValue) {
    $newOsOut = (Invoke-Expression "$dotnetDevApp setos $OsValue")
    $setOsCode = $LASTEXITCODE

    if ($setOsCode -ne 0) {
        Write-Host $newOsOut
        return 1
    }

    if ($Env:DOTNET_DEV_WHATIF_PREVIEW -ne 0) {
        Write-Host "\$Env:DOTNET_DEV_OS = '$newOsOut'"
    }
    else {
        $Env:DOTNET_DEV_OS = $newOsOut
    }

    Update-Platform
}

function Set-Arch([string]$ArchValue) {
    Write-Host $archValue
    $newArchOut = (Invoke-Expression "$dotnetDevApp setarch $ArchValue")
    $setArchCode = $LASTEXITCODE

    if ($setArchCode -ne 0) {
        Write-Host $newArchOut
        return 1
    }

    if ($Env:DOTNET_DEV_WHATIF_PREVIEW -ne 0) {
        Write-Host "\$Env:DOTNET_DEV_ARCH = '$newArchOut'"
    }
    else {
        $Env:DOTNET_DEV_ARCH = $newArchOut
    }

    Update-Platform
}

function Set-Config([string]$ConfigValue) {
    $newConfigOut = (Invoke-Expression "$dotnetDevApp setconfig $ConfigValue")
    $setConfigCode = $LASTEXITCODE

    if ($setConfigCode -ne 0) {
        Write-Host $newConfigOut
        return 1
    }

    if ($Env:DOTNET_DEV_WHATIF_PREVIEW -ne 0) {
        Write-Host "\$Env:DOTNET_DEV_CONFIG = '$newConfigOut'"
    }
    else {
        $Env:DOTNET_DEV_CONFIG = $newConfigOut
    }

    Update-Platform
}

function Set-Repo([string]$RepoValue) {
    $newRepoOut = (Invoke-Expression "$dotnetDevApp setrepo $RepoValue")
    $setRepoCode = $LASTEXITCODE

    if ($setRepoCode -ne 0) {
        Write-Host $newRepoOut
        return 1
    }

    $envVars = @{
        "DOTNET_DEV_REPO" = $newRepoOut
        "DOTNET_DEV_CLRSRC" = (Join-Path $newRepoOut "src" "coreclr")
        "DOTNET_DEV_TESTSRC" = (Join-Path $newRepoOut "src" "tests")
        "DOTNET_DEV_LIBSSRC" = (Join-Path $newRepoOut "src" "libraries")
        "DOTNET_DEV_MONOSRC" = (Join-Path $newRepoOut "src" "mono")

        "DOTNET_DEV_CLRBIN_ARTIFACTS" = `
          (Join-Path $newRepoOut "artifacts" "bin" "coreclr")

        "DOTNET_DEV_CLRTEST_ARTIFACTS" = `
          (Join-Path $newRepoOut "artifacts" "tests" "coreclr" $Env:DOTNET_DEV_PLATFORM)

        "DOTNET_DEV_COREROOT" = (Join-Path $newRepoOut              `
                                           "artifacts"              `
                                           "tests"                  `
                                           "coreclr"                `
                                           $Env:DOTNET_DEV_PLATFORM `
                                           "Tests"                  `
                                           "Core_Root")
    }

    $envVars.GetEnumerator() | ForEach-Object {
        $exportCmd = "Set-Item Env:$($_.Key) $($_.Value)"

        if ($Env:DOTNET_DEV_WHATIF_PREVIEW -ne 0) {
            Write-Host $exportCmd
        }
        else {
            Invoke-Expression $exportCmd
        }
    }
}

function Set-CoreRootEnvVar() {
    $Env:CORE_ROOT = $Env:DOTNET_DEV_COREROOT
}

function Update-Platform() {
    $Env:DOTNET_DEV_PLATFORM = "$Env:DOTNET_DEV_OS.$Env:DOTNET_DEV_ARCH.$Env:DOTNET_DEV_CONFIG"

    $Env:DOTNET_DEV_CLRTEST_ARTIFACTS = `
      (Join-Path $Env:DOTNET_DEV_REPO "artifacts" "tests" "coreclr" $Env:DOTNET_DEV_PLATFORM)

    $Env:DOTNET_DEV_COREROOT = `
      (Join-Path $Env:DOTNET_DEV_CLRTEST_ARTIFACTS "Tests" "Core_Root")
}

# **************************************************************** #
# The Functions in Charge of all the Dotnet Dev Environment Magic! #
# **************************************************************** #

function WhatIf-Preview() {
    if ($Env:DOTNET_DEV_WHATIF_PREVIEW -eq 0) {
        $Env:DOTNET_DEV_WHATIF_PREVIEW = 1
        Write-Host "What-If Preview Mode Enabled."
    }
    else {
        $Env:DOTNET_DEV_WHATIF_PREVIEW = 0
        Write-Host "What-If Preview Mode Disabled."
    }
}

function Build-Repo([string]$BuildType) {
    $buildRepoOut = (Invoke-Expression "$dotnetDevApp build $BuildType $args")
    $buildRepoCode = $LASTEXITCODE

    if (($buildRepoCode -ne 0) -or ($Env:DOTNET_DEV_WHATIF_PREVIEW -ne 0)) {
        Write-Host $buildRepoOut
        return 1
    }

    Invoke-Expression $buildRepoOut
}

# ************************** #
# Aliases for the Functions! #
# ************************** #

# To follow Powershell's coding standards, we defined the functions using the
# two-word notation separated by a dash '-'. However, to keep the experience
# seamless with its bash counterpart, we're adding some aliases to call the
# functions just like in the bash version of the environment.

Set-Alias -Name setos             -Value Set-OS
Set-Alias -Name setarch           -Value Set-Arch
Set-Alias -Name setconfig         -Value Set-Config
Set-Alias -Name setrepo           -Value Set-Repo
Set-Alias -Name setcorerootenvvar -Value Set-CoreRootEnvVar
Set-Alias -Name whatifpreview     -Value WhatIf-Preview
Set-Alias -Name buildrepo         -Value Build-Repo

# ********************************* #
# Magical Aliases! Er... Functions! #
# ********************************* #

# Since Powershell doesn't support commands with arguments in aliases, we'll have
# to use functions and then alias those instead.

function Build-Clr() { Build-Repo "main" "subset=clr $args" }
function Build-ClrDbg() { Build-Repo "main" "subset=clr config=dbg $args" }
function Build-ClrChk() { Build-Repo "main" "subset=clr config=chk $args" }
function Build-ClrRel() { Build-Repo "main" "subset=clr config=rel $args" }

function Build-Libs() { Build-Repo "main" "subset=libs $args" }
function Build-LibsDbg() { Build-Repo "main" "subset=libs config=dbg $args" }
function Build-LibsRel() { Build-Repo "main" "subset=libs config=rel $args" }

function Build-ClrLibs() { Build-Repo "main" "subset=clr+libs $args" }
function Build-ClrLibsDbg() { Build-Repo "main" "subset=clr+libs config=dbg $args" }
function Build-ClrLibsRel() { Build-Repo "main" "subset=clr+libs config=rel $args" }

function Build-ClrLibsChkDbg() {
    Build-Repo "main" "subset=clr+libs clrconfig=chk libsconfig=dbg $args"
}

function Build-ClrLibsRelDbg() {
    Build-Repo "main" "subset=clr+libs clrconfig=rel libsconfig=dbg $args"
}

function Build-ClrLibsDbgRel() {
    Build-Repo "main" "subset=clr+libs clrconfig=dbg libsconfig=rel $args"
}

function Build-ClrLibsChkRel() {
    Build-Repo "main" "subset=clr+libs clrconfig=chk libsconfig=rel $args"
}

function Gen-CoreRoot() {
    Build-Repo "tests" "libs=rel -GenerateLayoutOnly $args"
}

function Gen-CoreRootDbg() {
    Build-Repo "tests" "libs=rel clr=dbg -GenerateLayoutOnly $args"
}

function Gen-CoreRootChk() {
    Build-Repo "tests" "libs=rel clr=chk -GenerateLayoutOnly $args"
}

function Gen-CoreRootRel() {
    Build-Repo "tests" "libs=rel clr=rel -GenerateLayoutOnly $args"
}

function Gen-CoreRootLibsDbg() {
    Build-Repo "tests" "libs=dbg -GenerateLayoutOnly $args"
}

function Gen-CoreRootDbgLibsDbg() {
    Build-Repo "tests" "libs=dbg clr=dbg -GenerateLayoutOnly $args"
}

function Gen-CoreRootChkLibsDbg() {
    Build-Repo "tests" "libs=dbg clr=chk -GenerateLayoutOnly $args"
}

function Gen-CoreRootRelLibsDbg() {
    Build-Repo "tests" "libs=dbg clr=rel -GenerateLayoutOnly $args"
}

function Cd-Clr() { Set-Location $Env:DOTNET_DEV_CLRSRC }
function Cd-Tests() { Set-Location $Env:DOTNET_DEV_TESTSRC }
function Cd-Libs() { Set-Location $Env:DOTNET_DEV_LIBSSRC }
function Cd-Mono() { Set-Location $Env:DOTNET_DEV_MONOSRC }

function Cd-ClrBins() { Set-Location $Env:DOTNET_DEV_CLRBIN_ARTIFACTS }
function Cd-ClrTests() { Set-Location $Env:DOTNET_DEV_CLRTEST_ARTIFACTS }
function Cd-CoreRoot() { Set-Location $Env:DOTNET_DEV_COREROOT }

Set-Alias -Name buildclr    -Value Build-Clr
Set-Alias -Name buildclrdbg -Value Build-ClrDbg
Set-Alias -Name buildclrchk -Value Build-ClrChk
Set-Alias -Name buildclrrel -Value Build-ClrRel

Set-Alias -Name buildlibs    -Value Build-Libs
Set-Alias -Name buildlibsdbg -Value Build-LibsDbg
Set-Alias -Name buildlibsrel -Value Build-LibsRel

Set-Alias -Name buildclrlibs    -Value Build-ClrLibs
Set-Alias -Name buildclrlibsdbg -Value Build-ClrLibsDbg
Set-Alias -Name buildclrlibsrel -Value Build-ClrLibsRel

Set-Alias -Name buildclrlibschkdbg -Value Build-ClrLibsChkDbg
Set-Alias -Name buildclrlibsreldbg -Value Build-ClrLibsRelDbg
Set-Alias -Name buildclrlibsdbgrel -Value Build-ClrLibsDbgRel
Set-Alias -Name buildclrlibschkrel -Value Build-ClrLibsChkRel

Set-Alias -Name gencoreroot    -Value Gen-CoreRoot
Set-Alias -Name gencorerootdbg -Value Gen-CoreRootDbg
Set-Alias -Name gencorerootchk -Value Gen-CoreRootChk
Set-Alias -Name gencorerootrel -Value Gen-CoreRootRel

Set-Alias -Name gencorerootlibsdbg    -Value Gen-CoreRootLibsDbg
Set-Alias -Name gencorerootdbglibsdbg -Value Gen-CoreRootDbgLibsDbg
Set-Alias -Name gencorerootchklibsdbg -Value Gen-CoreRootChkLibsDbg
Set-Alias -Name gencorerootrellibsdbg -Value Gen-CoreRootRelLibsDbg

Set-Alias -Name cdclr   -Value Cd-Clr
Set-Alias -Name cdtests -Value Cd-Tests
Set-Alias -Name cdlibs  -Value Cd-Libs
Set-Alias -Name cdmono  -Value Cd-Mono

Set-Alias -Name cdclrbins  -Value Cd-ClrBins
Set-Alias -Name cdclrtests -Value Cd-ClrTests
Set-Alias -Name cdcoreroot -Value Cd-CoreRoot
