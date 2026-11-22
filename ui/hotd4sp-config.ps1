function Read-Hotd4SPConfig([string]$Directory) {
    $values=@{width='1920';height='1080';fullscreen='0';aa='4';af='16';raw_mouse='1';mouse_sens='1.00';mouse_grab='1';crosshair='1';leave_reload='1';muted='0';volume='100'}
    $path=Join-Path $Directory 'lindbergh.ini'
    if(Test-Path -LiteralPath $path){foreach($line in [IO.File]::ReadAllLines($path)){if($line -match '^\s*(\w+)\s*=\s*([^#;]+)'){$values[$Matches[1]]=$Matches[2].Trim()}}}
    return $values
}
function Write-Hotd4SPConfig([string]$Directory,[hashtable]$Changes) {
    $path=Join-Path $Directory 'lindbergh.ini';$remaining=@{};foreach($key in $Changes.Keys){$remaining[$key]=[string]$Changes[$key]}
    $lines=[Collections.Generic.List[string]]::new()
    if(Test-Path -LiteralPath $path){foreach($line in [IO.File]::ReadAllLines($path)){
        if($line -match '^\s*(\w+)\s*=' -and $Changes.ContainsKey($Matches[1])){
            $key=$Matches[1];if($remaining.ContainsKey($key)){$lines.Add("$key = $($remaining[$key])");$remaining.Remove($key)}
        }else{$lines.Add($line)}
    }}
    foreach($key in ($remaining.Keys | Sort-Object)){$lines.Add("$key = $($remaining[$key])")}
    $tmp=$path+'.new';[IO.File]::WriteAllLines($tmp,$lines,[Text.UTF8Encoding]::new($false))
    if([IO.File]::Exists($path)){[IO.File]::Replace($tmp,$path,$path+'.last-save.bak')}else{[IO.File]::Move($tmp,$path)}
}
