function ConvertTo-Hotd4Resolution([string] $Value) {
    if ($Value.Trim() -match '^(auto|Desktop)$') { return 'auto' }
    if ($Value -match '^\s*(\d{3,5})\s*[x×]\s*(\d{3,5})\s*$') {
        $width = [int]$Matches[1]
        $height = [int]$Matches[2]
        if ($width -ge 640 -and $height -ge 360 -and $width -le 8192 -and $height -le 8192) {
            return ('{0}x{1}' -f $width, $height)
        }
    }
}

function Get-Hotd4AspectRatio([string]$RecompDir) {
    $file=Join-Path $RecompDir 'aspect-ratio.txt'
    if([IO.File]::Exists($file) -and [IO.File]::ReadAllText($file).Trim() -eq '4:3'){return '4:3'}
    return '16:9'
}
function Get-Hotd4RenderSize([int]$Width,[int]$Height,[ValidateSet('16:9','4:3')][string]$Aspect='16:9') {
    $x,$y,$cap,$minimum=if($Aspect -eq '4:3'){@(4,3,960,160)}else{@(16,9,240,40)}
    $unit=[int][Math]::Floor([Math]::Min($cap,[Math]::Min($Width/[double]$x,$Height/[double]$y)))
    if($unit -lt $minimum){throw $(if($Aspect -eq '4:3'){'Select at least 640 x 480 for 4:3.'}else{'Select at least 640 x 360 for 16:9.'})}
    return ($x*$unit),($y*$unit)
}
