#Requires -Version 7
# P4-E-R1: derive verify-v04-phase2-r1.ps1 from verify-v04-phase2.ps1 (H-21 copy). Only change: the View menu's Phase 4 rows
# (Split Up/Down/Left/Right, Maximize Pane) are added to the expected row text ($expectRows[2]) and to $orig so the menu case no longer aborts.
$d = $PSScriptRoot
$t = Get-Content (Join-Path $d 'verify-v04-phase2.ps1') -Raw -Encoding utf8
$tab = ([char]96 + "t")
$old = "2 = `"Toggle Left Dock|Ctrl-B${tab}Toggle Folder Sidebar|Ctrl-Alt-J${tab}Focus Folder Sidebar|Ctrl-Alt-;${tab}---${tab}Project Panel|Ctrl-Shift-E`""
$new = "2 = `"Toggle Left Dock|Ctrl-B${tab}Toggle Folder Sidebar|Ctrl-Alt-J${tab}Focus Folder Sidebar|Ctrl-Alt-;${tab}Split Up|Ctrl-K Up${tab}Split Down|Ctrl-K Down${tab}Split Left|Ctrl-K Left${tab}Split Right|Ctrl-K Right${tab}Maximize Pane|Shift-Escape${tab}---${tab}Project Panel|Ctrl-Shift-E`""
if (-not $t.Contains($old)) { throw 'expectRows anchor not found' }
$t = $t.Replace($old, $new)
$a = "'Zoom' = @('zed::Zoom', '없음 (F11 은 다른 액션)') }"
if (-not $t.Contains($a)) { throw 'orig anchor not found' }
$b = "'Zoom' = @('zed::Zoom', '없음 (F11 은 다른 액션)'); 'Split Up' = @('pane::SplitUp', 'Ctrl+K Up'); 'Split Down' = @('pane::SplitDown', 'Ctrl+K Down'); 'Split Left' = @('pane::SplitLeft', 'Ctrl+K Left'); 'Split Right' = @('pane::SplitRight', 'Ctrl+K Right'); 'Maximize Pane' = @('workspace::ToggleZoom', 'Shift+Escape') }"
$t = $t.Replace($a, $b)
Set-Content (Join-Path $d 'verify-v04-phase2-r1.ps1') $t -Encoding utf8NoBOM
