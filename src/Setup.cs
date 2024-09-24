// File: Setup.cs

using System;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;

public static class DotnetDevSetup
{
    /// <summary>
    /// Checks which operating system the DotnetDev is currently running on.
    /// </summary>
    /// <returns>
    /// Outputs the operating system's name in lowercase, as recognized by the
    /// runtime repo, for the shell to consume and set, and returns 0.
    /// </returns>
    public static int GetOperatingSystem()
    {
        if (OperatingSystem.IsLinux())
        {
            Console.WriteLine("linux");
        }
        else if (OperatingSystem.IsMacOS())
        {
            Console.WriteLine("osx");
        }
        else if (OperatingSystem.IsWindows())
        {
            Console.WriteLine("windows");
        }
        else
        {
            Console.WriteLine("GetOperatingSystem: The detected operating system"
                              + " was not Linux, Mac, or Windows.");
            return -1;
        }

        return 0;
    }

    /// <summary>
    /// Checks what architecture is the system where the DotnetDev is currently
    /// running on.
    /// </summary>
    /// <returns>
    /// Outputs the hardware's architecture name in lowercase, as recognized by
    /// the runtime repo, for the shell to consume and set, and returns 0.
    /// </returns>
    public static int GetArchitecture()
    {
        Architecture systemArch = RuntimeInformation.OSArchitecture;
        Console.WriteLine(systemArch.ToString().ToLower());
        return 0;
    }

    /// <summary>
    /// Processes and validates the path of the runtime repo clone the user wants
    /// to work on.
    /// </summary>
    /// <returns>
    /// Outputs the full path to the given clone of the runtime repo for the shell
    /// to consume and set, and returns 0 if everything goes fine, and -1 otherwise.
    /// </returns>
    public static int SetRepo(string[] cmdArgs)
    {
        if (cmdArgs.Length < 1 || string.IsNullOrWhiteSpace(cmdArgs[0]))
        {
            Console.WriteLine("SetRepo: A path to the runtime repo is required.");
            return -1;
        }

        string repoPath = cmdArgs[0];

        if (!Directory.Exists(repoPath))
        {
            Console.WriteLine("SetRepo: The given path '{0}' was unfortunately not found.",
                              repoPath);
            return -1;
        }

        string repoAbsolutePath = Path.GetFullPath(repoPath);
        Console.WriteLine(Path.TrimEndingDirectorySeparator(repoAbsolutePath));
        return 0;
    }

    /// <summary>
    /// Processes and validates the new operating system value that the user wants
    /// to set to the DOTNET_DEV_OS environment variable.
    /// </summary>
    /// <returns>
    /// Outputs the new OS in lowercase for the shell to consume and set.
    /// Returns 0 if everything went fine, and -1 otherwise.
    /// </returns>
    public static int SetOS(string[] cmdArgs)
    {
        if (cmdArgs.Length < 1 || string.IsNullOrWhiteSpace(cmdArgs[0]))
        {
            Console.WriteLine("SetOS: An operating system name is required as argument.");
            return -1;
        }

        string newOS = cmdArgs[0].ToLower();

        if (!BuildUtils.IsSupportedOSValue(newOS))
        {
            Console.WriteLine("SetOS: The OS value '{0}' is not supported.",
                              newOS);
            return -1;
        }

        Console.WriteLine(newOS);
        return 0;
    }

    /// <summary>
    /// Processes and validates the new architecture value that the user wants
    /// to set to the DOTNET_DEV_ARCH environment variable.
    /// </summary>
    /// <returns>
    /// Outputs the new architecture in lowercase for the shell to consume and set.
    /// Returns 0 if everything went fine, and -1 otherwise.
    /// </returns>
    public static int SetArch(string[] cmdArgs)
    {
        if (cmdArgs.Length < 1 || string.IsNullOrWhiteSpace(cmdArgs[0]))
        {
            Console.WriteLine("SetArch: An architecture name is required as argument.");
            return -1;
        }

        string newArch = cmdArgs[0].ToLower();

        if (!BuildUtils.IsSupportedPlatformValue(newArch))
        {
            Console.WriteLine("SetArch: The architecture value '{0}' is not supported.",
                              newArch);
            return -1;
        }

        Console.WriteLine(newArch);
        return 0;
    }

    /// <summary>
    /// Processes and validates the new configuration value that the user wants
    /// to set to the DOTNET_DEV_CONFIG environment variable.
    /// </summary>
    /// <returns>
    /// Outputs the new configuration in titlecase for the shell to consume and set.
    /// Returns 0 if everything went fine, and -1 otherwise.
    /// </returns>
    public static int SetConfig(string[] cmdArgs)
    {
        if (cmdArgs.Length < 1 || string.IsNullOrWhiteSpace(cmdArgs[0]))
        {
            Console.WriteLine("SetConfig: A configuration name is required as argument.");
            return -1;
        }

        string newConfig = cmdArgs[0].ToLower();

        switch (newConfig)
        {
            case "dbg":
            case "debug":
                Console.WriteLine("Debug");
                break;

            case "chk":
            case "checked":
                Console.WriteLine("Checked");
                break;

            case "rel":
            case "release":
                Console.WriteLine("Release");
                break;

            default:
                Console.WriteLine("SetConfig: You have to pick one of the following"
                                  + " three: Debug, Checked, Release.");
                return -1;
        }

        return 0;
    }
}
