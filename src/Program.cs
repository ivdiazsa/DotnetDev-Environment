// File: Program.cs

using System;

public class Program
{
    static int Main(string[] args)
    {
        if (args.Length == 0 || string.IsNullOrWhiteSpace(args[0]))
        {
            Console.WriteLine("DotnetDev: A command is required to run.");
            return -1;
        }

        string cmd = args[0];
        string[] cmdArgs = args[1..];
        int exitCode = 999;

        switch (cmd)
        {
            case "getos":
                exitCode = DotnetDevSetup.GetOperatingSystem();
                break;

            case "getarch":
                exitCode = DotnetDevSetup.GetArchitecture();
                break;

            case "setrepo":
                exitCode = DotnetDevSetup.SetRepo(cmdArgs);
                break;

            case "setos":
                exitCode = DotnetDevSetup.SetOS(cmdArgs);
                break;

            case "setarch":
                exitCode = DotnetDevSetup.SetArch(cmdArgs);
                break;

            case "setconfig":
                exitCode = DotnetDevSetup.SetConfig(cmdArgs);
                break;

            case "build":
                exitCode = DotnetDevCommands.BuildRepo(cmdArgs);
                break;

            default:
                Console.WriteLine($"Apologies, but the command '{cmd}' isn't available yet.");
                exitCode = -1;
                break;
        }

        return exitCode;
    }
}
