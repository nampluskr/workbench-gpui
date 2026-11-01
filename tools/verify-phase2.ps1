#Requires -Version 7
<#
.SYNOPSIS
  PLAN Phase 2 (SPEC R-7·R-8·R-9·R-10) 증거를 specs/v0.1/verify/phase2/ 에 모은다.

.DESCRIPTION
  앱(디버그 빌드)을 `--dev-editor-poc` 계열 플래그로 단계마다 새로 띄우고, 표준출력과 스크린샷을 저장한 뒤 닫는다.
  시작 전에 workbench-gpui 가 이미 실행 중이면 오류로 끝낸다(다른 프로세스는 건드리지 않는다).
  스크린샷은 스크립트가 띄운 PID 의 창 HWND 를 capture.ps1 -Hwnd 로 넘겨 찍는다.

    r7   기본 PoC 화면 (줄 번호, 들여쓰기 안내선, 한글 표시)              → r7-editor.png
    r8   5만·10만 줄 파일 열기·스크롤·입력 → 다음 프레임 시간(--dev-perf)   → r8-*.txt, r8-perf[-<Tag>].json, r8-*-after.png
         -Tag 로 빌드 종류(debug, opt)를 결과 이름에 붙인다.
         측정 파일은 target\phase2-data\ 에 만들고 커밋하지 않는다.
    r9   CRLF·UTF-16 LE·CP949 파일을 naive·app 두 방식으로 열기→저장, 바이트 비교 → r9\, r9-roundtrip.json
    r10  한글 혼합 줄·영문 줄 측정(--dev-measure) + 스크린샷 픽셀로 잉크 아래 끝(기준선)·폭  → r10-*.txt, r10-measure.png, r10-pixels.json

.PARAMETER Steps
  실행할 단계. 기본 r7,r8,r9,r10.

.EXAMPLE
  pwsh -NoProfile -File tools/verify-phase2.ps1
.EXAMPLE
  pwsh -NoProfile -File tools/verify-phase2.ps1 -Steps r9
#>
[CmdletBinding()]
param(
    [string]$Exe = 'target\debug\workbench-gpui.exe',
    [string]$OutDir = 'specs\v0.1\verify\phase2',
    # pwsh -File 로 부르면 배열 인자가 한 문자열로 오므로 쉼표로 나눈다.
    [string]$Steps = 'r7,r8,r9,r10',
    # r8 결과 파일 이름에 붙일 꼬리표 (예: debug, opt). 빌드 종류별 결과를 따로 남길 때 쓴다.
    [string]$Tag = ''
)

$ErrorActionPreference = 'Stop'
$StepList = @($Steps -split '[,\s]+' | Where-Object { $_ })
foreach ($s in $StepList) { if ($s -notin 'r7', 'r8', 'r9', 'r10') { throw "알 수 없는 단계: $s (r7, r8, r9, r10)" } }
$ProcessName = 'workbench-gpui'
$AppTitle = 'workbench-gpui'
$CaptureScript = Join-Path $PSScriptRoot 'capture.ps1'

Add-Type -AssemblyName System.Drawing.Common
Add-Type -AssemblyName System.Drawing.Primitives

if (-not ('WgPhase2.Native' -as [type])) {
    $refs = @(
        'System.Runtime'
        'System.Collections'
        'System.Runtime.InteropServices'
        'System.Drawing.Common'
        'System.Drawing.Primitives'
        'System.ComponentModel.Primitives'
    )
    $drawingDir = [System.IO.Path]::GetDirectoryName([System.Drawing.Bitmap].Assembly.Location)
    foreach ($n in 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core') {
        $p = Join-Path $drawingDir "$n.dll"
        if (Test-Path -LiteralPath $p) { $refs += $p }
    }
    Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Text;

namespace WgPhase2
{
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    public static class Native
    {
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
        [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
        [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);

        public static string Title(IntPtr h)
        {
            var sb = new StringBuilder(512);
            GetWindowText(h, sb, sb.Capacity);
            return sb.ToString();
        }

        // 프로세스의 보이는 소유자 없는 최상위 창 중 제목이 title 인 가장 큰 창.
        public static IntPtr FindTitled(uint pid, string title)
        {
            IntPtr best = IntPtr.Zero; long bestArea = 0;
            EnumWindows((h, l) =>
            {
                uint p;
                GetWindowThreadProcessId(h, out p);
                if (p != pid || !IsWindowVisible(h) || GetWindow(h, 4) != IntPtr.Zero) return true;
                if (Title(h) != title) return true;
                RECT r; GetWindowRect(h, out r);
                long area = (long)(r.Right - r.Left) * (r.Bottom - r.Top);
                if (area > bestArea) { bestArea = area; best = h; }
                return true;
            }, IntPtr.Zero);
            return best;
        }

        static int Diff(Color a, Color b)
        {
            return Math.Abs(a.R - b.R) + Math.Abs(a.G - b.G) + Math.Abs(a.B - b.B);
        }

        // 사각형 안에서 배경색 bg 와 차이(채널 합)가 threshold 보다 큰 픽셀(잉크)의 범위.
        // 결과: [minX, minY, maxX, maxY, count]. 잉크가 없으면 count = 0.
        public static int[] InkBox(string path, int x, int y, int w, int h, int bgX, int bgY, int threshold)
        {
            using (var bmp = new Bitmap(path))
            {
                var bg = bmp.GetPixel(Math.Min(Math.Max(bgX, 0), bmp.Width - 1), Math.Min(Math.Max(bgY, 0), bmp.Height - 1));
                int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1, count = 0;
                for (int yy = Math.Max(0, y); yy < Math.Min(bmp.Height, y + h); yy++)
                    for (int xx = Math.Max(0, x); xx < Math.Min(bmp.Width, x + w); xx++)
                    {
                        if (Diff(bmp.GetPixel(xx, yy), bg) <= threshold) continue;
                        count++;
                        if (xx < minX) minX = xx; if (yy < minY) minY = yy;
                        if (xx > maxX) maxX = xx; if (yy > maxY) maxY = yy;
                    }
                return new[] { minX, minY, maxX, maxY, count };
            }
        }
    }
}
'@
}

$out = [System.IO.Path]::GetFullPath($OutDir, (Get-Location).Path)
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }
$exePath = (Resolve-Path -LiteralPath $Exe).Path
$dataDir = [System.IO.Path]::GetFullPath('target\phase2-data', (Get-Location).Path)
if (-not (Test-Path -LiteralPath $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }

$summary = [ordered]@{ startedAt = (Get-Date).ToString('o'); exe = $exePath; steps = [ordered]@{}; errors = @() }

function Assert-NotRunning {
    $existing = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0) {
        throw "이미 실행 중인 $ProcessName 가 있다 (PID $($existing.Id -join ', ')). 닫고 다시 실행하라"
    }
}

function Save-Capture([IntPtr]$Hwnd, [int]$AppPid, [string]$Name) {
    $png = Join-Path $out "$Name.png"
    $expected = '0x{0:X}' -f $Hwnd.ToInt64()
    $raw = & pwsh -NoProfile -File $CaptureScript -Hwnd $expected -Out $png -Method PrintWindow
    $text = ($raw | Out-String)
    Set-Content -LiteralPath (Join-Path $out "$Name.json") -Value $text -Encoding utf8
    $obj = $text | ConvertFrom-Json
    if ($obj.hwnd -ne $expected -or $obj.pid -ne $AppPid) { throw "capture ${Name}: 고정한 창과 다른 창을 찍었다" }
    if (-not $obj.capture.ok) { throw "capture $Name 실패: $($obj.capture.error)" }
    $obj | Add-Member -NotePropertyName png -NotePropertyValue $png -Force
    return $obj
}

# 앱을 띄워 표준출력에 $DonePattern 이 나올 때까지 기다리고, $OnReady 를 부른 뒤 닫는다.
function Invoke-App([string]$Name, [string[]]$AppArgs, [string]$DonePattern, [int]$TimeoutSec, [scriptblock]$OnReady) {
    Assert-NotRunning
    $stdout = Join-Path $out "$Name-stdout.txt"
    $quoted = $AppArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process -FilePath $exePath -ArgumentList $quoted -RedirectStandardOutput $stdout -PassThru
    $result = [ordered]@{ name = $Name; args = $AppArgs; pid = $proc.Id; windowMs = $null; doneMs = $null; timedOut = $false; stdout = $stdout; ready = $null }
    try {
        $hwnd = [IntPtr]::Zero
        while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec -and $hwnd -eq [IntPtr]::Zero) {
            Start-Sleep -Milliseconds 50
            $hwnd = [WgPhase2.Native]::FindTitled([uint32]$proc.Id, $AppTitle)
        }
        if ($hwnd -eq [IntPtr]::Zero) { throw "${Name}: 앱 창이 ${TimeoutSec}초 안에 뜨지 않았다" }
        $result.windowMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
        while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
            if ((Test-Path -LiteralPath $stdout) -and (Select-String -LiteralPath $stdout -Pattern $DonePattern -Quiet)) { break }
            if ($proc.HasExited) { throw "${Name}: 앱이 먼저 종료됐다 (exit $($proc.ExitCode))" }
            Start-Sleep -Milliseconds 100
        }
        if (-not (Select-String -LiteralPath $stdout -Pattern $DonePattern -Quiet)) {
            $result.timedOut = $true
            $script:summary.errors += "${Name}: '$DonePattern' 줄이 ${TimeoutSec}초 안에 나오지 않았다"
        } else {
            $result.doneMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
        }
        if ($OnReady) { $result.ready = & $OnReady $hwnd $proc.Id }
    }
    finally {
        if (-not $proc.HasExited) {
            try { [void]$proc.CloseMainWindow(); [void]$proc.WaitForExit(5000) } catch {}
            if (-not $proc.HasExited) { try { $proc.Kill(); [void]$proc.WaitForExit(3000) } catch {} }
        }
    }
    $result.lines = @(Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue | Where-Object { $_ -like '[[]dev]*' })
    return $result
}

# "[dev] ... key=value ..." 한 줄에서 key 값.
function Get-Field([string]$Line, [string]$Key) {
    if ($Line -match "(?:^|\s)$([regex]::Escape($Key))=(`"[^`"]*`"|\S+)") { return $Matches[1].Trim('"') }
    return $null
}

function Parse-Bounds([string]$Text) {
    if (-not $Text) { return $null }
    $v = $Text.Split(',') | ForEach-Object { [double]$_ }
    [ordered]@{ x = $v[0]; y = $v[1]; w = $v[2]; h = $v[3] }
}

try {
    # ---------------- r7 ----------------
    if ($StepList -contains 'r7') {
        $r = Invoke-App 'r7' @('--dev-editor-poc') '\[dev\] poc done' 30 {
            param($hwnd, $appPid)
            (Save-Capture $hwnd $appPid 'r7-editor').png
        }
        $summary.steps.r7 = $r
    }

    # ---------------- r8 ----------------
    if ($StepList -contains 'r8') {
        $perf = [ordered]@{}
        # (줄 수, soft wrap). wrap 은 gpui-base 기본값(켜짐). 10만 줄은 wrap 끔도 잰다.
        foreach ($cfg in @(@(50000, $true), @(100000, $true), @(100000, $false))) {
            $lines = $cfg[0]; $wrap = $cfg[1]
            $file = Join-Path $dataDir "lines-$lines.txt"
            if (-not (Test-Path -LiteralPath $file)) {
                $sb = [System.Text.StringBuilder]::new()
                for ($i = 1; $i -le $lines; $i++) {
                    [void]$sb.Append(('line {0:D6}: the quick brown fox jumps over the lazy dog 가나다 0123456789' -f $i)).Append("`n")
                }
                [System.IO.File]::WriteAllText($file, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
            }
            $name = "r8-$($lines / 1000)k" + $(if (-not $wrap) { '-nowrap' } else { '' }) + $(if ($Tag) { "-$Tag" } else { '' })
            $appArgs = @('--dev-poc-file', $file, '--dev-perf') + $(if (-not $wrap) { @('--dev-no-wrap') } else { @() })
            $r = Invoke-App $name $appArgs '\[dev\] poc done' 600 {
                param($hwnd, $appPid)
                (Save-Capture $hwnd $appPid "$name-after").png
            }
            $load = $r.lines | Where-Object { $_ -like '[[]dev] load *' } | Select-Object -First 1
            $first = $r.lines | Where-Object { $_ -like '[[]dev] perf first_frame*' } | Select-Object -First 1
            $scroll = $r.lines | Where-Object { $_ -like '[[]dev] perf scroll*' } | Select-Object -First 1
            $insert = $r.lines | Where-Object { $_ -like '[[]dev] perf insert*' } | Select-Object -First 1
            $perf[$name] = [ordered]@{
                method = '앱 내부: 변경(set_value·set_scroll_offset·insert)을 적용한 시점부터, 그 변경이 그려진 프레임의 draw·present 가 끝난 뒤 실행되는 foreground 작업까지 (on_next_frame 콜백에서 예약, gpui-pre window.rs 1878~1912). drawn = 그 시점까지 화면이 다시 그려진 측정 수. 실제 키 입력→화면 지연이 아니다'
                softWrap = $wrap
                file = $file
                fileBytes = (Get-Item -LiteralPath $file).Length
                lines = [int](Get-Field $load 'lines')
                readMs = [double](Get-Field $load 'read_ms')
                decodeMs = [double](Get-Field $load 'decode_ms')
                setValueMs = [double](Get-Field $load 'set_value_ms')
                firstFrameAfterSetValueMs = [double](Get-Field $first 'first_frame_after_set_value_ms')
                firstFrameDrawn = Get-Field $first 'drawn'
                processStartToWindowMs = $r.windowMs
                scroll = [ordered]@{ n = Get-Field $scroll 'n'; drawn = Get-Field $scroll 'drawn'; avgMs = Get-Field $scroll 'avg'; minMs = Get-Field $scroll 'min'; maxMs = Get-Field $scroll 'max'; raw = $scroll }
                insert = [ordered]@{ n = Get-Field $insert 'n'; drawn = Get-Field $insert 'drawn'; avgMs = Get-Field $insert 'avg'; minMs = Get-Field $insert 'min'; maxMs = Get-Field $insert 'max'; raw = $insert }
                timedOut = $r.timedOut
                stdout = $r.stdout
                screenshot = $r.ready
            }
        }
        $perfFile = 'r8-perf' + $(if ($Tag) { "-$Tag" } else { '' }) + '.json'
        $perf | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $out $perfFile) -Encoding utf8
        $summary.steps.r8 = $perf
    }

    # ---------------- r9 ----------------
    if ($StepList -contains 'r9') {
        $r9 = Join-Path $out 'r9'
        if (-not (Test-Path -LiteralPath $r9)) { New-Item -ItemType Directory -Path $r9 -Force | Out-Null }
        [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
        $crlf = "첫째 줄 first line`r`n둘째 줄 second line`r`n셋째 줄 third`r`n"
        $lf = $crlf.Replace("`r`n", "`n")
        $inputs = [ordered]@{
            'lf-utf8.txt'          = [System.Text.UTF8Encoding]::new($false).GetBytes($lf)
            'crlf-utf8.txt'        = [System.Text.UTF8Encoding]::new($false).GetBytes($crlf)
            'crlf-utf16le-bom.txt' = [byte[]](@(0xFF, 0xFE) + [System.Text.Encoding]::Unicode.GetBytes($crlf))
            'crlf-cp949.txt'       = [System.Text.Encoding]::GetEncoding(949).GetBytes($crlf)
        }
        $rows = @()
        foreach ($name in $inputs.Keys) {
            $inPath = Join-Path $r9 "in-$name"
            [System.IO.File]::WriteAllBytes($inPath, $inputs[$name])
            foreach ($mode in 'naive', 'app') {
                $outPath = Join-Path $r9 "out-$mode-$name"
                if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath }
                $runTag = "r9-$mode-$([System.IO.Path]::GetFileNameWithoutExtension($name))"
                $r = Invoke-App $runTag @('--dev-poc-file', $inPath, '--dev-roundtrip-out', $outPath, '--dev-roundtrip-mode', $mode) '\[dev\] (roundtrip|load result=error)' 30 $null
                Move-Item -LiteralPath $r.stdout -Destination (Join-Path $r9 "$runTag-stdout.txt") -Force
                $line = $r.lines | Where-Object { $_ -like '[[]dev] roundtrip*' -or $_ -like '[[]dev] load result=error*' } | Select-Object -First 1
                $inBytes = [System.IO.File]::ReadAllBytes($inPath)
                $outBytes = if (Test-Path -LiteralPath $outPath) { [System.IO.File]::ReadAllBytes($outPath) } else { $null }
                $firstDiff = $null
                if ($outBytes) {
                    $n = [math]::Min($inBytes.Length, $outBytes.Length)
                    for ($i = 0; $i -lt $n; $i++) { if ($inBytes[$i] -ne $outBytes[$i]) { $firstDiff = $i; break } }
                    if ($null -eq $firstDiff -and $inBytes.Length -ne $outBytes.Length) { $firstDiff = $n }
                }
                $rows += [ordered]@{
                    input = $name
                    mode = $mode
                    detectedEncoding = Get-Field $line 'encoding'
                    inBytes = $inBytes.Length
                    outBytes = if ($outBytes) { $outBytes.Length } else { $null }
                    bytesIdentical = ($null -ne $outBytes -and $null -eq $firstDiff)
                    firstDiffOffset = $firstDiff
                    appLine = $line
                    out = $outPath
                }
            }
        }
        $rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $out 'r9-roundtrip.json') -Encoding utf8

        # CP949 손실 문자 시험: 앱의 인코딩 함수가 U+20A9(₩)·U+00A5(¥)를 오류로 잡고, 한글은 손실 없이 옮기는가.
        $st = Invoke-App 'r9-cp949-selftest' @('--dev-cp949-selftest') '\[dev\] cp949-selftest done' 30 $null
        Move-Item -LiteralPath $st.stdout -Destination (Join-Path $r9 'r9-cp949-selftest-stdout.txt') -Force
        $doneLine = $st.lines | Where-Object { $_ -like '[[]dev] cp949-selftest done*' } | Select-Object -First 1
        $cases = @($st.lines | Where-Object { $_ -like '[[]dev] cp949-selftest case=*' } | ForEach-Object {
            [ordered]@{ case = Get-Field $_ 'case'; expect = Get-Field $_ 'expect'; got = Get-Field $_ 'got'; pass = (Get-Field $_ 'pass') -eq 'true'; line = $_ }
        })
        $selftest = [ordered]@{ done = $doneLine; cases = $cases; allPass = ($cases.Count -gt 0 -and -not ($cases | Where-Object { -not $_.pass })) }
        $selftest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $out 'r9-cp949-selftest.json') -Encoding utf8
        if (-not $selftest.allPass) { $summary.errors += "r9: CP949 손실 문자 시험이 모두 통과하지 않았다 ($doneLine)" }
        $summary.steps.r9 = $rows
    }

    # ---------------- r10 ----------------
    if ($StepList -contains 'r10') {
        $r = Invoke-App 'r10' @('--dev-editor-poc', '--dev-measure') '\[dev\] poc done' 60 {
            param($hwnd, $appPid)
            Save-Capture $hwnd $appPid 'r10-measure'
        }
        $cap = $r.ready
        $s = [double]$cap.scale
        $cx0 = $cap.clientRect.x - $cap.rect.x
        $cy0 = $cap.clientRect.y - $cap.rect.y
        $editorLine = $r.lines | Where-Object { $_ -like '[[]dev] measure editor*' } | Select-Object -First 1
        $editorBounds = Parse-Bounds (Get-Field $editorLine 'input_bounds')
        $boxes = @()
        foreach ($l in ($r.lines | Where-Object { $_ -like '[[]dev] measure line *' })) {
            $boxes += [ordered]@{ kind = 'line'; row = [int](Get-Field $l 'row'); name = Get-Field $l 'text'; b = Parse-Bounds (Get-Field $l 'bounds') }
        }
        foreach ($l in ($r.lines | Where-Object { $_ -like '[[]dev] measure segment *' })) {
            $boxes += [ordered]@{ kind = 'segment'; row = [int](Get-Field $l 'row'); name = Get-Field $l 'name'; b = Parse-Bounds (Get-Field $l 'bounds') }
        }
        $pix = @()
        foreach ($box in $boxes) {
            $b = $box.b
            if (-not $b) { continue }
            # 줄 끝의 커서(폭 1)를 피하려고 오른쪽 2 논리 px 를 뺀다.
            # 배경은 같은 행의 편집기 오른쪽 끝에서 40 논리 px 안쪽(글자가 없는 곳)에서 잰다.
            # (구간 바로 오른쪽은 같은 줄의 다음 글자일 수 있어 쓰지 않는다.)
            $px = [int]($cx0 + $b.x * $s); $py = [int]($cy0 + $b.y * $s)
            $pw = [int](($b.w - 2) * $s); $ph = [int]($b.h * $s)
            $bgX = [int]($cx0 + ($editorBounds.x + $editorBounds.w - 40) * $s); $bgY = [int]($py + $ph / 2)
            $ink = [WgPhase2.Native]::InkBox($cap.png, $px, $py, $pw, $ph, $bgX, $bgY, 96)
            $pix += [ordered]@{
                kind = $box.kind; row = $box.row; name = $box.name
                boxLogical = $b
                inkCount = $ink[4]
                inkTopFromBoxTopPhysical = if ($ink[4]) { $ink[1] - $py } else { $null }
                inkBottomFromBoxTopPhysical = if ($ink[4]) { $ink[3] - $py } else { $null }
                inkBottomFromBoxTopLogical = if ($ink[4]) { [math]::Round(($ink[3] - $py) / $s, 2) } else { $null }
                inkWidthPhysical = if ($ink[4]) { $ink[2] - $ink[0] + 1 } else { $null }
                inkWidthLogical = if ($ink[4]) { [math]::Round(($ink[2] - $ink[0] + 1) / $s, 2) } else { $null }
            }
        }
        $fonts = @($r.lines | Where-Object { $_ -like '[[]dev] measure font *' })
        $cursors = @($r.lines | Where-Object { $_ -like '[[]dev] measure cursor *' })
        $r10 = [ordered]@{
            scale = $s
            editorInputBounds = $editorBounds
            lineHeight = Get-Field $editorLine 'line_height'
            gutterLogical = if ($editorBounds -and $boxes.Count) { [math]::Round($boxes[0].b.x - $editorBounds.x, 2) } else { $null }
            fonts = $fonts
            cursors = $cursors
            pixels = $pix
            note = 'inkBottom = 상자 위에서 잉크 맨 아래 행까지(기준선 근사). 측정 줄은 아래로 내려가는 글자가 없는 글자만 쓴다(abcdehiklm, def)'
            screenshot = $cap.png
            stdout = $r.stdout
        }
        $r10 | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $out 'r10-pixels.json') -Encoding utf8
        $summary.steps.r10 = $r10
    }
}
catch {
    $summary.errors += $_.Exception.Message
}

$summary.finishedAt = (Get-Date).ToString('o')
# 실행한 단계(와 꼬리표)마다 요약 파일을 따로 둔다. 예: summary-r7-r9-r10.json, summary-r8-opt.json
$summaryName = 'summary-' + ($StepList -join '-') + $(if ($Tag) { "-$Tag" } else { '' }) + '.json'
$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $out $summaryName) -Encoding utf8
"errors: $($summary.errors.Count)"
$summary.errors
if ($summary.errors.Count -gt 0) { exit 1 }
