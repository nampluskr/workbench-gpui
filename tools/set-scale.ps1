#Requires -Version 7
<#
.SYNOPSIS
  주 모니터의 Windows 디스플레이 배율을 읽거나 바꾼다 (SPEC R-4·R-5 배율 시험용).

.DESCRIPTION
  문서화되지 않은 DisplayConfigGetDeviceInfo / DisplayConfigSetDeviceInfo 의 DPI scale 타입을 쓰는
  알려진 방식이다.
  - 타입 -3 (DISPLAYCONFIG_DEVICE_INFO_GET_DPI_SCALE): min·cur·max 를 "추천 배율 기준 상대 인덱스"로 준다.
  - 타입 -4 (DISPLAYCONFIG_DEVICE_INFO_SET_DPI_SCALE): 추천 배율 기준 상대 인덱스로 배율을 정한다.
  - 배율 목록: 100,125,150,175,200,225,250,300,350,400,450,500.
    추천 = 목록[|min|], 현재 = 목록[|min| + cur], 최대 = 목록[|min| + max], 최소 = 목록[0] = 100.
  주 모니터는 GetMonitorInfo(MONITORINFOF_PRIMARY)의 장치 이름(\\.\DISPLAYn)과
  DISPLAYCONFIG_SOURCE_DEVICE_NAME 의 GDI 장치 이름을 맞춰 고른다.

  이 스크립트는 시스템 설정을 바꾼다. 사용자 허락 없이 실행하지 않는다.
  외부 모듈 없이 Add-Type(C# P/Invoke)만 쓴다.

  출력은 JSON 이다. -Percent 로 바꾼 뒤에는 이 프로세스 안의 값이 아니라 새 pwsh 프로세스에서
  -Get 으로 다시 읽은 값을 after 에 넣는다. 결과가 요청과 다르거나 실패하면 종료 코드 1 이다.

.PARAMETER Percent
  바꿀 배율: 100, 125, 150, 175, 200.

.PARAMETER Get
  바꾸지 않고 현재·추천·최소·최대 배율만 낸다.

.EXAMPLE
  pwsh -NoProfile -File tools/set-scale.ps1 -Get
.EXAMPLE
  pwsh -NoProfile -File tools/set-scale.ps1 -Percent 150
#>
[CmdletBinding(DefaultParameterSetName = 'Get')]
param(
    [Parameter(ParameterSetName = 'Set', Mandatory = $true)]
    [ValidateSet(100, 125, 150, 175, 200)]
    [int]$Percent,

    [Parameter(ParameterSetName = 'Get')]
    [switch]$Get
)

$ErrorActionPreference = 'Stop'

if (-not ('WgScale.Native' -as [type])) {
    Add-Type -ReferencedAssemblies 'System.Runtime', 'System.Runtime.InteropServices' -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace WgScale
{
    [StructLayout(LayoutKind.Sequential)]
    public struct LUID { public uint LowPart; public int HighPart; }

    [StructLayout(LayoutKind.Sequential)]
    public struct PATH_SOURCE_INFO { public LUID adapterId; public uint id; public uint modeInfoIdx; public uint statusFlags; }

    [StructLayout(LayoutKind.Sequential)]
    public struct RATIONAL { public uint Numerator; public uint Denominator; }

    [StructLayout(LayoutKind.Sequential)]
    public struct PATH_TARGET_INFO
    {
        public LUID adapterId; public uint id; public uint modeInfoIdx;
        public int outputTechnology; public int rotation; public int scaling;
        public RATIONAL refreshRate; public int scanLineOrdering; public int targetAvailable; public uint statusFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PATH_INFO { public PATH_SOURCE_INFO sourceInfo; public PATH_TARGET_INFO targetInfo; public uint flags; }

    [StructLayout(LayoutKind.Sequential)]
    public struct MODE_INFO
    {
        public int infoType; public uint id; public LUID adapterId;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 48)] public byte[] info;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DEVICE_INFO_HEADER { public int type; public uint size; public LUID adapterId; public uint id; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SOURCE_DEVICE_NAME
    {
        public DEVICE_INFO_HEADER header;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string viewGdiDeviceName;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DPI_SCALE_GET { public DEVICE_INFO_HEADER header; public int minScaleRel; public int curScaleRel; public int maxScaleRel; }

    [StructLayout(LayoutKind.Sequential)]
    public struct DPI_SCALE_SET { public DEVICE_INFO_HEADER header; public int scaleRel; }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct MONITORINFOEX
    {
        public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string szDevice;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }

    public class ScaleInfo
    {
        public string Device;
        public int MinRel, CurRel, MaxRel;
        public int Current, Recommended, Minimum, Maximum;
    }

    public static class Native
    {
        const uint QDC_ONLY_ACTIVE_PATHS = 2;
        const int TYPE_GET_SOURCE_NAME = 1;
        const int TYPE_GET_DPI_SCALE = -3;
        const int TYPE_SET_DPI_SCALE = -4;
        const uint MONITOR_DEFAULTTOPRIMARY = 1;

        public static readonly int[] Scales = { 100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500 };

        [DllImport("user32.dll")] static extern int GetDisplayConfigBufferSizes(uint flags, out uint numPaths, out uint numModes);
        [DllImport("user32.dll")] static extern int QueryDisplayConfig(uint flags, ref uint numPaths, [Out] PATH_INFO[] paths, ref uint numModes, [Out] MODE_INFO[] modes, IntPtr topology);
        [DllImport("user32.dll", EntryPoint = "DisplayConfigGetDeviceInfo")] static extern int GetName(ref SOURCE_DEVICE_NAME req);
        [DllImport("user32.dll", EntryPoint = "DisplayConfigGetDeviceInfo")] static extern int GetScale(ref DPI_SCALE_GET req);
        [DllImport("user32.dll", EntryPoint = "DisplayConfigSetDeviceInfo")] static extern int SetScale(ref DPI_SCALE_SET req);
        [DllImport("user32.dll")] static extern IntPtr MonitorFromPoint(POINT pt, uint flags);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool GetMonitorInfo(IntPtr hMon, ref MONITORINFOEX mi);

        static string PrimaryDevice()
        {
            var mi = new MONITORINFOEX();
            mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
            if (!GetMonitorInfo(MonitorFromPoint(new POINT { X = 0, Y = 0 }, MONITOR_DEFAULTTOPRIMARY), ref mi))
                throw new InvalidOperationException("GetMonitorInfo failed");
            return mi.szDevice;
        }

        // 주 모니터에 해당하는 활성 경로의 소스(adapterId, id)를 찾는다.
        static PATH_SOURCE_INFO PrimarySource(out string device)
        {
            device = PrimaryDevice();
            uint np, nm;
            int rc = GetDisplayConfigBufferSizes(QDC_ONLY_ACTIVE_PATHS, out np, out nm);
            if (rc != 0) throw new InvalidOperationException("GetDisplayConfigBufferSizes failed: " + rc);
            var paths = new PATH_INFO[np];
            var modes = new MODE_INFO[nm];
            rc = QueryDisplayConfig(QDC_ONLY_ACTIVE_PATHS, ref np, paths, ref nm, modes, IntPtr.Zero);
            if (rc != 0) throw new InvalidOperationException("QueryDisplayConfig failed: " + rc);
            for (int i = 0; i < np; i++)
            {
                var req = new SOURCE_DEVICE_NAME();
                req.header.type = TYPE_GET_SOURCE_NAME;
                req.header.size = (uint)Marshal.SizeOf(typeof(SOURCE_DEVICE_NAME));
                req.header.adapterId = paths[i].sourceInfo.adapterId;
                req.header.id = paths[i].sourceInfo.id;
                if (GetName(ref req) == 0 && string.Equals(req.viewGdiDeviceName, device, StringComparison.OrdinalIgnoreCase))
                    return paths[i].sourceInfo;
            }
            throw new InvalidOperationException("primary display path not found: " + device);
        }

        public static ScaleInfo Read()
        {
            string device;
            var src = PrimarySource(out device);
            var req = new DPI_SCALE_GET();
            req.header.type = TYPE_GET_DPI_SCALE;
            req.header.size = (uint)Marshal.SizeOf(typeof(DPI_SCALE_GET));
            req.header.adapterId = src.adapterId;
            req.header.id = src.id;
            int rc = GetScale(ref req);
            if (rc != 0) throw new InvalidOperationException("DisplayConfigGetDeviceInfo(GET_DPI_SCALE) failed: " + rc);

            int baseIdx = Math.Abs(req.minScaleRel);
            Func<int, int> at = idx =>
            {
                if (idx < 0 || idx >= Scales.Length) throw new InvalidOperationException("scale index out of range: " + idx);
                return Scales[idx];
            };
            return new ScaleInfo
            {
                Device = device,
                MinRel = req.minScaleRel, CurRel = req.curScaleRel, MaxRel = req.maxScaleRel,
                Current = at(baseIdx + req.curScaleRel),
                Recommended = at(baseIdx),
                Minimum = at(0),
                Maximum = at(baseIdx + req.maxScaleRel),
            };
        }

        public static void Write(int percent)
        {
            var info = Read();
            int target = Array.IndexOf(Scales, percent);
            if (target < 0) throw new ArgumentException("unsupported scale: " + percent);
            int rel = target - Math.Abs(info.MinRel);
            if (rel < info.MinRel || rel > info.MaxRel)
                throw new ArgumentOutOfRangeException("percent", percent + "% is outside " + info.Minimum + "%.." + info.Maximum + "% for " + info.Device);

            string device;
            var src = PrimarySource(out device);
            var req = new DPI_SCALE_SET();
            req.header.type = TYPE_SET_DPI_SCALE;
            req.header.size = (uint)Marshal.SizeOf(typeof(DPI_SCALE_SET));
            req.header.adapterId = src.adapterId;
            req.header.id = src.id;
            req.scaleRel = rel;
            int rc = SetScale(ref req);
            if (rc != 0) throw new InvalidOperationException("DisplayConfigSetDeviceInfo(SET_DPI_SCALE) failed: " + rc);
        }
    }
}
'@
}

function ConvertTo-ScaleObject($info) {
    [ordered]@{
        device      = $info.Device
        current     = $info.Current
        recommended = $info.Recommended
        minimum     = $info.Minimum
        maximum     = $info.Maximum
        relative    = [ordered]@{ min = $info.MinRel; cur = $info.CurRel; max = $info.MaxRel }
    }
}

if ($PSCmdlet.ParameterSetName -eq 'Get') {
    try {
        ConvertTo-ScaleObject ([WgScale.Native]::Read()) | ConvertTo-Json -Depth 3
        exit 0
    } catch {
        [ordered]@{ ok = $false; error = $_.Exception.Message } | ConvertTo-Json
        exit 1
    }
}

$result = [ordered]@{
    requested = $Percent
    before    = $null
    after     = $null
    ok        = $false
    error     = $null
}
try {
    $result.before = ConvertTo-ScaleObject ([WgScale.Native]::Read())
    [WgScale.Native]::Write($Percent)
    Start-Sleep -Milliseconds 1500

    # 새 프로세스에서 다시 읽는다 (이 프로세스의 DPI 상태와 무관하게 확인).
    $raw = & pwsh -NoProfile -File $PSCommandPath -Get
    if ($LASTEXITCODE -ne 0) { throw "새 프로세스에서 배율을 다시 읽지 못했다: $($raw | Out-String)" }
    $result.after = ($raw | Out-String) | ConvertFrom-Json
    if ($result.after.current -ne $Percent) {
        throw "배율이 바뀌지 않았다: 요청 $Percent%, 다시 읽은 값 $($result.after.current)%"
    }
    $result.ok = $true
} catch {
    $result.error = $_.Exception.Message
}

$result | ConvertTo-Json -Depth 4
if (-not $result.ok) { exit 1 }
