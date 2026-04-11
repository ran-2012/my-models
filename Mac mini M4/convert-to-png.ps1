# PowerShell script to convert all images to PNG format in current directory
# Requires ffmpeg to be installed and available in PATH

# Check if ffmpeg is available
$ffmpegPath = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegPath) {
    Write-Host "Error: ffmpeg is not found in PATH. Please install ffmpeg first." -ForegroundColor Red
    Write-Host "Download from: https://ffmpeg.org/download.html" -ForegroundColor Yellow
    exit 1
}

# Create bak directory if it doesn't exist
$bakDir = Join-Path -Path . -ChildPath "bak"
if (-not (Test-Path $bakDir)) {
    New-Item -ItemType Directory -Path $bakDir -Force | Out-Null
    Write-Host "Created 'bak' directory for original files." -ForegroundColor Cyan
}

# Create or update .gitignore file
$gitignorePath = Join-Path -Path . -ChildPath ".gitignore"
$bakIgnoreEntry = "bak/"

if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    if ($gitignoreContent -notmatch [regex]::Escape($bakIgnoreEntry)) {
        Add-Content -Path $gitignorePath -Value "`n$bakIgnoreEntry"
        Write-Host "Added 'bak/' to existing .gitignore file." -ForegroundColor Cyan
    } else {
        Write-Host ".gitignore already contains 'bak/' entry." -ForegroundColor Gray
    }
} else {
    Set-Content -Path $gitignorePath -Value $bakIgnoreEntry
    Write-Host "Created .gitignore file with 'bak/' entry." -ForegroundColor Cyan
}

# Get all image files in the current directory
$imageExtensions = @('*.jpg', '*.jpeg', '*.jfif', '*.bmp', '*.gif', '*.tiff', '*.tif', '*.webp')
$imageFiles = Get-ChildItem -Path . -Recurse -Include $imageExtensions -File

if ($imageFiles.Count -eq 0) {
    Write-Host "No image files found in the current directory." -ForegroundColor Yellow
    exit
}

Write-Host "Found $($imageFiles.Count) image file(s) to convert." -ForegroundColor Cyan

$successCount = 0
$failCount = 0

foreach ($file in $imageFiles) {
    try {
        # Skip if already PNG
        if ($file.Extension -eq '.png') {
            Write-Host "Skipping $($file.Name) - already PNG format" -ForegroundColor Gray
            continue
        }

        # Create output filename
        $outputFileName = [System.IO.Path]::ChangeExtension($file.Name, '.png')
        $outputPath = Join-Path -Path $file.DirectoryName -ChildPath $outputFileName
        
        # Check if output file already exists
        if (Test-Path $outputPath) {
            Write-Host "Warning: $outputFileName already exists. Skipping $($file.Name)" -ForegroundColor Yellow
            continue
        }
        
        # Convert using ffmpeg
        $ffmpegArgs = @(
            '-i', "`"$($file.FullName)`""
            '-y'  # Overwrite output file if it exists
            "`"$outputPath`""
        )
        
        $result = & ffmpeg $ffmpegArgs -hide_banner -loglevel error 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Converted: $($file.Name) → $outputFileName" -ForegroundColor Green
            
            # Move original file to bak directory
            $bakPath = Join-Path -Path $bakDir -ChildPath $file.Name
            Move-Item -Path $file.FullName -Destination $bakPath -Force
            Write-Host "  Moved original to: bak\$($file.Name)" -ForegroundColor Gray
            
            $successCount++
        } else {
            Write-Host "✗ Failed to convert $($file.Name)" -ForegroundColor Red
            if ($result) {
                Write-Host "  Error: $result" -ForegroundColor Red
            }
            $failCount++
        }
        
    } catch {
        Write-Host "✗ Failed to convert $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`nConversion complete!" -ForegroundColor Cyan
Write-Host "Successfully converted: $successCount file(s)" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "Failed: $failCount file(s)" -ForegroundColor Red
}
