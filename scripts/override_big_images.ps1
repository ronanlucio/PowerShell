<#
    This script search for big images in a directory ($path) and override it with a blank one.
    The main purpose is to reduce the used space in the hard disk.
	
	ATTENTION:
	You will definitely loose your images, so, use it in a environment that allows it.
	
	Author: Ronan Lucio Pereira
#>

$testMode = $TRUE
$count    = 0

# Directory to be scanned for big images
$path   = ".\"

# Temp dir where temporary new image files will be created (and second moved from)
# Type fullpath (don't ask me why)
$tmpDir = "D:\Workspace\tmp\"

# Modificar apenas as imagens maiores do que o tamanho abaixo
$maxSize = 500
$unit    = "KB"

if ($testMode) {
	Write-Host "TEST MODE: Files will NOT be changed"
} elseif (!(Test-Path -Path $tmpDir)) {
    New-Item -ItemType Directory -Force -Path $tmpDir
}

Add-Type -AssemblyName System.Drawing

Get-ChildItem -Path $path/* -Include *.jpg, *.gif, *.png -Recurse | Where-Object {
    ($_.Length / "1$unit") -gt $maxSize   # List files greater than 5KB

} | foreach-Object {
    # Load original image
    $img    = New-Object System.Drawing.Bitmap $_.FullName

    $_.FullName
    Write-Host "image:", $_.Name, "- width:", $img.Width, "- height:", $img.Height

    # Create new image
    $newFileName    = $tmpDir + $_.Name
    $newImage       = New-Object System.Drawing.Bitmap $img.Width,$img.Height
    $font           = New-Object System.Drawing.Font Consolas,24
    $brushBg        = [System.Drawing.Brushes]::WhiteSmoke 
    $brushFg        = [System.Drawing.Brushes]::Gray
    $graphics       = [System.Drawing.Graphics]::FromImage($newImage) 
    $graphics.FillRectangle( $brushBg, 0, 0, $newImage.Width, $newImage.Height ) 
    $graphics.DrawString( $_.Name, $font, $brushFg, 10, 10 ) 
    $graphics.Dispose()
    $img.Dispose()
    
	if (!$testMode) {
		$newImage.Save("$newFileName") 
		Write-Host $newFileName, "is supposed to be moved to", $_.FullName

    	# OVERRIDE ORIGINAL IMAGE
    	Move-Item -Path $newFileName -Destination $_.FullName -Force
	} else {
		$newFileName
	}

    "-----"
    $count++
}

Write-Host $count, "files"