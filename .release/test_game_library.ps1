$ErrorActionPreference='Stop'
& {
    . "$PSScriptRoot/../ui/hotd4-game-library.ps1"
    $nested={Get-Command New-Hotd4GameStartInfo -ErrorAction Stop | Out-Null}.GetNewClosure()
    & $nested
}
. "$PSScriptRoot/../ui/hotd4-game-library.ps1"
function Assert($condition,[string]$message){if(!$condition){throw $message}}
function New-Fixture([string]$Root,[string]$Game){
    $folder=if($Game -eq 'Normal'){'HOTD4_Recomp'}else{'HOTD4SP_Recomp'}
    $app=Join-Path $Root $folder;[void][IO.Directory]::CreateDirectory($app)
    $exe=if($Game -eq 'Normal'){'hotd4-desktop.exe'}else{'hotd4sp-desktop.exe'}
    $menu=if($Game -eq 'Normal'){'hotd4-startmenu.ps1'}else{'hotd4sp-startmenu.ps1'}
    $entry=if($Game -eq 'Normal'){Join-Path $Root 'Play HOTD4.exe'}else{Join-Path $app 'Play HOTD4 Special.exe'}
    foreach($file in @((Join-Path $app $exe),(Join-Path $app $menu),$entry)){[IO.File]::WriteAllText($file,'asset-free test fixture')}
    return $app
}
$test=Join-Path ([IO.Path]::GetTempPath()) ('HOTD4 library '+[char]0xe5+" & O'Brien "+[Guid]::NewGuid().ToString('N'))
$normal=New-Fixture (Join-Path $test 'nearby') Normal
$special=New-Fixture (Join-Path $test 'nearby') Special
$far=New-Fixture (Join-Path $test 'different installation') Special
$library=Join-Path $test 'preferences/installations.json'
Assert ((Resolve-Hotd4Installation (Split-Path $normal -Parent) Normal) -eq $normal) 'Normal root detection failed'
Assert ((Resolve-Hotd4Installation $special Special) -eq $special) 'Special app detection failed'
Assert (!(Resolve-Hotd4Installation $normal Special)) 'Wrong game accepted'
Assert ((Find-Hotd4OtherInstallation $normal Normal $library) -eq $special) 'Sibling Special discovery failed'
Assert ((Find-Hotd4OtherInstallation $special Special $library) -eq $normal) 'Sibling normal discovery failed'
Register-Hotd4Installation $normal Normal $library
Register-Hotd4Installation $far Special $library
$data=Read-Hotd4Library $library
Assert ($data.Normal -eq $normal -and $data.Special -eq $far) 'Registration lost another installation'
Assert ((Find-Hotd4OtherInstallation $normal Normal $library) -eq $far) 'Saved installation not preferred'
[IO.File]::WriteAllText($library,'{"Version":1,"Special":"Z:\\missing\\game"}')
Assert ((Find-Hotd4OtherInstallation $normal Normal $library) -eq $special) 'Stale path prevented sibling discovery'
[IO.File]::WriteAllText($library,'broken json')
Register-Hotd4Installation $normal Normal $library
Assert ((Read-Hotd4Library $library).Normal -eq $normal) 'Damaged library could not recover'
$original=@{}
try{
    foreach($key in @('HOTD4_SETTINGS_DIR','HOTD4SP_CHAPTER','LINDBERGH_NVRAM','TEA_DIR','PATH')){$original[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
    $env:HOTD4_SETTINGS_DIR=$normal;$env:HOTD4SP_CHAPTER='2';$env:LINDBERGH_NVRAM='wrong-cabinet';$env:TEA_DIR='wrong-dump';$env:PATH=$normal+';'+$env:PATH
    $info=New-Hotd4GameStartInfo $special Special $normal
    Assert ($info.FileName -eq (Join-Path $special 'Play HOTD4 Special.exe')) 'Wrong Special entry point'
    Assert (!$info.UseShellExecute -and $info.CreateNoWindow) 'Console-free child options incorrect'
    foreach($key in @($info.EnvironmentVariables.Keys)){Assert ($key -notmatch '^(HOTD4_|HOTD4SP_|LINDBERGH_)' -and $key -ne 'TEA_DIR') ('Inherited game setting: '+$key)}
    Assert (($info.EnvironmentVariables['PATH'] -split ';') -notcontains $normal) 'Previous game DLL path leaked'
    Assert ($env:HOTD4_SETTINGS_DIR -eq $normal -and $env:LINDBERGH_NVRAM -eq 'wrong-cabinet') 'Parent environment was modified'
    $info=New-Hotd4GameStartInfo $normal Normal $special
    Assert ($info.FileName -eq (Join-Path (Split-Path $normal -Parent) 'Play HOTD4.exe')) 'Wrong normal entry point'
}finally{foreach($key in $original.Keys){[Environment]::SetEnvironmentVariable($key,$original[$key],'Process')}}
$caught=$false;try{New-Hotd4GameStartInfo (Join-Path $test 'absent') Special}catch{$caught=$true}
Assert $caught 'Missing target accepted'
Write-Host 'PASS: sibling and saved discovery, independent layouts, spaces/accents/metacharacters, stale/corrupt paths, registration, clean child environment and hidden launch options.'
