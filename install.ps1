$ErrorActionPreference = 'Stop'
$ArchiveUrl = 'https://raw.githubusercontent.com/ShengwenXu/opencode-skills-collection/main/skills.zip'
$ExpectedHash = '5be4e6ae10e1739dd6529eac138faf6ee637e236a23a343523b5ad9dff368a1a'
if ($env:XDG_CONFIG_HOME) {
    $ConfigRoot = $env:XDG_CONFIG_HOME
} else {
    $ConfigRoot = Join-Path $HOME '.config'
}
$SkillsRoot = Join-Path $ConfigRoot 'opencode/skills'
$WorkDir = Join-Path ([System.IO.Path]::GetTempPath()) ('opencode-skills-' + [guid]::NewGuid().ToString())
try {
    New-Item -ItemType Directory -Path $WorkDir | Out-Null
    $ArchivePath = Join-Path $WorkDir 'skills.zip'
    Invoke-WebRequest -Uri $ArchiveUrl -OutFile $ArchivePath -UseBasicParsing
    $ActualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ActualHash -ne $ExpectedHash) {
        throw 'Archive checksum mismatch; installation stopped.'
    }
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $WorkDir
    New-Item -ItemType Directory -Force -Path $SkillsRoot | Out-Null
    $Installed = 0
    $Skipped = 0
    Get-ChildItem -LiteralPath (Join-Path $WorkDir 'skills') -Directory | ForEach-Object {
        $SourceDir = $_.FullName
        if (Test-Path -LiteralPath (Join-Path $SourceDir 'SKILL.md')) {
            $Destination = Join-Path $SkillsRoot $_.Name
            if (Test-Path -LiteralPath $Destination) {
                Write-Host "SKIP $($_.Name)"
                $Skipped++
            } else {
                Copy-Item -LiteralPath $SourceDir -Destination $Destination -Recurse
                Write-Host "INSTALLED $($_.Name)"
                $Installed++
            }
        }
    }
    Write-Host "Installed: $Installed; already present: $Skipped"
} finally {
    if (Test-Path -LiteralPath $WorkDir) {
        Remove-Item -LiteralPath $WorkDir -Recurse -Force
    }
}
