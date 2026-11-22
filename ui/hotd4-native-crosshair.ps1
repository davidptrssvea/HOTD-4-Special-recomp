function Initialize-Hotd4NativeCrosshair([string]$RecompDir,[string]$DumpDir) {
    if(!('Hotd4NativeCrosshair' -as [type])) {
        Add-Type -AssemblyName PresentationCore,WindowsBase
        Add-Type -Path (Join-Path $RecompDir 'hotd4-native-crosshair.cs') -ReferencedAssemblies PresentationCore,WindowsBase
    }
    $sourceFile=Join-Path $RecompDir 'native-crosshair-source.txt'
    $sources=@($DumpDir)
    if([IO.File]::Exists($sourceFile)){$sources+=([IO.File]::ReadAllText($sourceFile).Trim())}
    foreach($source in $sources){if(!$source){continue};foreach($candidate in @($source,(Join-Path $source 'disk0'),(Join-Path $source 'game/disk0'))){
        try { if([Hotd4NativeCrosshair]::Ensure($RecompDir,$candidate)){return $true} } catch { Write-Warning "Could not load original crosshair: $($_.Exception.GetBaseException().Message)" }
    }}
    return [Hotd4NativeCrosshair]::IsReady($RecompDir)
}
function Select-Hotd4NativeCrosshairSource([string]$RecompDir,$Owner) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog=New-Object Windows.Forms.FolderBrowserDialog
    $dialog.Description='Select your original HOTD4 arcade dump (Special does not contain the Name Entry crosshair).'
    $dialog.ShowNewFolderButton=$false
    $handle=New-Object Windows.Forms.NativeWindow
    try {
        if($Owner){$handle.AssignHandle(([Windows.Interop.WindowInteropHelper]::new($Owner)).EnsureHandle())}
        $answer=if($Owner){$dialog.ShowDialog($handle)}else{$dialog.ShowDialog()}
        if($answer -ne [Windows.Forms.DialogResult]::OK){return $false}
        if(Initialize-Hotd4NativeCrosshair $RecompDir $dialog.SelectedPath){
            [IO.File]::WriteAllText((Join-Path $RecompDir 'native-crosshair-source.txt'),$dialog.SelectedPath);return $true
        }
        [void][Windows.MessageBox]::Show('Original Name Entry resources were not found. Select the normal HOTD4 dump containing fs\test\playerranking.bnk.','Original Crosshair')
        return $false
    } finally { $handle.ReleaseHandle();$dialog.Dispose() }
}
