Add-Type -AssemblyName System.Management

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class DisplayControl
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public int dmFields, dmPositionX, dmPositionY;
        public int dmDisplayOrientation, dmDisplayFixedOutput;
        public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;

        public short dmLogPixels;
        public int dmBitsPerPel, dmPelsWidth, dmPelsHeight;
        public int dmDisplayFlags, dmDisplayFrequency;
        public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType;
        public int dmReserved1, dmReserved2;
        public int dmPanningWidth, dmPanningHeight;
    }

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    [DllImport("kernel32.dll")]
    static extern bool GetSystemPowerStatus(ref SYSTEM_POWER_STATUS status);

    [StructLayout(LayoutKind.Sequential)]
    struct SYSTEM_POWER_STATUS
    {
        public byte ACLineStatus;
        public byte BatteryFlag;
        public byte BatteryLifePercent;
        public byte Reserved;
        public int BatteryLifeTime;
        public int BatteryFullLifeTime;
    }

    public static bool IsAC()
    {
        SYSTEM_POWER_STATUS status = new SYSTEM_POWER_STATUS();
        GetSystemPowerStatus(ref status);
        return status.ACLineStatus == 1;
    }

    public static void SetRefreshRate(int hz)
    {
        DEVMODE mode = new DEVMODE();
        mode.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));

        mode.dmPelsWidth = 1920;
        mode.dmPelsHeight = 1080;
        mode.dmBitsPerPel = 32;
        mode.dmDisplayFrequency = hz;

        mode.dmFields =
            0x00080000 |
            0x00100000 |
            0x00040000 |
            0x00400000;

        ChangeDisplaySettings(ref mode, 0);
    }
}
"@

function Set-CorrectRefreshRate {
    if ([DisplayControl]::IsAC()) {
        [DisplayControl]::SetRefreshRate(144)
    }
    else {
        [DisplayControl]::SetRefreshRate(60)
    }
}

# Set the correct rate immediately when the watcher starts
Set-CorrectRefreshRate

# Watch Windows power-management events
$query = New-Object System.Management.WqlEventQuery
$query.QueryString = "SELECT * FROM Win32_PowerManagementEvent WHERE EventType = 10"

$watcher = New-Object System.Management.ManagementEventWatcher
$watcher.Query = $query
$watcher.Scope = New-Object System.Management.ManagementScope("\\.\root\cimv2")

$watcher.Start()

try {
    while ($true) {
        # Wait for a power-status-change event
        $event = $watcher.WaitForNextEvent()

        # Immediately update refresh rate
        Set-CorrectRefreshRate
    }
}
finally {
    $watcher.Stop()
    $watcher.Dispose()
}