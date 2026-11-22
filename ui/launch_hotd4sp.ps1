[CmdletBinding()]
param([ValidateSet('Desktop','VR')][string]$Mode='Desktop',[switch]$GraphicalErrors)
$ErrorActionPreference='Stop'
try {
    $modules=Join-Path ([Environment]::SystemDirectory) 'WindowsPowerShell/v1.0/Modules'
    Import-Module (Join-Path $modules 'Microsoft.PowerShell.Utility/Microsoft.PowerShell.Utility.psd1')
    Import-Module (Join-Path $modules 'Microsoft.PowerShell.Management/Microsoft.PowerShell.Management.psd1')
    if($Mode -eq 'Desktop'){& (Join-Path $PSScriptRoot 'hotd4sp-launcher.ps1') -NoMenu;return}
    $gameDir=if($env:HOTD4SP_DUMP_DIR){$env:HOTD4SP_DUMP_DIR}else{Join-Path (Split-Path -Parent $PSScriptRoot) 'hotd4sp'}
    $elfDir=Join-Path $gameDir 'elf';$elf=Join-Path $elfDir 'hod4M.elf';$exe=Join-Path $PSScriptRoot 'hotd4sp-vr.exe'
    foreach($path in @($exe,$elf,(Join-Path $gameDir 'fs'))){if(!(Test-Path -LiteralPath $path)){throw "Missing file or folder: $path"}}
    $sha=[Security.Cryptography.SHA256]::Create();$elfStream=[IO.File]::OpenRead($elf)
    try {$hash=[BitConverter]::ToString($sha.ComputeHash($elfStream)).Replace('-','')}finally{$elfStream.Dispose();$sha.Dispose()}
    if($hash -ne 'B84C70D9940D5F5FA7D287FD8C6B050444FDCBC2FD742D3AFC74A1099BBEC5FE'){throw 'Unsupported HOTD4 Special dump.'}
    $runtime=$env:XR_RUNTIME_JSON
    if(!$runtime){$key=Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Khronos\OpenXR\1' -Name ActiveRuntime -ErrorAction SilentlyContinue;$runtime=$key.ActiveRuntime}
    if(!$runtime -or !(Test-Path -LiteralPath $runtime -PathType Leaf)){throw 'No active OpenXR runtime is configured. Select one in your headset software.'}
    $cfg=Join-Path $PSScriptRoot 'vr.cfg'
    if(!(Test-Path -LiteralPath $cfg) -and (Test-Path -LiteralPath (Join-Path $elfDir 'vr.cfg'))){Copy-Item -LiteralPath (Join-Path $elfDir 'vr.cfg') -Destination $cfg}
    $nvram=Join-Path $PSScriptRoot 'lindbergh_nvram.vr.bin'
    if(!(Test-Path -LiteralPath $nvram) -and (Test-Path -LiteralPath (Join-Path $elfDir 'lindbergh_nvram.bin'))){Copy-Item -LiteralPath (Join-Path $elfDir 'lindbergh_nvram.bin') -Destination $nvram}
    $logDir=Join-Path $PSScriptRoot 'VR Logs';[void][IO.Directory]::CreateDirectory($logDir)
    do {
        $log=Join-Path $logDir ('OpenXR-SP-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.log')
        $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=$exe;$info.Arguments='"'+$elf+'"';$info.WorkingDirectory=$PSScriptRoot
        $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
        $info.EnvironmentVariables['PATH']="$PSScriptRoot;"+$env:PATH
        $info.EnvironmentVariables['TEA_DIR']=$gameDir;$info.EnvironmentVariables['HOTD4_SETTINGS_DIR']=$PSScriptRoot
        $info.EnvironmentVariables['LINDBERGH_GAME_CWD']=$elfDir
        $info.EnvironmentVariables['HOTD4_VR_LAUNCHER']='1';$info.EnvironmentVariables['LINDBERGH_NVRAM']=$nvram
        $info.EnvironmentVariables['LINDBERGH_SHOT_FROM_GUN']='1'
        $process=[Diagnostics.Process]::Start($info)
        try {
            $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync();$process.WaitForExit();$code=$process.ExitCode
            [IO.File]::WriteAllText($log,$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult(),[Text.UTF8Encoding]::new($false))
        } finally {$process.Dispose()}
    } while($code -eq 74)
    if($code -ne 0){throw "HOTD4 Special VR exited with code $code. Log: $log"}
} catch {
    $message=$_.Exception.GetBaseException().Message;[Console]::Error.WriteLine($message)
    if($GraphicalErrors){Add-Type -AssemblyName PresentationFramework;[void][Windows.MessageBox]::Show($message,'HOTD4 Special VR','OK','Error')}
    throw
}
