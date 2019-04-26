<#
    This script search for jpg images in a directory ($path) and reduces its quality.
	
	Author: Ronan Lucio Pereira

	Inspired on the follow posts:
	https://github.com/bpatra/powershell/blob/master/JPegCompressRecursively.ps1
	https://www.lewisroberts.com/2015/01/18/powershell-image-resize-function/
#>

$testMode     = $false
$count        = 0

# Resize big images (true) or just reduce image quality (false)
# If true, images larger than maxWidth or maxHeight will be resized to maxWidth or maxHeight, preserving its aspect ratio
$resizeBigImages = $false
$maxWidth        = 0
$maxHeight       = 0

# Quality percentage for the target image
$imageQuality = 60

# Directory to be scanned for big images
$path   = ".\"

# Temp dir where temporary new image files will be created (and second moved from)
# Type fullpath (don't ask me why)
$tmpDir = "D:\Workspace\tmp\"

# Get only images greater than
$maxSize = 300
$unit    = "KB"

if ($testMode) {
	Write-Host "TEST MODE: Files will NOT be changed"
} elseif (!(Test-Path -Path $tmpDir)) {
    New-Item -ItemType Directory -Force -Path $tmpDir
}

Add-Type -AssemblyName System.Drawing

Get-ChildItem -Path $path/* -Include *.jpg -Recurse | Where-Object {
    ($_.Length / "1$unit") -gt $maxSize   # List files greater than specific size

} | ForEach-Object {
    # Load original image
	$img       = [System.Drawing.Image]::FromFile($_.FullName)
	$newWidth  = $img.Width
	$newHeight = $img.Height

	# Encoder parameter for image quality
	$imageEncoder           = [System.Drawing.Imaging.Encoder]::Quality
	$encoderParams          = New-Object System.Drawing.Imaging.EncoderParameters(1)
	$encoderParams.param[0] = New-Object System.Drawing.Imaging.EncoderParameter($imageEncoder, $imageQuality)
	
	# get codec
	$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object {$_.MimeType -eq 'image/jpeg'}
	
	<#
	if (resizeBigImages and ($img.Width -gt $maxWidth or $img.Height -gt $maxHeight)) {
		# Compute the final ratio to use
		$ratioX = $CanvasWidth / $img.Width;
		$ratioY = $CanvasHeight / $img.Height;
		
		$ratio = $ratioY
		if ($ratioX -le $ratioY) {
			$ratio = $ratioX
		}
		
		$newWidth = [int] ($img.Width * $ratio)
		$newHeight = [int] ($img.Height * $ratio
	}
	#>

	$_.FullName
    Write-Host "image:", $_.Name, "- width:", $newWidth, "- height:", $newHeight

    # Create new image
    $newFileName    = $tmpDir + $_.Name
    $newImage       = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
	$graph          = [System.Drawing.Graphics]::FromImage($newImage)
	$graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

	$graph.Clear([System.Drawing.Color]::White)
	$graph.DrawImage($img, 0, 0, $newWidth, $newHeight)
    $graph.Dispose()
    $img.Dispose()
    
	if (!$testMode) {
		$newImage.Save($newFileName, $codec, $($encoderParams)) 
		Write-Host $newFileName, "is supposed to be reduced"

    	# OVERRIDE ORIGINAL IMAGE
    	Move-Item -Path $newFileName -Destination $_.FullName -Force
	} else {
		$newFileName
	}

    "-----"
    $count++
}

Write-Host $count, "files"