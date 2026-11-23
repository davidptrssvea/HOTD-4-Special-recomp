[CmdletBinding()]
param([ValidateSet('MainPage','OptionsPage')][string]$InitialPage='MainPage',[switch]$LogFrames,[switch]$NoMenu,[ValidateRange(0,2)][int]$Chapter=0,[switch]$ValidateOnly)
$ErrorActionPreference='Stop'
$recompDir=$PSScriptRoot
$gameDir=if($env:HOTD4SP_DUMP_DIR){$env:HOTD4SP_DUMP_DIR}else{Join-Path (Split-Path -Parent $recompDir) 'hotd4sp'}
$elfDir=Join-Path $gameDir 'elf'
$exe=Join-Path $recompDir 'hotd4sp-desktop.exe'
$elf=Join-Path $elfDir 'hod4M.elf'
. (Join-Path $recompDir 'hotd4sp-config.ps1')
. (Join-Path $recompDir 'hotd4-display.ps1')
function Read-Profile([string]$Name,[string]$Default) {
    $path=Join-Path $recompDir $Name
    if([IO.File]::Exists($path)){return [IO.File]::ReadAllText($path).Trim()}
    return $Default
}
function Start-Special($Selection,[int]$DesktopWidth,[int]$DesktopHeight) {
    $width=$DesktopWidth;$height=$DesktopHeight
    if($Selection.Resolution -ne 'auto'){$width,$height=$Selection.Resolution.Split('x') | ForEach-Object {[int]$_}}
    $rw,$rh=Get-Hotd4RenderSize $width $height (Get-Hotd4AspectRatio $recompDir)
    $windowed=$Selection.DisplayMode -eq 'Windowed'
    $outputW=if($windowed){$width}else{$DesktopWidth};$outputH=if($windowed){$height}else{$DesktopHeight}
    Write-Hotd4SPConfig $recompDir @{width=$rw;height=$rh;fullscreen=[int](!$windowed)}
    $launchNvram=$null;$practice=[int]$Selection.Mode -gt 0
    if($practice){$launchNvram=Join-Path ([IO.Path]::GetTempPath()) ('hotd4sp-practice-'+[guid]::NewGuid().ToString('N')+'.nvram')}
    try {
        do {
            [IO.File]::Copy((Join-Path $recompDir 'lindbergh.ini'),(Join-Path $elfDir 'lindbergh.ini'),$true)
            if($practice){
                if([IO.File]::Exists($launchNvram)){[IO.File]::Delete($launchNvram)}
                $saved=Join-Path $elfDir 'lindbergh_nvram.bin';if([IO.File]::Exists($saved)){[IO.File]::Copy($saved,$launchNvram)}
            }
            $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=$exe;$info.Arguments='"'+$elf+'"';$info.WorkingDirectory=$elfDir
            $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
            $info.EnvironmentVariables['PATH']="$recompDir;"+$env:PATH
            $info.EnvironmentVariables['TEA_DIR']=$gameDir
            $info.EnvironmentVariables['HOTD4_SETTINGS_DIR']=$recompDir
            $info.EnvironmentVariables['HOTD4SP_MENU']='1';$info.EnvironmentVariables['HOTD4_PAUSE_MENU']='1'
            $info.EnvironmentVariables['HOTD4SP_RENDER_SIZE']='{0}x{1}' -f $rw,$rh
            $info.EnvironmentVariables['LINDBERGH_WINDOW']='{0}x{1}' -f $outputW,$outputH
            $info.EnvironmentVariables['LINDBERGH_FULLSCREEN']=[string][int](!$windowed)
            $info.EnvironmentVariables['HOTD4_HUD_PROFILE']=Join-Path $recompDir 'hud-profile.txt'
            $info.EnvironmentVariables['HOTD4_HUD_SCALE']=Read-Profile 'hud-profile.txt' '0'
            foreach($pair in @(@('HOTD4_CROSSHAIR_PROFILE','crosshair-profile.txt'),@('HOTD4_CROSSHAIR_SIZE_PROFILE','crosshair-size.txt'),@('HOTD4_CROSSHAIR_COLOR_PROFILE','crosshair-color.txt'),@('HOTD4_SINDEN_PROFILE','sinden-profile.txt'))){$info.EnvironmentVariables[$pair[0]]=Join-Path $recompDir $pair[1]}
            if($practice){$info.EnvironmentVariables['LINDBERGH_AUTOSTART']='1';$info.EnvironmentVariables['HOTD4SP_CHAPTER']=[string]$Selection.Mode;$info.EnvironmentVariables['HOTD4_PRACTICE_CHAPTER']=[string]$Selection.Mode;$info.EnvironmentVariables['LINDBERGH_NVRAM']=$launchNvram}
            else{$info.EnvironmentVariables.Remove('HOTD4SP_CHAPTER');$info.EnvironmentVariables.Remove('HOTD4_PRACTICE_CHAPTER')}
            if($LogFrames -or $Selection.LogFrames){
                $directory=Join-Path $recompDir 'Frame Logs';[void][IO.Directory]::CreateDirectory($directory)
                $info.EnvironmentVariables['LINDBERGH_FRAME_TIMINGS']=Join-Path $directory ('HOTD4SP-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.csv')
            }
            $process=[Diagnostics.Process]::Start($info)
            try{
                $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$process.WaitForExit();$exitCode=$process.ExitCode
                $text=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
                [IO.File]::WriteAllText((Join-Path $recompDir 'hotd4sp-last-run.log'),$text,[Text.UTF8Encoding]::new($false))
            }finally{$process.Dispose()}
            [IO.File]::Copy((Join-Path $elfDir 'lindbergh.ini'),(Join-Path $recompDir 'lindbergh.ini'),$true)
        }while($exitCode -eq 74)
        if($exitCode -ne 0){throw "HOTD4 Special exited with code $exitCode. Details: hotd4sp-last-run.log"}
    }finally{if($launchNvram -and [IO.File]::Exists($launchNvram)){[IO.File]::Delete($launchNvram)}}
}
try {
    foreach($path in @($exe,$elf,(Join-Path $gameDir 'fs'))){if(!(Test-Path -LiteralPath $path)){throw "Missing file or folder: $path"}}
    $sha=[Security.Cryptography.SHA256]::Create();$stream=[IO.File]::OpenRead($elf)
    try{$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}
    if($hash -ne 'B84C70D9940D5F5FA7D287FD8C6B050444FDCBC2FD742D3AFC74A1099BBEC5FE'){throw 'This build requires the supported HOTD4 Special hod4M.elf. The original dump is not modified.'}
    . (Join-Path $recompDir 'hotd4-native-crosshair.ps1')
    [void](Initialize-Hotd4NativeCrosshair $recompDir $gameDir)
    if($ValidateOnly){Write-Output 'HOTD4 Special launcher files and dump verified.';exit 0}
    if(!('Hotd4SPDisplay' -as [type])){Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class Hotd4SPDisplay {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern int GetSystemMetrics(int index);
}
'@
    }
    [void][Hotd4SPDisplay]::SetProcessDPIAware();$dw=[Hotd4SPDisplay]::GetSystemMetrics(0);$dh=[Hotd4SPDisplay]::GetSystemMetrics(1)
    if($dw -le 0 -or $dh -le 0){throw 'Could not detect desktop resolution.'}
    if($NoMenu){
        $selection=@{Mode=[string]$Chapter;Resolution=(Read-Profile 'display-profile.txt' 'auto');DisplayMode=(Read-Profile 'display-mode.txt' 'Borderless');LogFrames=[bool]$LogFrames}
        Start-Special $selection $dw $dh;exit 0
    }
    . (Join-Path $recompDir 'hotd4sp-startmenu.ps1')
    do {
        $selection=Show-Hotd4SPStartMenu -RecompDir $recompDir -DesktopWidth $dw -DesktopHeight $dh -InitialPage $InitialPage
        $InitialPage='MainPage'
        if(!$selection){break}
        Start-Special $selection $dw $dh
    }while($true)
}catch{
    Add-Type -AssemblyName PresentationFramework
    [void][Windows.MessageBox]::Show($_.Exception.GetBaseException().Message,'HOTD4 Special','OK','Error');exit 1
}
