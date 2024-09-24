# DotnetDev Environment!

- [Requirements](#requirements)
- [How To Use It](#how-to-use-it)
  - [Further Configuration Options](#further-configuration-options)
- [The Commands](#the-commands)
  - [Navigation Commands](#navigation-commands)
  - [Build Commands](#build-commands)
    - [List of Currently Supported Build Commands](#list-of-currently-supported-build-commands)
  - [Other Cool Utilities](#other-cool-utilities)
- [Aliases Glossary](#aliases-glossary)

Welcome to my *DotnetDev* environment to make it easier to work with the runtime
codebase of .NET ([link here](https://github.com/dotnet/runtime)).

It is designed to help with building and navigation without having to type long
commands or changing to super long paths. This custom environment runs on top of
the shell by means of shell functions and aliases, which call into a back-end
written in C#. The main purpose of building a front-end and a back-end is to
provide the flexibility to run the environment on any platform in a transparent
way to the user, i.e. same commands, same workflow, regardless of whether you are
on Linux, MacOS, Windows, etc.

Currently, we have a Bash front-end and a Powershell Core front-end. Both are
expected to work on all platforms, although the general recommendation is to
use the Bash one for Linux and MacOS, and the Powershell one for Windows.

## Requirements

- `Git`
- `.NET 9 version or later`
- `Bash and/or Powershell Core`

## How To Use It

The first step is of course to install the requirements if you haven't done so.
Then, you can clone this repo to your machine.

```bash
git clone https://github.com/ivdiazsa/DotnetDevEnvironment.git
```

Then, source the front-end script you wish to use. For example, for the Bash one:

```bash
source DotnetDevEnvironment/dotnet_dev.sh
```

Sourcing the script will also build the back-end .NET app. If you make changes
and it breaks, then the rest of the environment is not sourced, so it is still
safe to continue working if this happens.

The next step is to tell the environment, where the runtime repo clone you want to
work with is located. We use the `setrepo` command for this:

```bash
setrepo /path/to/dotnet/runtime
```

Setting the repo path fills up a handful of environment variables in the background
that keep the state of the environment, like paths and configuration values. This,
in turn, allows the commands to run where they have to in the intended way. You can
see all these values by looking for the `DOTNET_DEV_*` environment variables.

From here, you are ready to use the environment! There are other things you can
configure, which are detailed in the following section.

### Further Configuration Options

By default, the *DotnetDev* environment sets the Architecture and OS to your machine's.
As for the configuration, it sets it to *Debug*, as per the default on the runtime
repo. However, you can change these values by means of the following commands:

- `setarch`
- `setos`
- `setconfig`

Any of the supported values by the runtime repo is allowed here. When updating
these values, the *DotnetDev* environment will automatically update the paths as
necessary in the background, so you don't have to worry about that.

## The Commands

The following sections detail the commands that are currently supported (more to
come!) and what they do and how they work.

### Navigation Commands

The Navigation Commands provide an interface to quickly move through the most
important places in the codebase. Note that this list is not exhaustive, and
suggestions are welcome for other places that are frequently used in other
workflows, but currently have no shortcut.

- `cdclr`: Changes to the `src/coreclr` directory.
- `cdlibs`: Changes to the `src/libraries` directory.
- `cdmono`: Changes to the `src/mono` directory.
- `cdtests`: Changes to the `src/tests` directory.

- `cdclrbins`: Changes to the `artifacts/bin/coreclr` directory.
- `cdclrtests`: Changes to the `artifacts/tests/coreclr/<os>.<arch>.<config>` directory.
- `cdcoreroot`: Changes to the `CORE_ROOT` directory.

### Build Commands

The Build Commands provide an interface to quickly initiate different kinds of
builds in the runtime repo with short syntax, and from wherever your `PWD` might be.

One of the main benefits that the *DotnetDev* environment provides is that of
full flexibility. The commands are predefined but they also allow you to pass your
own arguments for the build script's command-line in a transparent and seamless
way. You can pass them either directly how you would usually write them when calling
the build script yourself, or you can use the environment's key-value pair notation,
which also has some useful aliases. Or a combination of both.

For instance, let's take the `buildclrlibs` command as an example.

Calling it as is, `buildclrlibs` would call the build script like the following:

```bash
./build.sh -subset clr+libs -arch <arch> -os <os> -configuration <config>
```

However, let's suppose you also want to build the `host` and `packs`, which
currently have no commands here. Let's also suppose you want a CI build, and
libraries in `Release` configuration. You could call `buildclrlibs` like this:

```bash
buildclrlibs set=host+packs libs=rel --ci
```

DotnetDev will understand what you mean and call the build script with the following
command-line:

```bash
./build.sh -subset clr+libs+host+packs -librariesConfiguration Release -ci -arch <arch> -os <os> -configuration <config>
```

You could've also passed the other subsets directly as `-subset host+packs` and/or
the libraries configuration as `-lc Release`, and the end result would've been the
same. DotnetDev aims to provide this flexibility so that you have its commands to
help you, but are not confined to them in any way.

Always make sure to provide the kvp values before the flagged values. It might
work in any order, but that is untested as of this moment. It is part of my
current backlog, so if it doesn't work yet, it will at some point.

It is important to mention that the Kvp Aliases of DotnetDev can be used when
calling both, the main script, and the tests script.

**NOTE:** The flag values `set` and `libs` above are aliases for `subset` and
`librariesConfiguration` respectively. They are available in DotnetDev's Kvp
Notation only. For a full list of the currently supported aliases, check out the
Aliases Glossary at the end of this `README`.

#### List of Currently Supported Build Commands

- `buildclr`: Builds the CLR in the currently set configuration.
- `buildclrdbg`: Builds the CLR in the `Debug` configuration.
- `buildclrchk`: Builds the CLR in the `Checked` configuration.
- `buildclrrel`: Builds the CLR in the `Release` configuration.

- `buildlibs`: Builds the Libraries in the currently set configuration.
- `buildlibsdbg`: Builds the Libraries in the `Debug` configuration.
- `buildlibsrel`: Builds the Libraries in the `Release` configuration.

- `buildclrlibs`: Builds the CLR and the Libraries both in the currently set configuration.
- `buildclrlibsdbg`: Builds the CLR and the Libraries both in the `Debug` configuration.
- `buildclrlibsrel`: Builds the CLR and the Libraries both in the `Release` configuration.

- `buildclrlibschkdbg`: Builds the CLR in `Checked` and the Libraries in `Debug`.
- `buildclrlibsreldbg`: Builds the CLR in `Release` and the Libraries in `Debug`.
- `buildclrlibsdbgrel`: Builds the CLR in `Debug` and the Libraries in `Release`.
- `buildclrlibschkrel`: Builds the CLR in `Checked` and the Libraries in `Release`.

The next eight commands are used to generate the *CORE_ROOT*, using a variety of
possible configurations.

- `gencoreroot`: Uses the CLR in the currently set configuration and Libraries in `Release`.
- `gencorerootdbg`: Uses a CLR `Debug` build and `Release` Libraries.
- `gencorerootchk`: Uses a CLR `Checked` build and `Release` Libraries.
- `gencorerootrel`: Uses a CLR `Release` build and `Release` Libraries.

- `gencorerootlibsdbg`: Uses the CLR in the currently set configuration and Libraries in `Debug`.
- `gencorerootdbglibsdbg`: Uses a CLR `Debug` build and `Debug` Libraries.
- `gencorerootchklibsdbg`: Uses a CLR `Checked` build and `Debug` Libraries.
- `gencorerootrellibsdbg`: Uses a CLR `Release` build and `Debug` Libraries.

### Other Cool Utilities

In addition to all the commands described in the previous sections, DotnetDev also
has a few other neat utilities to help you with your work, which are described
down below.

**WhatIf Preview Mode**

DotnetDev has a command called `whatifpreview`, which serves as a toggle for said
mode. While this mode is activated, DotnetDev will not run any scripts. Instead,
when you call any command, it will display what command-line it would run. This
serves wonderfully when debugging commands or you simply want to know in detail
what exactly a command does.

**Set Core_Root Environment Variable**

DotnetDev already keeps track of the *CORE_ROOT* path for commands like `cdcoreroot`.
However, to not accidentally interfere with your work, it stores said path in its
own environment variable `DOTNET_DEV_COREROOT`. If you want to use it for actual
runtime tests, you can call the `setcorerootenvvar` command to have it set the path
to the `CORE_ROOT` environment variable as well.

Note that DotnetDev only updates its own environment variables when you change
configuration, architecture, repo, os, etc. So, if you want to use a *CORE_ROOT*
with the updated settings, you have to run `setcorerootenvvar` again.

**Call Build Scripts Directly**

The expectation is that DotnetDev's commands would be enough to provide at least
the basis for your workflow. However, if you require to call the build scripts
directly, and build the command-line entirely yourself, you can call the following
commands from anywhere:

- `buildmain`: Script at the runtime repo's root path.
- `buildtests`: Script at `/runtime/src/tests`.

## Aliases Glossary

As mentioned above, the Kvp notation for arguments in the DotnetDev supports
multiple aliases. They are case-insensitive and are described in the list down below.

**Subset**

- `s`
- `set`
- `subset`

**Architecture**

- `a`
- `arch`

**General Configuration**

- `c`
- `config`
- `configuration`

**Libraries Configuration**

- `lc`
- `libs`
- `libsconfig`
- `librariesconfiguration`

**Runtime Configuration**

- `clr`
- `clrconfig`
- `clrconfiguration`
- `rc`
- `runconfig`
- `runtimeconfiguration`

**Host Configuration**

- `hc`
- `hostconfig`
- `hostconfiguration`

As mentioned above in the building section, these aliases can be used transparently
for both, the main script and the tests script.
