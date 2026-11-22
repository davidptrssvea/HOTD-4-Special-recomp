using System;
using System.IO;

internal static class LauncherLogTests
{
    private static void Check(bool success, string reason)
    {
        if (!success) throw new Exception(reason);
    }

    private static int Main()
    {
        string root = Path.Combine(Path.GetTempPath(), "hotd4-launcher-log-test-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            string original = "ROOT CAUSE: original diagnostic\r\n" + new string('x', 20000) + "\r\nEND: exit 49\r\n";
            string log = Launcher.SaveErrorLog(root, "HOTD4", original, 49);
            Check(log != null && File.Exists(log), "Missing full error report");
            string saved = File.ReadAllText(log);
            Check(saved.EndsWith(original), "Full original error must be retained without truncation");
            Check(saved.Contains("Exit code: 49"), "Exit code must be recorded");
            string message = Launcher.FormatError(original, 49, log);
            Check(message.Contains("ROOT CAUSE") && message.Contains("END: exit 49") && message.Contains(log), "Dialog must show context and report location");
            Check(message.Length < 1800, "Dialog must remain bounded");
            string second = Launcher.SaveErrorLog(root, "HOTD4", "another failure", 1);
            Check(second != log && File.ReadAllText(log) == saved, "Reports must not overwrite earlier failures");
            Check(Launcher.FormatError("", 49, null).Contains("49"), "Empty errors need an exit-code fallback");
            string blocked = Path.Combine(root, "not-a-directory");
            File.WriteAllText(blocked, "fixture");
            Check(Launcher.SaveErrorLog(blocked, "HOTD4", original, 49) == null, "Unwritable reports must not hide the original failure");
            Console.WriteLine("Launcher error reports passed: full text, exit code, bounded dialog, unique files and write-failure fallback.");
            return 0;
        }
        finally
        {
            string fullRoot = Path.GetFullPath(root);
            string temp = Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar);
            Check(String.Equals(Path.GetDirectoryName(fullRoot), temp, StringComparison.OrdinalIgnoreCase) &&
                Path.GetFileName(fullRoot).StartsWith("hotd4-launcher-log-test-", StringComparison.Ordinal),
                "Cleanup must stay within this test's temporary directory");
            Directory.Delete(root, true);
        }
    }
}
