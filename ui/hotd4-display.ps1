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

function Get-Hotd4RenderSize([int] $Width, [int] $Height) {
    # Keep the arcade viewport, camera and HUD on the same 16:9 canvas.
    $unit = [int][Math]::Floor([Math]::Min(240, [Math]::Min($Width / 16.0, $Height / 9.0)))
    if ($unit -lt 40) { throw 'Select a resolution of at least 640 × 360.' }
    return (16 * $unit), (9 * $unit)
}
