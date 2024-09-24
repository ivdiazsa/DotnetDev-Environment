// File: Commands.cs

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

public static class DotnetDevCommands
{
    static readonly bool s_isWindows = OperatingSystem.IsWindows();
    static readonly string s_scriptExt = s_isWindows ? ".cmd" : ".sh";

    /// <summary>
    /// Validates the specified repo path exists and calls the appropriate helper
    /// function, depending on the type of build.
    /// </summary>
    /// <returns>
    /// Returns the value received from the helper function, or -1 if the repo path
    ///  was not found or if no build type, or an unrecognized one, was received.
    /// </returns>
    public static int BuildRepo(string[] buildArgs)
    {
        int result = 999;
        string repoPath = Environment.GetEnvironmentVariable("DOTNET_DEV_REPO");

        if (string.IsNullOrEmpty(repoPath))
        {
            Console.WriteLine("BuildRepo: First set the path to where the clone of"
                              + " the runtime repo is located with 'setrepo'.");
            return -1;
        }

        if (buildArgs.Length < 1 || string.IsNullOrWhiteSpace(buildArgs[0]))
        {
            Console.WriteLine("BuildRepo: A build type is required. The currently"
                              + " supported values are 'main' and 'tests'");
            return -1;
        }

        string buildType = buildArgs[0];

        switch (buildType)
        {
            case "main":
                result = BuildMain(repoPath, buildArgs[1..]);
                break;

            case "tests":
                result = BuildTests(repoPath, buildArgs[1..]);
                break;

            default:
                Console.WriteLine($"The build type '{buildType}' was not recognized.");
                result = -1;
                break;
        }

        return result;
    }

    /// <summary>
    /// Parses the incoming arguments to build the runtime repo. It allows them
    /// using a kvp syntax, which also supports easy-to-use aliases for the parameter
    /// names. It also supports receiving dashed arguments and MSBuild arguments,
    /// which are passed directly to the script command-line.
    /// </summary>
    /// <example>
    /// This function also supports repeated arguments using the kvp notation,
    /// the dashed notation, or a combination of both. Let's illustrate this
    /// with an example. Picture the following DotnetDev command-line:
    /// <code>
    /// buildrepo set=clr config=rel config=dbg -subset libs
    /// </code>
    /// Once processed, the command-line for the runtime repo's build script will
    /// have been transformed into one with no duplicates, as it expects it:
    /// <code>
    /// build.sh -subset clr+libs -configuration Release,Debug
    /// </code>
    /// </example>
    /// <returns>
    /// Outputs the full command-line for the shell to consume and use to call the
    /// runtime repo's main build script, and returns 0 if everything went fine.
    /// It returns -1 otherwise.
    /// </returns>
    private static int BuildMain(string repoPath, string[] buildArgs)
    {
        Dictionary<string, string> processedArgs = new();
        List<string> msbuildFlags = new();

        for (int i = 0; i < buildArgs.Length; i++)
        {
            string nextArg = buildArgs[i];

            if (nextArg.StartsWith("-p:") || nextArg.StartsWith("/p:"))
            {
                // If we entered this condition, then this means this argument is
                // meant to be passed as an MSBuild flag. We store these ones
                // separately, because we want to append them at the end of the
                // final command-line.
                msbuildFlags.Add(nextArg);
                continue;
            }

            string[] maybeKvp = nextArg.Split('=');
            string paramName = maybeKvp[0].TrimStart('-').ToLower();
            string argValue = string.Empty;

            if (maybeKvp.Length > 1)
                argValue = maybeKvp[1];
            else
            {
                // If this is the last token, or the next one is also a flag, then
                // that means the current token is a switch flag, and therefore its
                // would-be value is just the empty string.
                string seeAhead = (i + 1) == buildArgs.Length
                                  ? string.Empty
                                  : buildArgs[i + 1];

                if (!seeAhead.StartsWith('-') && !seeAhead.StartsWith('/'))
                {
                    argValue = seeAhead;
                    i++;
                }
            }

            (string normalizedParam, bool isConfigParam) =
                BuildUtils.NormalizeParameter(paramName, isTestBuild: false);

            BuildUtils.ProcessBuildArgument(normalizedParam,
                                            argValue,
                                            processedArgs,
                                            isConfigParam,
                                            isTestBuild: false);
        }

        // Fetch the architecture, OS, and configuration values from the DotnetDev
        // environment if the user didn't pass them.
        BuildUtils.AddDefaultParamsFromEnv(processedArgs, isTestBuild: false);

        string buildScript = Path.Join(repoPath, $"build{s_scriptExt}");
        StringBuilder argsSb = new();

        foreach (KeyValuePair<string, string> argKvp in processedArgs)
        {
            argsSb.Append($" -{argKvp.Key}");

            if (!string.IsNullOrEmpty(argKvp.Value))
                argsSb.Append($" {argKvp.Value}");
        }

        // The reason we are conditioning printing the script args and MSBuild flags
        // is to avoid returning a command-line with trailing spaces in the cases
        // where one or both of those are empty. If anything, for cleanliness.

        Console.Write(buildScript);

        if (argsSb.Length > 0)
            Console.Write($"{argsSb.ToString()}");

        if (msbuildFlags.Count > 0)
            Console.Write($" {string.Join(' ', msbuildFlags)}");

        Console.Write("\n");
        return 0;
    }

    /// <summary>
    /// Parses the incoming arguments to build the coreclr tests. It allows them
    /// using a kvp syntax, which also supports easy-to-use aliases for the parameter
    /// names. It also supports receiving dashed arguments and MSBuild arguments,
    /// which are passed directly to the script command-line.
    /// </summary>
    /// <returns>
    /// Outputs the full command-line for the shell to consume and use to call the
    /// runtime repo's test build script, and returns 0 if everything went fine.
    /// It returns -1 otherwise.
    /// </returns>
    private static int BuildTests(string repoPath, string[] buildArgs)
    {
        Dictionary<string, string> kvpArgs = new();
        List<string> scriptFlags = new();
        List<string> msBuildFlags = new();

        for (int i = 0; i < buildArgs.Length; i++)
        {
            string nextArg = buildArgs[i];

            if (nextArg.StartsWith("-p:") || nextArg.StartsWith("/p:"))
            {
                // If we entered this condition, then this means this argument is
                // meant to be passed as an MSBuild flag. We store these ones
                // separately, because we want to append them at the end of the
                // final command-line.

                msBuildFlags.Add(nextArg);
                continue;
            }

            string paramName = string.Empty;
            string argValue = string.Empty;

            if (nextArg.Contains('='))
            {
                // If we're here, then our next argument is in the DotnetDev's Kvp Form.
                // MSBuild arguments also use a Kvp-like expression, but we already
                // processed them above, so we're sure it's a DotnetDev one here.

                string[] kvp = nextArg.Split('=');

                paramName = kvp[0].ToLower();
                argValue = kvp.Length > 1 ? kvp[1] : "";
            }
            else
            {
                // If we're here, that means we found an argument to pass directly
                // to the tests script command-line directly.

                // However, the tests build script parses the architecture and
                // configuration values as switch flags, instead of the usual
                // flag and value (e.g. for x64 on Checked, the command-line looks
                // like "build.sh -x64 -Checked". So, we have to work around that
                // to avoid potential duplicates.

                argValue = nextArg.TrimStart('-');

                if (BuildUtils.IsSupportedPlatformValue(argValue))
                    paramName = "arch";
                else if (BuildUtils.IsSupportedConfigurationValue(argValue))
                    paramName = "clr";
                else
                {
                    // Not a platform or configuration value, so we can simply add it
                    // as another flag to pass as is to the script.
                    scriptFlags.Add(nextArg);
                    continue;
                }
            }

            (string normalizedParam, bool isConfigParam) =
                BuildUtils.NormalizeParameter(paramName, isTestBuild: true);

            if (!BuildUtils.ProcessBuildArgument(normalizedParam,
                                                 argValue,
                                                 kvpArgs,
                                                 isConfigParam,
                                                 isTestBuild: true))
            {
                Console.WriteLine($"BuildTests: Only one '{normalizedParam}' value"
                                  + " should be specified.");
                return -1;
            }
        }

        // Fetch the architecture, OS, and configuration values from the DotnetDev
        // environment if the user didn't pass them.
        BuildUtils.AddDefaultParamsFromEnv(kvpArgs, isTestBuild: true);

        // Build the command-line here: Note that we need to handle the special
        // cases for the architecture and clr configuration, since those don't
        // work with dashes '-' on Windows.

        string testsScript = Path.Join(repoPath, "src", "tests", $"build{s_scriptExt}");
        StringBuilder kvpArgsSb = new();

        foreach (KeyValuePair<string, string> argKvp in kvpArgs)
        {
            if (argKvp.Key == "arch" || argKvp.Key == "clr")
            {
                kvpArgsSb.AppendFormat(" {0}", s_isWindows
                                               ? argKvp.Value
                                               : $"-{argKvp.Value}");
                continue;
            }
            else if (argKvp.Key == "libs")
            {
                msBuildFlags.Add($"/p:LibrariesConfiguration={argKvp.Value}");
                continue;
            }

            kvpArgsSb.Append($" -{argKvp.Key}");

            // Flags with values are separated by spaces on Windows, and colons ':'
            // in all the other platforms. The exception to this rule is the '-os'
            // flag. This one is separated by a space regardless of platform.

            if (!string.IsNullOrEmpty(argKvp.Value))
            {
                kvpArgsSb.AppendFormat("{0}{1}",
                                       (s_isWindows || argKvp.Key == "os") ? " " : ":",
                                       argKvp.Value);
            }
        }

        // The reason we are conditioning printing the script args and MSBuild flags
        // is to avoid returning a command-line with trailing spaces in the cases
        // where one or both of those are empty. If anything, for cleanliness.

        Console.Write(testsScript);

        if (kvpArgsSb.Length > 0)
            Console.Write($"{kvpArgsSb.ToString()}");

        if (scriptFlags.Count > 0)
            Console.Write($" {string.Join(' ', scriptFlags)}");

        if (msBuildFlags.Count > 0)
            Console.Write($" {string.Join(' ', msBuildFlags)}");

        Console.Write("\n");
        return 0;
    }
}
