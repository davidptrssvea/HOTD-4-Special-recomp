param([string]$PreviewDir)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/../ui/hotd-game-library.ps1"

function Assert($condition,[string]$message) {
    if (!$condition) { throw $message }
}
function Write-Fixture([string]$Path,[string]$Content='asset-free test fixture') {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    [IO.File]::WriteAllText($Path,$Content)
}
function New-Fixture([string]$Root,[string]$Game,[switch]$Legacy,[switch]$MissingData) {
    $spec=Get-HotdLibrarySpec $Game
    $app=if ($spec.App) { Join-Path $Root $spec.App } else { $Root }
    Write-Fixture (Join-Path $Root $spec.Launcher)
    $menu=if ($Game -eq 'Scarlet' -and !$Legacy) { "# HOTD Game Library" } else { "# Game menu" }
    Write-Fixture (Join-Path $app $spec.Menu) $menu
    Write-Fixture (Join-Path $app $spec.Binary)
    if ($spec.EntryScript) { Write-Fixture (Join-Path $app $spec.EntryScript) }
    if (!$Legacy -and $Game -ne 'Scarlet') { Write-Fixture (Join-Path $app 'hotd-game-library.ps1') }
    if ($Game -eq 'Normal') {
        Write-Fixture (Join-Path $Root 'Play HOTD4.cmd') 'set "HOTD4_NO_LAUNCHER=0"'
        Write-Fixture (Join-Path $Root 'dump-path.txt') (Join-Path $Root 'game/disk0')
    }
    if (!$MissingData) {
        if ($Game -eq 'Scarlet') {
            Write-Fixture (Join-Path $Root 'Game/Hodzero/Binaries/Win64/Hodzero-Win64-Shipping.exe')
            Write-Fixture (Join-Path $Root 'Game/Hodzero/Content/Paks/Hodzero-WindowsNoEditor.pak')
        } else {
            $data=Join-Path $Root (@{Normal='game/disk0';Special='hotd4sp';EX='disk0'}[$Game])
            $elf=if ($Game -eq 'EX') { 'hodexRI.elf' } else { 'hod4M.elf' }
            Write-Fixture (Join-Path $data ('elf/'+$elf))
            [void][IO.Directory]::CreateDirectory((Join-Path $data 'fs'))
        }
    }
    return $app
}

$test=Join-Path ([IO.Path]::GetTempPath()) ('HOTD library '+[char]0xe5+" & O'Brien "+[Guid]::NewGuid().ToString('N'))
$env:LOCALAPPDATA=Join-Path $test 'profile'
$normal=New-Fixture (Join-Path $test 'shared/HOTD4-PC') Normal
$special=New-Fixture (Join-Path $test 'shared/HOTD4SP-PC') Special
$ex=New-Fixture (Join-Path $test 'separate EX drive') EX
$scarlet=New-Fixture (Join-Path $test 'another directory') Scarlet
$incomplete=New-Fixture (Join-Path $test 'shared/Scarlet Dawn') Scarlet -MissingData
$library=Get-HotdLibraryPath
$oldLibrary=Join-Path $env:LOCALAPPDATA 'HOTD4-Launcher/installations.json'

Assert ((Resolve-Hotd4Installation (Split-Path $normal -Parent) Normal).App -eq $normal) 'Normal root failed'
Assert ((Resolve-Hotd4Installation (Join-Path $special 'Play HOTD4 Special.exe') Special).App -eq $special) 'Special launcher path failed'
Assert (!(Resolve-Hotd4Installation $incomplete Scarlet)) 'Package without game data was accepted'
Assert (!(Resolve-Hotd4Installation $normal Special)) 'A different game was accepted'
Assert ((@(Get-HotdLibraryInstallations $normal Normal).Game -join ',') -eq 'Normal,Special') 'Nearby or missing-game filtering failed'

Write-Fixture $oldLibrary (@{Version=1;Normal=$normal;Special=$special} | ConvertTo-Json)
$history=Join-Path $env:LOCALAPPDATA 'HOTD-Setup/EX.json'
Write-Fixture $history (@{Format=1;Edition='EX';InstallDir=(Split-Path $ex -Parent)} | ConvertTo-Json)
Register-Hotd4Installation $scarlet Scarlet
Register-Hotd4Installation $ex EX
Write-Fixture $oldLibrary (@{Version=1;Normal=$normal;Special='Z:\missing'} | ConvertTo-Json)
Assert ((Read-Hotd4Library).Scarlet -eq $scarlet) 'An old registry write erased the new registration'
Assert ((@(Get-HotdLibraryInstallations $normal Normal).Game -join ',') -eq 'Normal,Special,EX,Scarlet') 'Four-game discovery or stale fallback failed'
Write-Fixture $library 'corrupt json'
Assert ((@(Get-HotdLibraryInstallations $normal Normal).Game -join ',') -eq 'Normal,Special,EX') 'Setup history recovery failed'
Register-Hotd4Installation $scarlet Scarlet
Register-Hotd4Installation $normal Normal
Assert ((Read-Hotd4Library).Scarlet -eq $scarlet -and (Read-Hotd4Library).Normal -eq $normal) 'Registration lost an edition'

$legacy=New-Fixture (Join-Path $test 'older Scarlet') Scarlet -Legacy
Assert (!(Resolve-Hotd4Installation $legacy Scarlet).CanSettings) 'Legacy Scarlet incorrectly supports direct settings'
Assert (!(New-Hotd4GameStartInfo $legacy Scarlet $normal Settings).Arguments) 'Legacy Scarlet was given unsupported options'

$env:HOTD4_SETTINGS_DIR=$normal
$env:HOTD4SP_CHAPTER='2'
$env:HOTDEX_TEST='stale'
$env:SCARLET_TEST='stale'
$env:LINDBERGH_NVRAM='wrong-cabinet'
$env:TEA_DIR='wrong-dump'
$env:PATH=$normal+';'+$env:PATH
foreach ($target in @(@('Normal',$normal),@('Special',$special),@('EX',$ex),@('Scarlet',$scarlet))) {
    $fixture=Resolve-Hotd4Installation $target[1] $target[0]
    foreach ($action in 'Menu','Play','Settings') {
        $info=New-Hotd4GameStartInfo $fixture.App $fixture.Game $normal $action
        $flag=@{Menu='';Play='--no-launcher';Settings='--settings'}[$action]
        Assert ($info.FileName -eq $fixture.Launcher -and $info.Arguments -eq $flag) "$($fixture.Game): wrong $action handoff"
        Assert ($info.WorkingDirectory -eq [IO.Path]::GetDirectoryName($fixture.Launcher)) 'Working folder is incorrect'
        Assert (!$info.UseShellExecute -and $info.CreateNoWindow) 'Console-free child options are incorrect'
        foreach ($key in @($info.EnvironmentVariables.Keys)) {
            Assert ($key -notmatch '^(HOTD4(?:SP)?_|HOTDEX_|SCARLET_|LINDBERGH_|TEA_)') "Inherited $key"
        }
        Assert (($info.EnvironmentVariables['PATH'] -split ';') -notcontains $normal) 'Previous game DLL path leaked'
    }
}
Assert ($env:HOTD4_SETTINGS_DIR -eq $normal -and $env:LINDBERGH_NVRAM -eq 'wrong-cabinet') 'Parent environment was modified'

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$inspect={
    param($window,$gameCards)
    $window.ShowActivated=$false
    $window.WindowStartupLocation='Manual'
    $window.Left=-20000
    $window.Top=-20000
    $window.Show()
    $window.UpdateLayout()
    Assert ($gameCards.Children.Count -eq 4) 'A complete installation did not get a card'
    foreach ($card in $gameCards.Children) {
        $actions=$card.Child.Children[0]
        Assert (@($actions.Children | Where-Object Content -eq 'Play').Count -eq 1) 'Missing Play action'
        Assert (@($actions.Children | Where-Object Content -eq 'Settings').Count -eq 1) 'Missing Settings action'
        Assert ($card.ActualHeight -gt 0 -and $card.ActualWidth -gt 0) 'Card did not lay out'
    }
    Assert ($window.FindName('Locate').IsVisible -and $window.FindName('Back').IsVisible) 'Footer actions are clipped'
    if ($PreviewDir) {
        [void][IO.Directory]::CreateDirectory($PreviewDir)
        $grid=$window.Content
        $bounds=[Windows.Rect]::new(0,0,$grid.ActualWidth+48,$grid.ActualHeight+38)
        $visual=[Windows.Media.DrawingVisual]::new()
        $drawing=$visual.RenderOpen()
        $drawing.DrawRectangle($window.Background,$null,$bounds)
        $brush=[Windows.Media.VisualBrush]::new($grid)
        $content=[Windows.Rect]::new(24,19,$grid.ActualWidth,$grid.ActualHeight)
        $drawing.DrawRectangle($brush,$null,$content)
        $drawing.Close()
        $bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new([int][Math]::Ceiling($bounds.Width),[int][Math]::Ceiling($bounds.Height),96,96,[Windows.Media.PixelFormats]::Pbgra32)
        $bitmap.Render($visual)
        $encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new()
        $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
        $stream=[IO.File]::Create((Join-Path $PreviewDir 'HOTD Game Library.png'))
        try { $encoder.Save($stream) } finally { $stream.Dispose() }
    }
    $settings=$gameCards.Children[3].Child.Children[0].Children | Where-Object Content -eq 'Settings'
    $settings.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
}
$selected=Show-HotdGameLibrary -RecompDir $normal -CurrentGame Normal -Inspect $inspect
Assert ($selected.Installation.Game -eq 'Scarlet' -and $selected.Action -eq 'Settings') 'Library selected the wrong game/action'
Write-Host 'PASS: four-game discovery, legacy compatibility, absent game filtering, installer history, launch isolation and WPF handoff.'
