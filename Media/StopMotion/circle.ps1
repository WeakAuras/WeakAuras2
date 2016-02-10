$Height=256
$Width=256
$InnerRadius=0
$OuterRadius=120
$Number = 301 # 101 Frames: First empty
$Output = "circle"

# Create Base Image
$BaseGeometry = [string]$Width + "x" + $Height

$MiddleX = $Width / 2
$MiddleY = $Height / 2

## draws a arc, can't handle 360° or 0° arcs
Function DrawArc($MiddleX, $MiddleY, $InnerRadius, $OuterRadius, $StartAngle, $EndAngle, $FileName)
{
  if ($EndAngle -lt $StartAngle) {
    $TMP = $EndAngle
	$EndAngle = $StartAngle
	$StartAngle = $EndAngle
  }

  $Large = 0
  if ($($EndAngle - $StartAngle) -gt 180) {
    $Large = 1
  }

  $StartRadians = [math]::pi * 2 * $StartAngle / 360
  $EndRadians = [math]::pi * 2 * $EndAngle / 360

  if ($StartAngle -ne $EndAngle) {
    # Start Outer Coordinates
    $SXO = [math]::sin($StartRadians) * $OuterRadius + $MiddleX
    $SYO = -[math]::cos($StartRadians) * $OuterRadius + $MiddleY
    # Start Inner Coordinates
    $SXI = [math]::sin($StartRadians) * $InnerRadius + $MiddleX
    $SYI = -[math]::cos($StartRadians) * $InnerRadius + $MiddleY
    
    # End Outer Coordinates
    $EXO = [math]::sin($EndRadians) * $OuterRadius + $MiddleX
    $EYO = -[math]::cos($EndRadians) * $OuterRadius + $MiddleY
    # End Inner Coordinates
    $EXI = [math]::sin($EndRadians) * $InnerRadius + $MiddleX
    $EYI = -[math]::cos($EndRadians) * $InnerRadius + $MiddleY
    
    $Paths = "path  'M "+ $SXI + "," + $SYI + " "
    # Inner Arc
    $Paths = $Paths + "A " + $InnerRadius + "," + $InnerRadius + " 0 "
    $Paths = $Paths + [string]$Large + ",1 "
    $Paths = $Paths + $EXI + "," + $EYI + " "
    # Angled Straight Line
    $Paths = $Paths + "L " + $EXO + "," + $EYO + " "
    # Outer Arc
    $Paths = $Paths + "A " + $OuterRadius + "," + $OuterRadius + " 0 "
    $Paths = $Paths + [string]$Large + ",0 "
    $Paths = $Paths + $SXO + "," + $SYO + " "
    # Straight Line
    $Paths = $Paths + "Z "
    
    $Paths = $Paths + "'"
    convert $FileName -fill white -draw $Paths -gamma 2.2 -compress RLE $FileName
  }
}

# Create individual frames
for ($i=0; $i -lt $Number; $i++) {
  $TMP = "{0:D3}" -f $($i + 1)
  $OutputName = $Output + $TMP + ".tga"

  $Angle = 360 / $($Number - 1) * $i
  convert -size $BaseGeometry xc:transparent -compress RLE $OutputName

  if ($i -eq 0) {
     ## Do nothing
  } elseif ($i -eq $($Number - 1)) {
    DrawArc $MiddleX $MiddleY $InnerRadius $OuterRadius 0 180 $OutputName
	DrawArc $MiddleX $MiddleY $InnerRadius $OuterRadius 180 360 $OutputName
  } else {
    DrawArc $MiddleX $MiddleY $InnerRadius $OuterRadius 0 $Angle $OutputName
  }

}
