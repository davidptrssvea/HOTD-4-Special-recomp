$ErrorActionPreference='Stop'
. "$PSScriptRoot/../tools/setup_support.ps1"
function Get-Sha256([string]$Path){
    $sha=[Security.Cryptography.SHA256]::Create()
    try{return [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($Path))).Replace('-','')}finally{$sha.Dispose()}
}
function Assert-Throws([scriptblock]$Action,[string]$Pattern){
    $caught=$false
    try{& $Action}catch{if($_.Exception.Message -notmatch $Pattern){throw};$caught=$true}
    if(!$caught){throw "Expected error: $Pattern"}
}
$test=Join-Path ([IO.Path]::GetTempPath()) ('HOTD4 setup tests '+[char]0xe5+' '+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($test)
$source=Join-Path $test 'expected.dat';[IO.File]::WriteAllBytes($source,[byte[]](1,2,3,4,5))
$hash=Get-Sha256 $source;$script:downloads=0;$script:alwaysBad=$false
function Invoke-WebRequest {
    param([switch]$UseBasicParsing,$Uri,$OutFile,$TimeoutSec,$Headers)
    $script:downloads++
    if($script:alwaysBad -or $script:downloads -eq 1){[IO.File]::WriteAllText($OutFile,'truncated archive')}
    else{[IO.File]::WriteAllBytes($OutFile,[IO.File]::ReadAllBytes($source))}
}
# Use the real validation and atomic replacement, with deterministic HTTP payloads.
$archive=Join-Path $test 'cache.exe';[IO.File]::WriteAllText($archive,'old bad cache')
Get-VerifiedBuilderArchive $archive @('https://primary.test/a','https://fallback.test/a') $hash 5 -DelaySeconds 0
if($script:downloads -ne 2 -or (Get-Sha256 $archive) -ne $hash){throw 'Fallback download failed'}
Get-VerifiedBuilderArchive $archive @('https://offline.test/a') $hash 5 -DelaySeconds 0
if($script:downloads -ne 2){throw 'Valid archive cache was not reused'}
$script:alwaysBad=$true
Assert-Throws {Get-VerifiedBuilderArchive $archive @('https://bad.test/a') ('F'*64) 5 -DelaySeconds 0} 'after 3 attempts'
if((Get-Sha256 $archive) -ne $hash){throw 'Failed download damaged the old cache'}
$lock=Join-Path $test 'lock';$handle=Enter-BuilderLock $lock
try{Assert-Throws {Enter-BuilderLock $lock} 'Another installer'}finally{$handle.Dispose()}
$handle=Enter-BuilderLock $lock;$handle.Dispose()
$native="$env:SystemRoot/System32/WindowsPowerShell/v1.0/powershell.exe"
Invoke-Checked $native @('-NoProfile','-Command',"[Console]::Error.WriteLine('ordinary compiler warning'); exit 0")
Assert-Throws {Invoke-Checked $native @('-NoProfile','-Command',"[Console]::Error.WriteLine('actual compiler error'); exit 7")} 'actual compiler error'
Assert-Throws {Invoke-Checked (Join-Path $test 'nonexistent.exe') @()} 'missing or cannot'
$root=Join-Path $test 'builder';$dump=Join-Path $test 'dump';$out=Join-Path $test 'install';$tools=Join-Path $test 'tools/msys64'
Test-BuilderPreflight $root $dump $out $tools
Assert-Throws {Test-BuilderPreflight $root $dump (Join-Path $dump 'bad') $tools} 'outside'
Assert-Throws {Test-BuilderPreflight $root $dump $out (Join-Path $dump 'bad-tools')} 'separate'
Assert-Throws {Test-BuilderPreflight $root $dump (Join-Path $test 'bad;path') $tools} 'semicolon'
if(!(Get-BuilderToolProblems (Join-Path $test 'empty-cache'))){throw 'Missing toolchain was accepted'}
Write-Host 'PASS: pinned fallback/retries, offline reuse, cache preservation, locks, stderr/exit status, writable accented paths, protected folders and missing tools.'
