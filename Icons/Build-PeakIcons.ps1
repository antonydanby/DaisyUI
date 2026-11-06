# Builds the palette icons of the "Peak SVG" section.
#   Icons\PeakSVGImage.bmp, Icons\PeakSVGImageList.bmp  (24 x 24, 3 colours + transparent key)
#   Source\Peak\Peak.SVG.Reg.dcr                         (resource names = upper case class names)
# Needs C:\Program Files (x86)\Embarcadero\Studio\37.0\bin64 for cgrc.exe.
# Optional: -Preview <folder> also writes 10x enlarged PNG previews.
param([string]$Preview = '')

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$iconDir = Join-Path $root 'Icons'
$bin = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin64'

$key    = [System.Drawing.Color]::FromArgb(255, 0, 255)   # transparent (bottom left pixel)
$grey   = [System.Drawing.Color]::FromArgb(62, 67, 72)    # base colour
$white  = [System.Drawing.Color]::FromArgb(255, 255, 255)
$accent = [System.Drawing.Color]::FromArgb(0, 176, 240)

function New-Tile {
    $b = New-Object System.Drawing.Bitmap 24, 24, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    for ($y = 0; $y -lt 24; $y++) { for ($x = 0; $x -lt 24; $x++) { $b.SetPixel($x, $y, $key) } }
    for ($y = 1; $y -le 22; $y++) { for ($x = 1; $x -le 22; $x++) { $b.SetPixel($x, $y, $grey) } }
    foreach ($p in @(@(1,1), @(22,1), @(1,22), @(22,22))) { $b.SetPixel($p[0], $p[1], $key) }
    return $b
}

function Fill($b, $x, $y, $w, $h, $c) {
    for ($j = $y; $j -lt $y + $h; $j++) { for ($i = $x; $i -lt $x + $w; $i++) { $b.SetPixel($i, $j, $c) } }
}

function Frame($b, $x, $y, $w, $h, $c) {
    Fill $b $x $y $w 1 $c
    Fill $b $x ($y + $h - 1) $w 1 $c
    Fill $b $x $y 1 $h $c
    Fill $b ($x + $w - 1) $y 1 $h $c
}

# filled triangle: apex at (ax, ay), growing one pixel each side per row, clipped to [x0, x1]
function Mountain($b, $ax, $ay, $yEnd, $x0, $x1, $c) {
    for ($y = $ay; $y -le $yEnd; $y++) {
        $half = $y - $ay
        for ($x = [Math]::Max($x0, $ax - $half); $x -le [Math]::Min($x1, $ax + $half); $x++) { $b.SetPixel($x, $y, $c) }
    }
}

# TPeakSVGImage: a picture with vector anchor handles on its corners
$img = New-Tile
Frame $img 4 5 16 14 $white
Mountain $img 11 9 17 5 18 $accent
Mountain $img 16 13 17 5 18 $white
Fill $img 6 7 2 2 $white
foreach ($p in @(@(4,5), @(19,5), @(4,18), @(19,18))) {
    Fill $img ($p[0] - 1) ($p[1] - 1) 3 3 $white
    $img.SetPixel($p[0], $p[1], $accent)
}

# TPeakSVGImageList: two stacked pictures
$list = New-Tile
Frame $list 9 4 11 9 $white
Fill $list 10 5 9 7 $grey
Mountain $list 15 6 9 10 18 $white
Fill $list 4 9 12 11 $accent
Frame $list 4 9 12 11 $white
Mountain $list 9 12 17 5 14 $white
Fill $list 12 11 2 2 $white

$icons = @{ 'PeakSVGImage' = $img; 'PeakSVGImageList' = $list }
$rc = Join-Path $iconDir 'Peak.SVG.Reg.rc'
$lines = @()
foreach ($name in $icons.Keys) {
    $icons[$name].Save((Join-Path $iconDir "$name.bmp"), [System.Drawing.Imaging.ImageFormat]::Bmp)
    $lines += ('T' + $name.ToUpper() + ' BITMAP "' + $name + '.bmp"')
    if ($Preview -ne '') {
        $big = New-Object System.Drawing.Bitmap 240, 240
        $g = [System.Drawing.Graphics]::FromImage($big)
        $g.InterpolationMode = 'NearestNeighbor'
        $g.PixelOffsetMode = 'Half'
        $g.DrawImage($icons[$name], 0, 0, 240, 240)
        $g.Dispose()
        $big.Save((Join-Path $Preview "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $big.Dispose()
    }
}
Set-Content -Path $rc -Value $lines -Encoding ASCII

$dcr = Join-Path $root 'Source\Peak\Peak.SVG.Reg.dcr'
Push-Location $iconDir
try {
    $env:PATH = $bin + ';' + $env:PATH
    & (Join-Path $bin 'cgrc.exe') '-c65001' '-=' 'resinator.exe' $rc "-fo$dcr" | Out-Null
} finally {
    Pop-Location
    Remove-Item $rc -ErrorAction SilentlyContinue
}
"DCR: " + (Test-Path $dcr)
