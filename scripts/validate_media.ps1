<#
.SYNOPSIS
    Windows Native Media Validator for KIRI Engine 3D Reconstruction.
    Runs on PowerShell 5.1+ (built into Windows 10/11) with ZERO external dependencies.
    No Python, no ffmpeg, no downloads required.
#>

param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Path
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$MAX_SIZE_BYTES = 5 * 1024 * 1024 * 1024  # 5 GB
$MIN_PHOTOS = 20
$MAX_PHOTOS = 300
$MIN_VIDEO_DURATION = 3.0
$MAX_VIDEO_DURATION = 180.0

$IMAGE_EXTS = @(".jpg", ".jpeg", ".png", ".heic", ".heif", ".webp", ".dng", ".tiff", ".tif", ".bmp")
$VIDEO_EXTS = @(".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm")

function Output-Json {
    param ($obj, $exitCode=0)
    $json = $obj | ConvertTo-Json -Compress
    Write-Output $json
    exit $exitCode
}

# Resolve target path
if (-not (Test-Path -LiteralPath $Path)) {
    Output-Json @{ valid = $false; error = "Path does not exist: $Path" } 1
}

$resolvedItem = Get-Item -LiteralPath $Path

function Get-Mp4Duration([string]$filePath) {
    try {
        $stream = [System.IO.File]::OpenRead($filePath)
        $reader = New-Object System.IO.BinaryReader($stream)
        $fileLen = $stream.Length

        while ($stream.Position -lt $fileLen) {
            if (($fileLen - $stream.Position) -lt 8) { break }
            $rawSize = $reader.ReadBytes(4)
            $rawType = $reader.ReadBytes(4)
            [Array]::Reverse($rawSize)
            $atomSize = [System.BitConverter]::ToUInt32($rawSize, 0)
            $atomType = [System.Text.Encoding]::ASCII.GetString($rawType)

            if ($atomSize -eq 1) {
                $extSize = $reader.ReadBytes(8)
                [Array]::Reverse($extSize)
                $atomSize = [System.BitConverter]::ToUInt64($extSize, 0)
                $contentSize = $atomSize - 16
            } elseif ($atomSize -eq 0) {
                $contentSize = $fileLen - $stream.Position
            } else {
                $contentSize = $atomSize - 8
            }

            if ($atomType -eq "moov") {
                $moovEnd = $stream.Position + $contentSize
                while ($stream.Position -lt $moovEnd) {
                    if (($moovEnd - $stream.Position) -lt 8) { break }
                    $sSize = $reader.ReadBytes(4)
                    $sType = $reader.ReadBytes(4)
                    [Array]::Reverse($sSize)
                    $subSize = [System.BitConverter]::ToUInt32($sSize, 0)
                    $subType = [System.Text.Encoding]::ASCII.GetString($sType)

                    if ($subSize -eq 1) {
                        $eSize = $reader.ReadBytes(8)
                        [Array]::Reverse($eSize)
                        $subSize = [System.BitConverter]::ToUInt64($eSize, 0)
                        $subContent = $subSize - 16
                    } elseif ($subSize -eq 0) {
                        $subContent = $moovEnd - $stream.Position
                    } else {
                        $subContent = $subSize - 8
                    }

                    if ($subType -eq "mvhd") {
                        $mvhdBytes = $reader.ReadBytes([Math]::Min($subContent, 32))
                        if ($mvhdBytes.Length -ge 20) {
                            $ver = $mvhdBytes[0]
                            if ($ver -eq 1 -and $mvhdBytes.Length -ge 32) {
                                $tsBytes = $mvhdBytes[20..23]
                                $durBytes = $mvhdBytes[24..31]
                                [Array]::Reverse($tsBytes)
                                [Array]::Reverse($durBytes)
                                $ts = [System.BitConverter]::ToUInt32($tsBytes, 0)
                                $dur = [System.BitConverter]::ToUInt64($durBytes, 0)
                                if ($ts -gt 0) { $stream.Close(); return [double]$dur / [double]$ts }
                            } elseif ($ver -eq 0 -and $mvhdBytes.Length -ge 20) {
                                $tsBytes = $mvhdBytes[12..15]
                                $durBytes = $mvhdBytes[16..19]
                                [Array]::Reverse($tsBytes)
                                [Array]::Reverse($durBytes)
                                $ts = [System.BitConverter]::ToUInt32($tsBytes, 0)
                                $dur = [System.BitConverter]::ToUInt32($durBytes, 0)
                                if ($ts -gt 0) { $stream.Close(); return [double]$dur / [double]$ts }
                            }
                        }
                        $stream.Close()
                        return -1.0
                    } else {
                        $stream.Seek($subContent, [System.IO.SeekOrigin]::Current) | Out-Null
                    }
                }
                $stream.Close()
                return -1.0
            } else {
                $stream.Seek($contentSize, [System.IO.SeekOrigin]::Current) | Out-Null
            }
        }
        $stream.Close()
    } catch {
        # Fallback to -1
    }
    return -1.0
}

# Single file check
if (-not $resolvedItem.PSIsContainer) {
    $ext = $resolvedItem.Extension.ToLower()
    $sizeBytes = $resolvedItem.Length
    $sizeGb = [Math]::Round($sizeBytes / (1024*1024*1024), 3)

    if ($VIDEO_EXTS -contains $ext) {
        if ($sizeBytes -gt $MAX_SIZE_BYTES) {
            Output-Json @{
                valid = $false; type = "video"; file = $resolvedItem.FullName
                size_bytes = $sizeBytes; size_gb = $sizeGb
                error = "Video size ($sizeGb GB) exceeds limit of 5 GB."
            } 1
        }

        $duration = Get-Mp4Duration $resolvedItem.FullName
        $durRounded = if ($duration -gt 0) { [Math]::Round($duration, 2) } else { -1.0 }

        if ($duration -le 0) {
            Output-Json @{
                valid = $false; type = "video"; file = $resolvedItem.FullName
                size_bytes = $sizeBytes; size_gb = $sizeGb; duration_seconds = -1
                error = "Could not determine video duration. Ensure file is a valid MP4/MOV video."
            } 1
        }

        if ($duration -lt $MIN_VIDEO_DURATION) {
            Output-Json @{
                valid = $false; type = "video"; file = $resolvedItem.FullName
                size_bytes = $sizeBytes; size_gb = $sizeGb; duration_seconds = $durRounded
                error = "Video duration (${durRounded}s) is shorter than minimum 3 seconds."
            } 1
        }

        if ($duration -gt $MAX_VIDEO_DURATION) {
            Output-Json @{
                valid = $false; type = "video"; file = $resolvedItem.FullName
                size_bytes = $sizeBytes; size_gb = $sizeGb; duration_seconds = $durRounded
                error = "Video duration (${durRounded}s) exceeds maximum 3 minutes (180s)."
            } 1
        }

        Output-Json @{
            valid = $true; type = "video"; file = $resolvedItem.FullName
            size_bytes = $sizeBytes; size_gb = $sizeGb; duration_seconds = $durRounded
            message = "Valid video scan: ${durRounded}s, $sizeGb GB."
        } 0
    } elseif ($IMAGE_EXTS -contains $ext) {
        Output-Json @{
            valid = $false; type = "photo"; file = $resolvedItem.FullName
            error = "Single photo provided. KIRI Engine requires 20-300 photos in a folder for photo reconstruction."
        } 1
    } else {
        Output-Json @{
            valid = $false; error = "Unsupported file type '$ext'."
        } 1
    }
}

# Directory check
$photos = @()
$videos = @()
$totalPhotoBytes = 0

Get-ChildItem -LiteralPath $resolvedItem.FullName -File | ForEach-Object {
    $fileExt = $_.Extension.ToLower()
    if ($IMAGE_EXTS -contains $fileExt) {
        $photos += $_
        $totalPhotoBytes += $_.Length
    } elseif ($VIDEO_EXTS -contains $fileExt) {
        $videos += $_
    }
}

if ($videos.Count -eq 1 -and $photos.Count -eq 0) {
    # If folder contains only 1 video, treat as video
    & $MyInvocation.MyCommand.Definition $videos[0].FullName
    exit $LASTEXITCODE
}

$photoCount = $photos.Count
$totalSizeGb = [Math]::Round($totalPhotoBytes / (1024*1024*1024), 3)

if ($photoCount -lt $MIN_PHOTOS) {
    Output-Json @{
        valid = $false; type = "photo"; directory = $resolvedItem.FullName
        count = $photoCount; size_bytes = $totalPhotoBytes; size_gb = $totalSizeGb
        error = "Found $photoCount photos. KIRI Engine requires between 20 and 300 photos (minimum $MIN_PHOTOS)."
    } 1
}

if ($photoCount -gt $MAX_PHOTOS) {
    Output-Json @{
        valid = $false; type = "photo"; directory = $resolvedItem.FullName
        count = $photoCount; size_bytes = $totalPhotoBytes; size_gb = $totalSizeGb
        error = "Found $photoCount photos. Exceeds the limit of $MAX_PHOTOS photos."
    } 1
}

if ($totalPhotoBytes -gt $MAX_SIZE_BYTES) {
    Output-Json @{
        valid = $false; type = "photo"; directory = $resolvedItem.FullName
        count = $photoCount; size_bytes = $totalPhotoBytes; size_gb = $totalSizeGb
        error = "Total photos size ($totalSizeGb GB) exceeds limit of 5 GB."
    } 1
}

Output-Json @{
    valid = $true; type = "photo"; directory = $resolvedItem.FullName
    count = $photoCount; size_bytes = $totalPhotoBytes; size_gb = $totalSizeGb
    message = "Valid photo scan: $photoCount photos, $totalSizeGb GB."
} 0
