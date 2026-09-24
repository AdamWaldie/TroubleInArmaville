param(
    [Parameter(Mandatory = $true)]
    [int]$ProcessId,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
if (-not ("TttQaWindowCapture" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class TttQaWindowCapture {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint flags);
    [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr context);
}
"@
}

[TttQaWindowCapture]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null
Add-Type -AssemblyName System.Drawing
$process = Get-Process -Id $ProcessId -ErrorAction Stop
$process.Refresh()
if ($process.ProcessName -ne "arma3_x64" -or $process.MainWindowHandle -eq 0) {
    throw "Process $ProcessId is not a visible Arma 3 client window."
}

[TttQaWindowCapture]::ShowWindowAsync($process.MainWindowHandle, 9) | Out-Null
[TttQaWindowCapture]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 250
$rect = New-Object TttQaWindowCapture+RECT
if (-not [TttQaWindowCapture]::GetWindowRect($process.MainWindowHandle, [ref]$rect)) {
    throw "Could not read Arma 3 window bounds."
}
$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
[TttQaWindowCapture]::SetCursorPos($rect.Left + 8, $rect.Top + 8) | Out-Null
# Match the proven WMP capture path: DirectX needs a complete compositor frame
# after the window is restored/foregrounded. Without this settle, PrintWindow
# can return a valid PNG containing only some controls from the current frame.
Start-Sleep -Milliseconds 1200
$bitmap = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
    # Capture the frame Windows actually presented. PrintWindow can return a
    # syntactically valid but mixed/partial DirectX frame for Arma (some text
    # and controls come from different render passes), which is unusable as
    # localisation evidence even though the PNG itself opens normally.
    $copySize = New-Object System.Drawing.Size $width, $height
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $copySize, [System.Drawing.CopyPixelOperation]::SourceCopy)
    $absolute = [System.IO.Path]::GetFullPath($OutputPath)
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($absolute)) | Out-Null
    $bitmap.Save($absolute, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $absolute
} finally {
    $graphics.Dispose()
    $bitmap.Dispose()
}
