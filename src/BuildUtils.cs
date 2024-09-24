// File: BuildUtils.cs

using System;
using System.Collections.Generic;

internal static class BuildUtils
{
    private static HashSet<string> _supportedPlatforms = new HashSet<string>
    {
        "x86",
        "x64",
        "arm",
        "armv6",
        "armel",
        "arm64",
        "loongarch64",
        "riscv64",
        "s390x",
        "ppc64le",
        "wasm"
    };

    private static HashSet<string> _supportedConfigurations = new HashSet<string>
    {
        "debug",
        "checked",
        "release"
    };

    private static HashSet<string> _supportedOperatingSystems = new HashSet<string>
    {
        "windows",
        "osx",
        "linux",
        "freebsd",
        "maccatalyst",
        "tvos",
        "tvossimulator",
        "ios",
        "iossimulator",
        "android",
        "browser",
        "wasi",
        "netbsd",
        "illumos",
        "solaris",
        "linux-musl",
        "linux-bionic",
        "tizen",
        "haiku"
    };

    /// <summary>
    /// </summary>
    /// <returns>
    /// </returns>
    public static bool IsSupportedPlatformValue(string val)
    {
        return _supportedPlatforms.Contains(val.ToLower());
    }

    /// <summary>
    /// </summary>
    /// <returns>
    /// </returns>
    public static bool IsSupportedOSValue(string val)
    {
        return _supportedOperatingSystems.Contains(val.ToLower());
    }

    /// <summary>
    /// The DotnetDev environment supports a wide variety of aliases for some
    /// parameters. However, we settle on one "universal" name for each one
    /// of them, for the purpose of checking for duplicates, as well as passing
    /// the flags with the names the build scripts expect. This function maps
    /// all the aliases we currently support to their "official" counterparts
    /// for the scripts
    /// </summary>
    /// <returns>
    /// Returns a tuple with the normalized version of the parameter, and a flag
    /// showcasing whether said parameter represents a configuration value or not.
    /// </returns>
    public static (string, bool) NormalizeParameter(string receivedParam,
                                                    bool isTestBuild)
    {
        string normalized = string.Empty;
        bool isConfig = false;

        switch (receivedParam)
        {
            case "s":
            case "set":
                normalized = "subset";
                break;

            case "a":
                normalized = "arch";
                break;

            case "c":
            case "config":
            case "configuration":
                normalized = isTestBuild ? "clr" : "configuration";
                isConfig = true;
                break;

            case "lc":
            case "libs":
            case "libsconfig":
            case "librariesconfiguration":
                normalized = isTestBuild ? "libs" : "librariesConfiguration";
                isConfig = true;
                break;

            case "clr":
            case "clrconfig":
            case "clrconfiguration":
            case "rc":
            case "runconfig":
            case "runtimeconfiguration":
                normalized = isTestBuild ? "clr" : "runtimeConfiguration";
                isConfig = true;
                break;

            case "hc":
            case "hostconfig":
            case "hostconfiguration":
                normalized = "hostConfiguration";
                isConfig = true;
                break;

            default:
                normalized = receivedParam;
                break;
        }

        return (normalized, isConfig);
    }

    /// <summary>
    /// Adds the received param/arg kvp to the build arguments dictionary.
    /// </summary>
    /// <remarks>
    /// If the received parameter is a configuration value, it calls a helper
    /// function to map it to its corresponding value the scripts recognize.
    /// If the parameter had already been received prior, then the function
    /// appends the new argument value to the existing one. It is worth noting
    /// that allowing duplicates is only allowed for the main build script.
    /// </remarks>
    public static bool ProcessBuildArgument(string paramName,
                                            string argValue,
                                            Dictionary<string, string> processedArgs,
                                            bool isConfigParam,
                                            bool isTestBuild)
    {
        if (isConfigParam)
            argValue = NormalizeConfigArg(argValue);

        if (!processedArgs.ContainsKey(paramName))
        {
            processedArgs.Add(paramName, argValue);
        }
        else if (isTestBuild)
        {
            return false;
        }
        else if (!processedArgs[paramName].Contains(argValue))
        {
            string valToAppend = paramName == "subset" ? $"+{argValue}" : $",{argValue}";
            processedArgs[paramName] += valToAppend;
        }

        return true;
    }

    /// <summary>
    /// </summary>
    public static void AddDefaultParamsFromEnv(Dictionary<string, string> argsDict,
                                               bool isTestBuild)
    {
        // NOTE: When calling the main build script with only specific configuration
        //       flags, this function ends up also adding the general '-configuration'
        //       one, even though it might not be necessary. Testing on the actual
        //       build, the specific ones seem to take priority over the general one,
        //       which results in the general one being ignored. So, this function
        //       adding it doesn't cause any issues, at least for the time being.
        //       Still, it would be nice to only add it when necessary, perhaps
        //       by looking at the received subset values.

        if (!argsDict.TryGetValue("arch", out string _))
        {
            argsDict.Add("arch", Environment.GetEnvironmentVariable("DOTNET_DEV_ARCH"));
        }

        if (!argsDict.TryGetValue("os", out string _))
        {
            argsDict.Add("os", Environment.GetEnvironmentVariable("DOTNET_DEV_OS"));
        }

        if (isTestBuild && !argsDict.TryGetValue("clr", out string _))
        {
            argsDict.Add("clr", Environment.GetEnvironmentVariable("DOTNET_DEV_CONFIG"));
        }

        if (!isTestBuild && !argsDict.TryGetValue("configuration", out string _))
        {
            argsDict.Add("configuration",
                         Environment.GetEnvironmentVariable("DOTNET_DEV_CONFIG"));
        }
    }

    /// <summary>
    /// Checks whether the received parameter has already been added to either
    /// the build arguments dictionary, or the list of arguments to pass as is
    /// to the script.
    /// </summary>
    /// <remarks>
    /// This check is only used for the tests build script, as the main one does
    /// accept more than one value for a given parameter.
    /// </remarks>
    /// <returns>
    /// Returns 'true' if the given parameter had already been processed before,
    /// and 'false' otherwise.
    /// </returns>
    public static bool IsTestArgDuplicated(string paramName,
                                           string argValue,
                                           Dictionary<string, string> kvpArgs,
                                           List<string> otherArgs)
    {
        return (kvpArgs.ContainsKey(paramName)
                || !string.IsNullOrEmpty(
                    otherArgs.Find(
                        x => x.ToLower().Contains(argValue.ToLower()))));
    }

    /// <summary>
    /// </summary>
    /// <returns>
    /// </returns>
    public static bool IsSupportedConfigurationValue(string val)
    {
        return _supportedConfigurations.Contains(val.ToLower());
    }

    private static string NormalizeConfigArg(string configValue) => configValue switch
    {
        null or "" or "dbg" => "Debug",
        "chk" => "Checked",
        "rel" => "Release",
        _ => configValue,
    };
}
