using System.Diagnostics;
using System.Reflection;
using System.Runtime.CompilerServices;
using HASS.Agent.Shared.Managers.Audio;
using HASS.Agent.Shared.Managers.Audio.Internal;

// Run with: dotnet run --project tests/HASS.Agent.Audio.RegressionTests
// Test the real name resolver without requiring an audio device or adding production hooks.
// Device enumeration and Home Assistant reporting still require an integration check.
if (args.Contains("--child"))
    return 0;

try
{
    var startInfo = new ProcessStartInfo(Environment.ProcessPath!) { UseShellExecute = false };
    if (Path.GetFileNameWithoutExtension(Environment.ProcessPath) == "dotnet")
        startInfo.ArgumentList.Add(Assembly.GetExecutingAssembly().Location);
    startInfo.ArgumentList.Add("--child");

    using var exitedProcess = Process.Start(startInfo)!;
    var exitedProcessId = exitedProcess.Id;
    if (!exitedProcess.WaitForExit(10000))
    {
        exitedProcess.Kill();
        throw new Exception("The regression fixture process did not exit within 10 seconds.");
    }

    // Confirm the fixture exercises the same Process API failure as a stale audio session.
    try
    {
        using var unexpectedProcess = Process.GetProcessById(exitedProcessId);
        throw new Exception("The fixture process ID is still present; cannot reproduce an exited process.");
    }
    catch (ArgumentException)
    {
    }

    AssertName("exited process with an empty session name", exitedProcessId, "", "");
    AssertName("exited process with a fallback session name", exitedProcessId, "Session", "Session");

    using var currentProcess = Process.GetCurrentProcess();
    AssertName("live process", currentProcess.Id, "", currentProcess.ProcessName);
    AssertName("cached live process", currentProcess.Id, "", currentProcess.ProcessName);
    AssertName("session without a process", 0, "System Sounds", "System Sounds");
    Console.WriteLine("PASS: all audio session name regression checks.");
    return 0;
}
catch (Exception exception)
{
    Console.Error.WriteLine($"FAIL: {exception}");
    return 1;
}

static void AssertName(string scenario, int processId, string displayName, string expected)
{
    // InternalAudioSession normally reads COM state in its constructor. This check only
    // supplies its captured process ID and display name, so no audio hardware is needed.
    var session = (InternalAudioSession)RuntimeHelpers.GetUninitializedObject(typeof(InternalAudioSession));
    GC.SuppressFinalize(session);
    typeof(InternalAudioSession).GetField("<ProcessId>k__BackingField", BindingFlags.Instance | BindingFlags.NonPublic)!
        .SetValue(session, processId);
    typeof(InternalAudioSession).GetField("<DisplayName>k__BackingField", BindingFlags.Instance | BindingFlags.NonPublic)!
        .SetValue(session, displayName);

    var resolver = typeof(AudioManager).GetMethod("GetSessionDisplayName", BindingFlags.Static | BindingFlags.NonPublic)!;
    string actual;
    try
    {
        actual = (string)resolver.Invoke(null, new object[] { session })!;
    }
    catch (TargetInvocationException exception)
    {
        throw new Exception($"{scenario} should not interrupt audio enumeration.", exception.InnerException);
    }

    if (actual != expected)
        throw new Exception($"{scenario}: expected '{expected}', received '{actual}'.");

    Console.WriteLine($"PASS: {scenario}");
}
