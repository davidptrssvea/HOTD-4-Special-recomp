function Get-Hotd4ControlCatalog {
    @(
        @('coin1','Add Coin (P1)',53),@('start1','Start (P1)',49),@('trigger','Shoot',-1),@('reload','Reload',-3),
        @('action','Grenade',32),@('firemode','Fire Mode',102),@('coin2','Add Coin (P2)',54),@('start2','Start (P2)',50),
        @('test','Test Menu',116),@('service','Service',115),@('mute','Mute',109),@('pause','Pause',27),
        @('restart','Restart',1073741887),@('fullscreen','Fullscreen',1073741892),@('crosshair_toggle','Toggle Crosshair',1073741883),@('mouse_lock','Mouse Lock',1073741882),
        @('kb1_up','P1 Aim Up (Keyboard)',1073741906),
        @('kb1_down','P1 Aim Down (Keyboard)',1073741905),
        @('kb1_left','P1 Aim Left (Keyboard)',1073741904),
        @('kb1_right','P1 Aim Right (Keyboard)',1073741903),
        @('kb1_shoot','P1 Shoot (Keyboard)',1073742052),
        @('kb1_reload','P1 Reload / Shake (Keyboard)',1073742053),
        @('kb1_grenade','P1 Grenade (Keyboard)',1073742054),
        @('kb1_firemode','P1 Fire Mode (Keyboard)',1073741901),
        @('kb2_up','P2 Aim Up (Keyboard)',119),
        @('kb2_down','P2 Aim Down (Keyboard)',115),
        @('kb2_left','P2 Aim Left (Keyboard)',97),
        @('kb2_right','P2 Aim Right (Keyboard)',100),
        @('kb2_shoot','P2 Shoot (Keyboard)',32),
        @('kb2_reload','P2 Reload / Shake (Keyboard)',113),
        @('kb2_grenade','P2 Grenade (Keyboard)',101),
        @('kb2_firemode','P2 Fire Mode (Keyboard)',9),
        @('kb_service','Service (Keyboard)',1073741891)
    )
}
function Read-Hotd4Controls([string]$RecompDir){
    $values=[ordered]@{};foreach($row in Get-Hotd4ControlCatalog){$values[$row[0]]=[int]$row[2]}
    $ini=Join-Path $RecompDir 'lindbergh.ini'
    if([IO.File]::Exists($ini)){foreach($line in [IO.File]::ReadAllLines($ini)){
        if($line -match '^\s*(\w+)\s*=\s*(\S+)'){$name=$Matches[1];$v=$Matches[2];if($values.Contains($name) -and $name -notin 'pause','restart','fullscreen','crosshair_toggle','mouse_lock'){
            if($v -match '^mouse([1-5])$'){$values[$name]=-[int]$Matches[1]}
            elseif($v.Length -eq 1){$values[$name]=[int][char]$v}
            elseif($v -match '^\d+$'){$values[$name]=[int]$v}
            elseif($v -eq 'space'){$values[$name]=32}elseif($v -in 'enter','return'){$values[$name]=13}
        }}
    }}
    $file=Join-Path $RecompDir 'controls-profile.txt';$custom=$false
    if([IO.File]::Exists($file)){$lines=[IO.File]::ReadAllLines($file);if($lines.Count -and $lines[0] -eq 'HOTD4-CONTROLS-1'){
        $custom=$true;foreach($line in $lines){if($line -match '^(\w+) (-?\d+)$'){$k=$Matches[1];$v=[int]$Matches[2];if($values.Contains($k) -and ($v -gt 0 -or ($k -in 'trigger','reload','action','firemode' -and $v -ge -5 -and $v -lt 0))){$values[$k]=$v}}}
    }}
    @{Values=$values;Custom=$custom}
}
function Test-Hotd4BindingConflict([string]$A,[string]$B){
    $normal=@('trigger','reload','action','firemode','service')
    return !(($A -in $normal -and $B.StartsWith('kb')) -or ($B -in $normal -and $A.StartsWith('kb')))
}
function Write-Hotd4Controls([string]$RecompDir,$Values){
    $catalog=@(Get-Hotd4ControlCatalog)
    foreach($row in $catalog){$v=[int]$Values[$row[0]];if(!$v -or ($v -lt 0 -and $row[0] -notin 'trigger','reload','action','firemode')){throw "Choose a keyboard key for $($row[1])."}
        foreach($other in $catalog){if($other[0] -ne $row[0] -and [int]$Values[$other[0]] -eq $v -and (Test-Hotd4BindingConflict $row[0] $other[0])){throw "Duplicate binding: $($row[1]) and $($other[1])."}}
    }
    $text="HOTD4-CONTROLS-1`n";foreach($row in Get-Hotd4ControlCatalog){$text+="$($row[0]) $($Values[$row[0]])`n"}
    $dest=Join-Path $RecompDir 'controls-profile.txt';$temp=$dest+'.new'
    [IO.File]::WriteAllText($temp,$text,[Text.UTF8Encoding]::new($false))
    if([IO.File]::Exists($dest)){[IO.File]::Replace($temp,$dest,$dest+'.last-save.bak')}else{[IO.File]::Move($temp,$dest)}
}
function Get-Hotd4BindingName([int]$Value){
    $names=@{(-1)='Left Mouse';(-2)='Middle Mouse';(-3)='Right Mouse';(-4)='Mouse X1';(-5)='Mouse X2';13='Enter';27='Esc';32='Space';9='Tab';8='Backspace';127='Delete';1073741903='Right';1073741904='Left';1073741905='Down';1073741906='Up';1073741897='Insert';1073741898='Home';1073741901='End';1073741899='Page Up';1073741902='Page Down';1073742048='Left Ctrl';1073742049='Left Shift';1073742050='Left Alt';1073742052='Right Ctrl';1073742053='Right Shift';1073742054='Right Alt';1073741881='Caps Lock';1073741896='Pause/Break';1073741894='Print Screen';1073741895='Scroll Lock';1073741907='Num Lock';1073741908='Num /';1073741909='Num *';1073741910='Num -';1073741911='Num +';1073741912='Num Enter';1073741922='Num 0';1073741923='Num .'}
    if($names.ContainsKey($Value)){return $names[$Value]}
    if($Value -ge 1073741882 -and $Value -le 1073741893){return 'F'+($Value-1073741881)}
    if($Value -ge 1073741928 -and $Value -le 1073741939){return 'F'+($Value-1073741915)}
    if($Value -ge 1073741913 -and $Value -le 1073741921){return 'Num '+($Value-1073741912)}
    if($Value -gt 0 -and $Value -lt 65536){return ([char]$Value).ToString().ToUpperInvariant()}
    return "Key $Value"
}
function ConvertTo-Hotd4SdlKey($Key){
    $name=[string]$Key
    if($name -match '^F(\d+)$'){$n=[int]$Matches[1];return 1073741824+$(if($n -le 12){57+$n}else{91+$n})}
    if($name -match '^[A-Z]$'){return [int][char]$name.ToLowerInvariant()}
    if($name -match '^D([0-9])$'){return 48+[int]$Matches[1]}
    if($name -match '^NumPad([0-9])$'){$n=[int]$Matches[1];return 1073741824+$(if($n){88+$n}else{98})}
    $map=@{Return=13;Escape=27;Space=32;Tab=9;Back=8;Delete=127;Right=1073741903;Left=1073741904;Down=1073741905;Up=1073741906;Insert=1073741897;Home=1073741898;End=1073741901;PageUp=1073741899;PageDown=1073741902;LeftCtrl=1073742048;LeftShift=1073742049;LeftAlt=1073742050;RightCtrl=1073742052;RightShift=1073742053;RightAlt=1073742054;Capital=1073741881;CapsLock=1073741881;Pause=1073741896;Snapshot=1073741894;Scroll=1073741895;NumLock=1073741907;Divide=1073741908;Multiply=1073741909;Subtract=1073741910;Add=1073741911;Decimal=1073741923}
    if($map.ContainsKey($name)){return $map[$name]}
    if(-not ('Hotd4KeyLayout' -as [type])){Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public static class Hotd4KeyLayout { [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type); }'}
    $vk=[Windows.Input.KeyInterop]::VirtualKeyFromKey($Key);$code=[Hotd4KeyLayout]::MapVirtualKey($vk,2) -band 65535
    if($code){return [int][char]([char]$code).ToString().ToLowerInvariant()}
    return 0
}
function Get-Hotd4ControlSummary($Data,[int]$Index){
    $row=@(Get-Hotd4ControlCatalog)[$Index];$name=Get-Hotd4BindingName $Data.Values[$row[0]]
    if(!$Data.Custom){switch($row[0]){'coin1' {$name+=' / C / Num 5'}'start1' {if($name -ne 'Enter'){$name+=' / Enter'};$name+=' / Num 1'}'coin2' {$name+=' / Num 6'}'start2' {$name+=' / Num 2'}'fullscreen' {$name+=' / Alt+Enter'}}}
    $name
}
