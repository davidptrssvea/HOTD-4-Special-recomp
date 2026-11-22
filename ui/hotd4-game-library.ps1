param([switch]$RegisterOnly,[string]$LibraryRecompDir,[ValidateSet('Normal','Special')][string]$LibraryGame='Normal')

# WPF event closures use dynamic modules. Prefixed helpers must also be visible
# when the menu is hosted inside a CMD scriptblock or an embedded runspace.
function global:Get-Hotd4LibraryPath {
    return Join-Path $env:LOCALAPPDATA 'HOTD4-Launcher/installations.json'
}

function global:Resolve-Hotd4Installation {
    param([string]$Path,[ValidateSet('Normal','Special')][string]$Game)
    if(!$Path){return}
    try {
        $root=[IO.Path]::GetFullPath($Path)
        if([IO.File]::Exists($root)){$root=Split-Path $root -Parent}
        $folder=if($Game -eq 'Normal'){'HOTD4_Recomp'}else{'HOTD4SP_Recomp'}
        $package=if($Game -eq 'Normal'){'HOTD4-PC'}else{'HOTD4SP-PC'}
        foreach($candidate in @($root,(Join-Path $root $folder),(Join-Path (Join-Path $root $package) $folder))){
            $exe=if($Game -eq 'Normal'){'hotd4-desktop.exe'}else{'hotd4sp-desktop.exe'}
            $menu=if($Game -eq 'Normal'){'hotd4-startmenu.ps1'}else{'hotd4sp-startmenu.ps1'}
            $entry=if($Game -eq 'Normal'){Join-Path (Split-Path $candidate -Parent) 'Play HOTD4.exe'}else{Join-Path $candidate 'Play HOTD4 Special.exe'}
            if([IO.File]::Exists((Join-Path $candidate $exe)) -and [IO.File]::Exists((Join-Path $candidate $menu)) -and [IO.File]::Exists($entry)){
                return [IO.Path]::GetFullPath($candidate).TrimEnd('\','/')
            }
        }
    }catch{Write-Verbose $_.Exception.Message}
}

function global:Read-Hotd4Library {
    param([string]$LibraryFile=(Get-Hotd4LibraryPath))
    $result=@{}
    try {
        if([IO.File]::Exists($LibraryFile)){
            $data=[IO.File]::ReadAllText($LibraryFile) | ConvertFrom-Json
            if($data.Version -eq 1){
                foreach($game in 'Normal','Special'){
                    $property=$data.PSObject.Properties[$game]
                    if($property -and $property.Value -is [string]){$result[$game]=$property.Value}
                }
            }
        }
    }catch{Write-Verbose ('Could not read the game library: '+$_.Exception.Message)}
    return $result
}

function global:Register-Hotd4Installation {
    param([string]$RecompDir,[ValidateSet('Normal','Special')][string]$Game,[string]$LibraryFile=(Get-Hotd4LibraryPath))
    $resolved=Resolve-Hotd4Installation $RecompDir $Game
    if(!$resolved){throw 'Choose an installed game folder containing its launcher and desktop executable.'}
    $directory=Split-Path $LibraryFile -Parent
    [void][IO.Directory]::CreateDirectory($directory)
    $lock=$null;$pending=$LibraryFile+'.'+[Guid]::NewGuid().ToString('N')+'.tmp'
    try {
        for($attempt=0;$attempt -lt 10;$attempt++){
            try{$lock=[IO.File]::Open(($LibraryFile+'.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None);break}
            catch{if($attempt -eq 9){throw};Start-Sleep -Milliseconds 100}
        }
        $data=Read-Hotd4Library $LibraryFile;$data.Version=1;$data[$Game]=$resolved
        [IO.File]::WriteAllText($pending,($data | ConvertTo-Json),[Text.UTF8Encoding]::new($false))
        if([IO.File]::Exists($LibraryFile)){[IO.File]::Replace($pending,$LibraryFile,[NullString]::Value)}else{[IO.File]::Move($pending,$LibraryFile)}
    }finally{
        if($lock){$lock.Dispose()}
        if([IO.File]::Exists($pending)){[IO.File]::Delete($pending)}
    }
}

function global:Find-Hotd4OtherInstallation {
    param([string]$RecompDir,[ValidateSet('Normal','Special')][string]$CurrentGame,[string]$LibraryFile=(Get-Hotd4LibraryPath))
    $other=if($CurrentGame -eq 'Normal'){'Special'}else{'Normal'}
    $data=Read-Hotd4Library $LibraryFile
    if($data.ContainsKey($other)){
        $resolved=Resolve-Hotd4Installation $data[$other] $other
        if($resolved){return $resolved}
    }
    $parent=Split-Path ([IO.Path]::GetFullPath($RecompDir)) -Parent
    foreach($nearby in @($parent,(Split-Path $parent -Parent))){
        if($nearby){$resolved=Resolve-Hotd4Installation $nearby $other;if($resolved){return $resolved}}
    }
}

function global:New-Hotd4GameStartInfo {
    param([string]$RecompDir,[ValidateSet('Normal','Special')][string]$Game,[string]$PreviousRecompDir)
    $resolved=Resolve-Hotd4Installation $RecompDir $Game
    if(!$resolved){throw 'The other game was moved or is incomplete. Use Locate other game to select it again.'}
    $entry=if($Game -eq 'Normal'){Join-Path (Split-Path $resolved -Parent) 'Play HOTD4.exe'}else{Join-Path $resolved 'Play HOTD4 Special.exe'}
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$entry;$info.WorkingDirectory=Split-Path $entry -Parent
    $info.UseShellExecute=$false;$info.CreateNoWindow=$true
    # Every game starts with its own settings, cabinet state and dump paths.
    foreach($key in @($info.EnvironmentVariables.Keys)){
        if($key -match '^(HOTD4_|HOTD4SP_|LINDBERGH_|RECOMP_)' -or $key -eq 'TEA_DIR'){$info.EnvironmentVariables.Remove($key)}
    }
    if($PreviousRecompDir){
        $parts=@($info.EnvironmentVariables['PATH'] -split ';' | Where-Object {$_.TrimEnd('\','/') -ine $PreviousRecompDir.TrimEnd('\','/')})
        $info.EnvironmentVariables['PATH']=$parts -join ';'
    }
    return $info
}

function global:Add-Hotd4GameSwitcher {
    param($Window,$MainPage,[string]$RecompDir,[ValidateSet('Normal','Special')][string]$CurrentGame)
    try{Register-Hotd4Installation $RecompDir $CurrentGame}catch{Write-Verbose $_.Exception.Message}
    $switch=@{Other=Find-Hotd4OtherInstallation $RecompDir $CurrentGame}
    $otherGame=if($CurrentGame -eq 'Normal'){'Special'}else{'Normal'}
    $panel=[Windows.Controls.StackPanel]::new();$panel.Margin=[Windows.Thickness]::new(0,0,0,12)
    $heading=[Windows.Controls.DockPanel]::new();$heading.Margin=[Windows.Thickness]::new(0,0,0,6)
    $locate=[Windows.Controls.Button]::new();$locate.Name='LocateOtherGame';$locate.Content='Locate other game...'
    $locate.FontSize=12;$locate.Height=23;$locate.Padding=[Windows.Thickness]::new(8,0,8,0);$locate.Margin=[Windows.Thickness]::new(0)
    [Windows.Controls.DockPanel]::SetDock($locate,'Right');[void]$heading.Children.Add($locate)
    $label=[Windows.Controls.TextBlock]::new();$label.Text='SELECT GAME';$label.FontSize=12;$label.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#C3B7AE');$label.VerticalAlignment='Center'
    [void]$heading.Children.Add($label);[void]$panel.Children.Add($heading)
    $row=[Windows.Controls.Primitives.UniformGrid]::new();$row.Columns=2
    $buttons=@{}
    foreach($game in 'Normal','Special'){
        $button=[Windows.Controls.Button]::new();$button.Name=if($game -eq 'Normal'){'SelectNormalGame'}else{'SelectSpecialGame'}
        $button.Content=if($game -eq 'Normal'){'HOTD4'}else{'HOTD4 SPECIAL'}
        $button.Height=38;$button.FontSize=15;$button.Padding=[Windows.Thickness]::new(12,0,8,0)
        $button.Margin=if($game -eq 'Normal'){[Windows.Thickness]::new(0,0,5,0)}else{[Windows.Thickness]::new(5,0,0,0)}
        if($game -eq $CurrentGame){$button.IsEnabled=$false;$button.Background=[Windows.Media.BrushConverter]::new().ConvertFromString('#9C3436')}
        $buttons[$game]=$button;[void]$row.Children.Add($button)
    }
    [void]$panel.Children.Add($row);$MainPage.Children.Insert(0,$panel)
    $refresh={
        $button=$buttons[$otherGame]
        $button.IsEnabled=[bool]$switch.Other
        $button.Opacity=if($switch.Other){1.0}else{0.45}
        $button.ToolTip=if($switch.Other){'Open the other game menu'}else{'Use Locate other game to select your installation'}
    }.GetNewClosure()
    & $refresh
    $buttons[$otherGame].Add_Click({
        try {
            $info=New-Hotd4GameStartInfo $switch.Other $otherGame $RecompDir
            $process=[Diagnostics.Process]::Start($info)
            if(!$process){throw 'Could not open the other game.'}
            $process.Dispose();$Window.Close()
        }catch{
            [void][Windows.MessageBox]::Show($Window,$_.Exception.Message,'Game Library','OK','Error')
        }
    }.GetNewClosure())
    $locate.Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $dialog=[Windows.Forms.FolderBrowserDialog]::new()
        $dialog.Description=if($otherGame -eq 'Normal'){'Select your installed HOTD4 folder or HOTD4_Recomp folder.'}else{'Select your installed HOTD4 Special folder or HOTD4SP_Recomp folder.'}
        $dialog.ShowNewFolderButton=$false
        try {
            if($dialog.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){
                $resolved=Resolve-Hotd4Installation $dialog.SelectedPath $otherGame
                if(!$resolved){throw 'This is not a complete installation of the other game. Select the installed game, rather than the builder or original dump.'}
                Register-Hotd4Installation $resolved $otherGame
                $switch.Other=$resolved;& $refresh
            }
        }catch{[void][Windows.MessageBox]::Show($Window,$_.Exception.Message,'Game Library','OK','Error')}
        finally{$dialog.Dispose()}
    }.GetNewClosure())
}

if($RegisterOnly){Register-Hotd4Installation $LibraryRecompDir $LibraryGame}
