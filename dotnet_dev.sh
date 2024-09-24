#!/usr/bin/env bash

# ********************************** #
# Set up the Dotnet Dev Environment! #
# ********************************** #

case "$(uname -s)" in
    CYGWIN*|MINGW*|MSYS*)
        EXT='.exe'
        ;;
    *)
        EXT=''
        ;;
esac

DOTNET_DEV_SRC=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOTNET_DEV_SRC="$DOTNET_DEV_SRC/src"
DOTNET_DEV_APP="$DOTNET_DEV_SRC/App/DotnetDev$EXT"

# First, we need to build the Dotnet Dev App. All its configuration parameters are
# already set in the csproj, so calling 'dotnet build' is enough.
dotnet build "$DOTNET_DEV_SRC/DotnetDev.csproj"

if [[ "$?" != "0" ]]; then
    echo -e "\nSomething went wrong building the Dotnet Dev Environment. Check the C# message."
    return 1
fi

# ************************************ #
# Configure the Dotnet Dev Environment #
# ************************************ #

export DOTNET_DEV_WHATIF_PREVIEW=0
export DOTNET_DEV_REPO=""

export DOTNET_DEV_OS="$($DOTNET_DEV_APP getos)"
export DOTNET_DEV_ARCH="$($DOTNET_DEV_APP getarch)"
export DOTNET_DEV_CONFIG="Debug"

export DOTNET_DEV_PLATFORM="$DOTNET_DEV_OS.$DOTNET_DEV_ARCH.$DOTNET_DEV_CONFIG"
export DOTNET_DEV_COREROOT=""
export DOTNET_DEV_CLRBIN_ARTIFACTS=""
export DOTNET_DEV_CLRTEST_ARTIFACTS=""

export DOTNET_DEV_CLRSRC=""
export DOTNET_DEV_TESTSRC=""
export DOTNET_DEV_LIBSSRC=""
export DOTNET_DEV_MONOSRC=""

function setos {
    local newos_out
    local setos_code

    newos_out=$($DOTNET_DEV_APP setos "$1")
    setos_code=$?

    if [[ "$setos_code" != "0" ]]; then
        echo $newos_out
        return 1
    fi

    if [[ "$DOTNET_DEV_WHATIF_PREVIEW" != "0" ]]; then
        echo "export DOTNET_DEV_OS=$newos_out"
    else
        export DOTNET_DEV_OS=$newos_out
    fi

    updateplatform
}

function setarch {
    local newarch_out
    local setarch_code

    newarch_out=$($DOTNET_DEV_APP setarch "$1")
    setarch_code=$?

    if [[ "$setarch_code" != "0" ]]; then
        echo $newarch_out
        return 1
    fi

    if [[ "$DOTNET_DEV_WHATIF_PREVIEW" != "0" ]]; then
        echo "export DOTNET_DEV_ARCH=$newarch_out"
    else
        export DOTNET_DEV_ARCH=$newarch_out
    fi

    updateplatform
}

function setconfig {
    local newconfig_out
    local setconfig_code

    newconfig_out=$($DOTNET_DEV_APP setconfig "$1")
    setconfig_code=$?

    if [[ "$setconfig_code" != "0" ]]; then
        echo $newconfig_out
        return 1
    fi

    if [[ "$DOTNET_DEV_WHATIF_PREVIEW" != "0" ]]; then
        echo "export DOTNET_DEV_CONFIG=$newconfig_out"
    else
        export DOTNET_DEV_CONFIG=$newconfig_out
    fi

    updateplatform
}

function setrepo {
    local repopath_out
    local setrepo_code

    repopath_out=$($DOTNET_DEV_APP setrepo "$1")
    setrepo_code=$?

    if [[ "$setrepo_code" != "0" ]]; then
        echo $repopath_out
        return 1
    fi

    envvars_exports=("export DOTNET_DEV_REPO=$repopath_out"
                     "export DOTNET_DEV_CLRSRC=$repopath_out/src/coreclr"
                     "export DOTNET_DEV_TESTSRC=$repopath_out/src/tests"
                     "export DOTNET_DEV_LIBSSRC=$repopath_out/src/libraries"
                     "export DOTNET_DEV_MONOSRC=$repopath_out/src/mono"

                     "export DOTNET_DEV_CLRBIN_ARTIFACTS=$repopath_out/\
artifacts/bin/coreclr"

                     "export DOTNET_DEV_CLRTEST_ARTIFACTS=$repopath_out/\
artifacts/tests/coreclr/$DOTNET_DEV_PLATFORM"

                     "export DOTNET_DEV_COREROOT=$repopath_out/artifacts/tests/\
coreclr/$DOTNET_DEV_PLATFORM/Tests/Core_Root")

    for export_cmd in "${envvars_exports[@]}"
    do
        if [[ "$DOTNET_DEV_WHATIF_PREVIEW" != "0" ]]; then
            echo "$export_cmd"
        else
            $export_cmd
        fi
    done
}

function setcorerootenvvar {
    export CORE_ROOT=$DOTNET_DEV_COREROOT
}

function updateplatform {
    export DOTNET_DEV_PLATFORM="$DOTNET_DEV_OS.$DOTNET_DEV_ARCH.$DOTNET_DEV_CONFIG"
    export DOTNET_DEV_CLRTEST_ARTIFACTS="$DOTNET_DEV_REPO/artifacts/tests/coreclr/\
$DOTNET_DEV_PLATFORM"
    export DOTNET_DEV_COREROOT="$DOTNET_DEV_CLRTEST_ARTIFACTS/Tests/Core_Root"
}

# **************************************************************** #
# The Functions in Charge of all the Dotnet Dev Environment Magic! #
# **************************************************************** #

function whatifpreview {
    if [[ "$DOTNET_DEV_WHATIF_PREVIEW" == "0" ]]; then
        export DOTNET_DEV_WHATIF_PREVIEW=1
        echo 'What-If Preview Mode Enabled.'
    else
        export DOTNET_DEV_WHATIF_PREVIEW=0
        echo 'What-If Preview Mode Disabled.'
    fi
}

function buildrepo {
    local buildrepo_out
    local buildrepo_code
    local build_type="$1"
    shift

    buildrepo_out=$($DOTNET_DEV_APP "build" $build_type "$@")
    buildrepo_code=$?

    if [[ "$buildrepo_code" != "0" || "$DOTNET_DEV_WHATIF_PREVIEW" != "0" ]]; then
        echo $buildrepo_out
        return 1
    fi

    $buildrepo_out
}

function testing {
    local bldtyp=$1
    shift
    $DOTNET_DEV_APP "build" "$bldtyp" "$@"
}

alias testingalias="testing main set=clr+libs config=rel lc=dbg runconfig=chk arch=x64 arch=x86 -s host -os linux -rc Release -lc Release -a arm64"

alias testingalias2="testing main set=clr.runtime+clr.corelib+clr.nativecorelib+clr.tools+clr.iltools arch=arm64 config=Release subset=clr.alljits+clr.spmi -s libs /p:NoPgo=true --runtimeConfiguration Checked -p:UseCrossgen2=false --test -arch x64,x86 -bl"

alias testingalias3="testing tests clr=chk libs=dbg -generatelayoutonly -test:path.csproj -p:UseLocalAppHostPack=true"

# *************** #
# Magical Aliases #
# *************** #

alias buildmain="buildrepo main"
alias buildtests="buildrepo tests"

alias buildclr="buildrepo main subset=clr"
alias buildclrdbg="buildrepo main subset=clr config=dbg"
alias buildclrchk="buildrepo main subset=clr config=chk"
alias buildclrrel="buildrepo main subset=clr config=rel"

alias buildlibs="buildrepo main subset=libs"
alias buildlibsdbg="buildrepo main subset=libs config=dbg"
alias buildlibsrel="buildrepo main subset=libs config=rel"

alias buildclrlibs="buildrepo main subset=clr+libs"
alias buildclrlibsdbg="buildrepo main subset=clr+libs config=dbg"
alias buildclrlibsrel="buildrepo main subset=clr+libs config=rel"

alias buildclrlibschkdbg="buildrepo main subset=clr+libs clrconfig=chk libsconfig=dbg"
alias buildclrlibsreldbg="buildrepo main subset=clr+libs clrconfig=rel libsconfig=dbg"
alias buildclrlibsdbgrel="buildrepo main subset=clr+libs clrconfig=dbg libsconfig=rel"
alias buildclrlibschkrel="buildrepo main subset=clr+libs clrconfig=chk libsconfig=rel"

alias gencoreroot="buildrepo tests libs=rel -generatelayoutonly"
alias gencorerootdbg="buildrepo tests libs=rel clr=dbg -generatelayoutonly"
alias gencorerootchk="buildrepo tests libs=rel clr=chk -generatelayoutonly"
alias gencorerootrel="buildrepo tests libs=rel clr=rel -generatelayoutonly"

alias gencorerootlibsdbg="buildrepo tests libs=dbg -generatelayoutonly"
alias gencorerootdbglibsdbg="buildrepo tests libs=dbg clr=dbg -generatelayoutonly"
alias gencorerootchklibsdbg="buildrepo tests libs=dbg clr=chk -generatelayoutonly"
alias gencorerootrellibsdbg="buildrepo tests libs=dbg clr=rel -generatelayoutonly"

# Using single quotes here because we want to cd into the literal environment variable,
# to whatever value it has when issuing the alias. Otherwise, it will expand the
# environment variable at the time of sourcing the script, and assign that value to
# the 'cd' path, which in this case would be the empty string.

alias cdclr='cd $DOTNET_DEV_CLRSRC'
alias cdlibs='cd $DOTNET_DEV_LIBSSRC'
alias cdmono='cd $DOTNET_DEV_MONOSRC'
alias cdtests='cd $DOTNET_DEV_TESTSRC'

alias cdclrbins='cd $DOTNET_DEV_CLRBIN_ARTIFACTS'
alias cdclrtests='cd $DOTNET_DEV_CLRTEST_ARTIFACTS'
alias cdcoreroot='cd $DOTNET_DEV_COREROOT'
