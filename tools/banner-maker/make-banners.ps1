# =========================================================
# ETERNO BANNER MAKER
# Builds the email photos: graded photo + forest gradient + logo/text drawn INTO
# the image, so the email looks identical in every email app.
#
# Photos to use  -> sources\   (originals, any size)
# Fonts          -> fonts\     (Cormorant Garamond + Montserrat, free OFL licence)
# Finished files -> ..\..\images\   (what email.html loads)
#
# To change a banner, edit the "BANNERS" section at the bottom, then run:
#   powershell -ExecutionPolicy Bypass -File tools\banner-maker\make-banners.ps1
# =========================================================
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'sources'
$fd  = Join-Path $PSScriptRoot 'fonts'
$Out = (Resolve-Path (Join-Path $PSScriptRoot '..\..\images')).Path

$script:keep = @()
function Load-Font($file, $size, $style = 'Regular') {
  $pfc = New-Object System.Drawing.Text.PrivateFontCollection
  $pfc.AddFontFile((Join-Path $fd $file))
  $script:keep += , $pfc
  New-Object System.Drawing.Font $pfc.Families[0], $size, ([System.Drawing.FontStyle]$style), ([System.Drawing.GraphicsUnit]::Pixel)
}

# ---- Western Ghats colour grade: slightly muted, a touch more contrast, warm highlights ----
$s = 0.90; $c = 1.08; $t = (1 - $c) / 2; $tint = @(1.04, 1.01, 0.94); $lift = 0.012
$lum = @(0.3086, 0.6094, 0.0820)
$rows = New-Object 'single[][]' 5
for ($i = 0; $i -lt 3; $i++) {
  $row = New-Object 'single[]' 5
  for ($j = 0; $j -lt 3; $j++) { $v = $lum[$i] * (1 - $s); if ($i -eq $j) { $v += $s }; $row[$j] = [single]($v * $c * $tint[$j]) }
  $rows[$i] = $row
}
$rows[3] = [single[]]@(0, 0, 0, 1, 0)
$rows[4] = [single[]]@((($t+$lift)*$tint[0]), (($t+$lift)*$tint[1]), (($t+$lift)*$tint[2]), 0, 1)
$matrix = New-Object System.Drawing.Imaging.ColorMatrix(,$rows)
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$forest = [System.Drawing.Color]::FromArgb(255, 15, 31, 23)
$gold = [System.Drawing.Color]::FromArgb(255, 214, 178, 110)
$white = [System.Drawing.Color]::White
$fmt = [System.Drawing.StringFormat]::GenericTypographic.Clone()
$fmt.FormatFlags = $fmt.FormatFlags -bor [System.Drawing.StringFormatFlags]::MeasureTrailingSpaces

# Crop a photo to w x h around focus point (fx, fy = 0..1) and apply the grade
function New-Canvas($file, $w, $h, $fx, $fy) {
  $img = [System.Drawing.Image]::FromFile((Join-Path $src $file))
  $scale = [math]::Max($w / $img.Width, $h / $img.Height)
  $cw = $w / $scale; $ch = $h / $scale
  $sx = [math]::Min([math]::Max($fx * $img.Width - $cw / 2, 0), $img.Width - $cw)
  $sy = [math]::Min([math]::Max($fy * $img.Height - $ch / 2, 0), $img.Height - $ch)
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = 'HighQualityBicubic'; $g.SmoothingMode = 'HighQuality'; $g.PixelOffsetMode = 'HighQuality'
  $g.TextRenderingHint = 'AntiAlias'
  $attr = New-Object System.Drawing.Imaging.ImageAttributes; $attr.SetColorMatrix($matrix)
  $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $w, $h), [single]$sx, [single]$sy, [single]$cw, [single]$ch, 'Pixel', $attr)
  $img.Dispose()
  return @($bmp, $g)
}

# Vertical forest-green gradient: alpha a1 at y1 -> alpha a2 at y2
function Shade($g, $w, $y1, $y2, $a1, $a2) {
  $rect = New-Object System.Drawing.Rectangle 0, ([int]$y1 - 1), $w, ([int]($y2 - $y1) + 2)
  $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb($a1, $forest)), ([System.Drawing.Color]::FromArgb($a2, $forest)), 90
  $g.FillRectangle($br, 0, [int]$y1, $w, [int]($y2 - $y1)); $br.Dispose()
}

function Width-Tracked($g, $text, $font, $track) {
  $w = 0; foreach ($ch in $text.ToCharArray()) { $w += $g.MeasureString([string]$ch, $font, [System.Drawing.PointF]::Empty, $fmt).Width + $track }
  return $w - $track
}

# Draw text with letter-spacing and a soft shadow. align: left | center
function Text($g, $text, $font, $color, $x, $y, $track = 0, $align = 'left', $shadow = 90) {
  $w = Width-Tracked $g $text $font $track
  if ($align -eq 'center') { $x = $x - $w / 2 }
  $sb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($shadow, 0, 0, 0))
  $b = New-Object System.Drawing.SolidBrush $color
  foreach ($pass in 0, 1) {
    $cx = $x
    foreach ($ch in $text.ToCharArray()) {
      if ($pass -eq 0) { if ($shadow -gt 0) { $g.DrawString([string]$ch, $font, $sb, [single]($cx + 2), [single]($y + 3), $fmt) } }
      else { $g.DrawString([string]$ch, $font, $b, [single]$cx, [single]$y, $fmt) }
      $cx += $g.MeasureString([string]$ch, $font, [System.Drawing.PointF]::Empty, $fmt).Width + $track
    }
  }
  $sb.Dispose(); $b.Dispose()
}

function Save($bmp, $g, $name, $q = 78) {
  $p = New-Object System.Drawing.Imaging.EncoderParameters 1
  $p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]$q)
  $bmp.Save((Join-Path $Out $name), $jpeg, $p); $g.Dispose(); $bmp.Dispose()
}

# ---- Logo: cut the gold mark out of the visiting card as a crisp transparent image ----
$card = [System.Drawing.Bitmap]::FromFile((Join-Path $src 'logo-card.jpg'))
$lx = 340; $ly = 178; $lw = 410; $lh = 292
$logo = New-Object System.Drawing.Bitmap $lw, $lh, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt $lh; $y++) { for ($x = 0; $x -lt $lw; $x++) {
  $px = $card.GetPixel($lx + $x, $ly + $y)
  $m = [math]::Max($px.R, [math]::Max($px.G, $px.B))
  $a = [math]::Min(1.0, [math]::Max(0, ($m - 48) / 140.0))
  if ($a -gt 0.01) { $logo.SetPixel($x, $y, [System.Drawing.Color]::FromArgb([int](255 * $a), $gold)) }
} }
$card.Dispose()

$fEyebrow = Load-Font 'mont-600.ttf' 26
$fTitle   = Load-Font 'corm-600.ttf' 82
$fHero    = Load-Font 'corm-500.ttf' 92
$fHeroI   = Load-Font 'corm-500i.ttf' 92 'Italic'
$fCta     = Load-Font 'corm-500.ttf' 70
$fPill    = Load-Font 'mont-600.ttf' 22
$dot = "  $([char]0x00B7)  "       # middle dot
$ap  = [string][char]0x2019        # curly apostrophe

# Property banner (1200x680): place + name bottom-left, optional pill (e.g. COMING SOON)
function Banner($file, $fx, $fy, $place, $name, $outName, $pill) {
  $bg = New-Canvas $file 1200 680 $fx $fy; $bmp = $bg[0]; $g = $bg[1]
  Shade $g 1200 300 680 0 230
  if ($pill) {
    $pw = (Width-Tracked $g $pill $fPill 5) + 40
    $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 154, 80, 52))
    $g.FillRectangle($br, 72, 438, [int]$pw, 46); $br.Dispose()
    Text $g $pill $fPill $white 92 449 5 'left' 0
  }
  Text $g $place $fEyebrow $gold 74 520 7
  Text $g $name $fTitle $white 70 550 0 'left' 110
  Save $bmp $g $outName
}

# Small room photo (400x300), graded, no text
function Thumb($file, $fx, $fy, $outName) {
  $bg = New-Canvas $file 400 300 $fx $fy
  Save $bg[0] $bg[1] $outName
}

# =========================================================
# BANNERS: edit text / photos here
# =========================================================

# Hero (1200x900): logo at top, headline at bottom
$bg = New-Canvas 'hero-forest-drone.jpg' 1200 900 0.45 0.55; $bmp = $bg[0]; $g = $bg[1]
Shade $g 1200 0 330 175 0
Shade $g 1200 470 900 0 235
$dw = 300; $dh = [int]($lh * $dw / $lw)
$g.DrawImage($logo, [int]((1200 - $dw) / 2), 52, $dw, $dh)
Text $g 'WITH GRATITUDE' $fEyebrow $gold 72 640 7
Text $g 'Thank you for a' $fHero $white 70 682 0 'left' 110
Text $g 'truly warm welcome' $fHeroI $white 70 772 0 'left' 110
Save $bmp $g 'hero.jpg'

Banner 'camellia-cottages.jpg'  0.55 0.55 "BISON VALLEY${dot}MUNNAR" 'Eterno Camellia & Elettaria' 'camellia.jpg' $null
Banner 'capithans-building.jpg' 0.50 0.52 "SURYANELLI${dot}MUNNAR"   'Capithans Dale'              'capithans.jpg' $null
Banner 'vagamon-view.jpg'       0.50 0.45 'VAGAMON'                  'Eterno Mont Bungalow'        'mont-bungalow.jpg' 'COMING SOON'

# Closing banner (1200x420): headline centred, fades into the dark band below it
$bg = New-Canvas 'night-valley.jpg' 1200 420 0.5 0.45; $bmp = $bg[0]; $g = $bg[1]
Shade $g 1200 0 420 70 150
Shade $g 1200 250 420 0 255
Text $g "LET${ap}S CONNECT" $fEyebrow $gold 600 214 7 'center'
Text $g "Plan your guests$ap next escape" $fCta $white 600 256 0 'center' 110
Save $bmp $g 'cta.jpg' 80

Thumb 'flora-treehouse.jpg'   0.50 0.50 'flora.jpg'
Thumb 'loft-treehouse.jpg'    0.56 0.45 'treehouse.jpg'
Thumb 'valley-view-block.jpg' 0.48 0.50 'valley-view.jpg'

$logo.Dispose()
Get-ChildItem $Out | ForEach-Object { "{0,-20} {1} KB" -f $_.Name, [math]::Round($_.Length/1KB) }
