param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message) | Out-Null
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

$basePath = Join-Path $WorkspaceRoot "Civ7BaseAssets"
$modsPath = Join-Path $WorkspaceRoot "mods"

if (-not (Test-Path -LiteralPath $basePath)) {
    Add-Failure "Missing base reference: $basePath"
}

if (-not (Test-Path -LiteralPath $modsPath)) {
    Add-Failure "Missing mods directory: $modsPath"
}

$baseTables = Get-BaseTableNames $basePath

Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "*.xml","*.modinfo" -File |
    Where-Object { $_.FullName -notlike "$basePath*" } |
    ForEach-Object {
        $doc = Test-XmlFile $_
        if ($null -eq $doc) {
            return
        }

        if ($_.Extension -eq ".modinfo") {
            $modDir = $_.Directory.FullName
            $items = $doc.GetElementsByTagName("Item")
            foreach ($item in $items) {
                $relativePath = $item.InnerText.Trim()
                if ($relativePath.Length -eq 0) {
                    continue
                }
                if ($relativePath -match "^[a-zA-Z]+:") {
                    continue
                }
                $candidate = Join-Path $modDir $relativePath
                if (-not (Test-Path -LiteralPath $candidate)) {
                    Add-Failure "Missing file referenced by $($_.FullName): $relativePath"
                }
            }
        }
    }

Get-ChildItem -Path $WorkspaceRoot -Recurse -Filter "*.sql" -File |
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

Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "*.xml","*.modinfo" -File |
    Where-Object { $_.FullName -notlike "$basePath*" } |
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

if ($failures.Count -gt 0) {
    Write-Host "Civ VII workspace validation failed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Civ VII workspace validation passed." -ForegroundColor Green
