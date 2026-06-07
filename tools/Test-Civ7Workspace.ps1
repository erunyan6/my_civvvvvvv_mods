param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$Civ7UserRoot = "$env:LOCALAPPDATA\Firaxis Games\Sid Meier's Civilization VII"
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message) | Out-Null
}

function Add-Warning {
    param([string]$Message)
    $warnings.Add($Message) | Out-Null
}

function Test-XmlFile {
    param([System.IO.FileInfo]$File)
    try {
        $doc = New-Object System.Xml.XmlDocument
        $doc.PreserveWhitespace = $true
        $doc.Load($File.FullName)
        return $doc
    }
    catch {
        Add-Failure "Malformed XML: $($File.FullName) :: $($_.Exception.Message)"
        return $null
    }
}

function Get-Slug {
    param([string]$Value)
    return ($Value.Trim().ToLowerInvariant() -replace "[^a-z0-9]+", "-" -replace "^-|-$", "")
}

function Get-BaseTableNames {
    param([string]$BasePath)
    $names = New-Object System.Collections.Generic.HashSet[string]
    if (-not (Test-Path -LiteralPath $BasePath)) {
        return $names
    }

    Get-ChildItem -Path $BasePath -Recurse -Filter "*.xml" -File | ForEach-Object {
        $doc = Test-XmlFile $_
        if ($null -eq $doc -or $null -eq $doc.DocumentElement) {
            return
        }
        foreach ($node in $doc.DocumentElement.ChildNodes) {
            if ($node.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                $names.Add($node.Name) | Out-Null
            }
        }
    }
    return $names
}

function Get-SteamBuildId {
    $manifest = "C:\Program Files (x86)\Steam\steamapps\appmanifest_1295660.acf"
    if (-not (Test-Path -LiteralPath $manifest)) {
        return $null
    }
    $match = Select-String -LiteralPath $manifest -Pattern '"buildid"\s+"([^"]+)"' | Select-Object -First 1
    if ($null -eq $match) {
        return $null
    }
    return $match.Matches[0].Groups[1].Value
}

$workspaceRoot = (Resolve-Path $WorkspaceRoot).Path
$basePath = Join-Path $workspaceRoot "Civ7BaseAssets"
$modsPath = Join-Path $workspaceRoot "mods"
$currentBuildId = Get-SteamBuildId

if (-not (Test-Path -LiteralPath $basePath)) {
    Add-Failure "Missing base reference: $basePath"
}

if (-not (Test-Path -LiteralPath $modsPath)) {
    Add-Failure "Missing mods directory: $modsPath"
}

$baseTables = Get-BaseTableNames $basePath
$modDirs = @()
if (Test-Path -LiteralPath $modsPath) {
    $modDirs = Get-ChildItem -LiteralPath $modsPath -Directory | Where-Object { $_.Name -ne "_template" }
}

Get-ChildItem -Path $workspaceRoot -Recurse -Include "*.xml","*.modinfo" -File |
    Where-Object { $_.FullName -notlike "$basePath*" } |
    ForEach-Object {
        [void](Test-XmlFile $_)
    }

foreach ($modDir in $modDirs) {
    $modInfoFiles = @(Get-ChildItem -LiteralPath $modDir.FullName -Filter "*.modinfo" -File)
    if ($modInfoFiles.Count -eq 0) {
        Add-Failure "Mod has no .modinfo file: $($modDir.FullName)"
        continue
    }
    if ($modInfoFiles.Count -gt 1) {
        Add-Failure "Mod has multiple .modinfo files: $($modDir.FullName)"
    }

    $manifestPath = Join-Path $modDir.FullName "manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Add-Failure "Mod has no manifest.json: $($modDir.FullName)"
    }

    $manifest = $null
    if (Test-Path -LiteralPath $manifestPath) {
        try {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        }
        catch {
            Add-Failure "Invalid manifest.json: $manifestPath :: $($_.Exception.Message)"
        }
    }

    $modInfo = $modInfoFiles | Select-Object -First 1
    $doc = Test-XmlFile $modInfo
    if ($null -eq $doc -or $null -eq $doc.DocumentElement) {
        continue
    }

    $modId = $doc.DocumentElement.GetAttribute("id")
    if ([string]::IsNullOrWhiteSpace($modId)) {
        Add-Failure "Missing Mod id in $($modInfo.FullName)"
    }

    if ($modId -match "template|local-mod|TODO|PLACEHOLDER") {
        Add-Failure "Template placeholder Mod id remains in $($modInfo.FullName): $modId"
    }

    if ($null -ne $manifest) {
        foreach ($field in @("id", "name", "status", "lastValidatedGameBuild")) {
            if (-not $manifest.PSObject.Properties.Name.Contains($field)) {
                Add-Failure "manifest.json missing '$field': $manifestPath"
            }
        }

        if ($manifest.id -and $modId -and $manifest.id -ne $modId) {
            Add-Failure "manifest id does not match .modinfo id in $($modDir.Name): $($manifest.id) != $modId"
        }

        if ($manifest.id -and (Get-Slug $manifest.id) -ne $modDir.Name) {
            Add-Warning "Folder name does not match manifest id slug: $($modDir.Name) vs $(Get-Slug $manifest.id)"
        }

        if ($currentBuildId -and $manifest.lastValidatedGameBuild -and $manifest.lastValidatedGameBuild -ne $currentBuildId) {
            Add-Warning "Mod $($modDir.Name) was last validated for build $($manifest.lastValidatedGameBuild), current Steam build is $currentBuildId"
        }
    }

    foreach ($item in $doc.GetElementsByTagName("Item")) {
        $relativePath = $item.InnerText.Trim()
        if ($relativePath.Length -eq 0 -or $relativePath -match "^[a-zA-Z]+:") {
            continue
        }
        $candidate = Join-Path $modDir.FullName $relativePath
        if (-not (Test-Path -LiteralPath $candidate)) {
            Add-Failure "Missing file referenced by $($modInfo.FullName): $relativePath"
        }
    }

    foreach ($fileNode in $doc.GetElementsByTagName("File")) {
        $relativePath = $fileNode.InnerText.Trim()
        if ($relativePath.Length -eq 0 -or $relativePath -match "^[a-zA-Z]+:") {
            continue
        }
        $candidate = Join-Path $modDir.FullName $relativePath
        if (-not (Test-Path -LiteralPath $candidate)) {
            Add-Failure "Missing localized text file referenced by $($modInfo.FullName): $relativePath"
        }
    }

    Get-ChildItem -LiteralPath $modDir.FullName -Recurse -Include "*.xml","*.modinfo" -File | ForEach-Object {
        $content = Get-Content -LiteralPath $_.FullName -Raw
        if ($content -match "TODO|PLACEHOLDER") {
            Add-Failure "Placeholder text remains in $($_.FullName)"
        }
    }
}

Get-ChildItem -Path $workspaceRoot -Recurse -Filter "*.sql" -File |
    Where-Object { $_.FullName -notlike "$basePath*" } |
    ForEach-Object {
        $content = Get-Content -LiteralPath $_.FullName -Raw
        $matches = [regex]::Matches($content, "(?im)\b(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+([A-Za-z_][A-Za-z0-9_]*)")
        foreach ($match in $matches) {
            $table = $match.Groups[1].Value
            if ($baseTables.Count -gt 0 -and -not $baseTables.Contains($table)) {
                Add-Failure "SQL references unknown base XML table/container '$table' in $($_.FullName)"
            }
        }
    }

Get-ChildItem -Path $workspaceRoot -Recurse -Include "*.xml","*.modinfo" -File |
    Where-Object { $_.FullName -notlike "$basePath*" -and $_.FullName -notlike "*\mods\_template\*" } |
    ForEach-Object {
        $doc = Test-XmlFile $_
        if ($null -eq $doc) {
            return
        }

        $seen = @{}
        foreach ($row in $doc.GetElementsByTagName("Row")) {
            foreach ($attributeName in @("Type", "ID", "Tag")) {
                if ($row.HasAttribute($attributeName)) {
                    $key = "$($row.ParentNode.Name):${attributeName}:$($row.GetAttribute($attributeName))"
                    if ($seen.ContainsKey($key)) {
                        Add-Failure "Duplicate local row key '$key' in $($_.FullName)"
                    }
                    else {
                        $seen[$key] = $true
                    }
                }
            }
        }
    }

if ($warnings.Count -gt 0) {
    Write-Host "Civ VII workspace validation warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}

if ($failures.Count -gt 0) {
    Write-Host "Civ VII workspace validation failed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Civ VII workspace validation passed." -ForegroundColor Green
