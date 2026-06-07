param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [string]$DisplayName,
    [string]$Description,
    [string]$Author = "runya",
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

function Get-Slug {
    param([string]$Value)
    return ($Value.Trim().ToLowerInvariant() -replace "[^a-z0-9]+", "-" -replace "^-|-$", "")
}

function Get-KeyPrefix {
    param([string]$Value)
    return ("ERU_" + ($Value.Trim().ToUpperInvariant() -replace "[^A-Z0-9]+", "_" -replace "^_|_$", ""))
}

$slug = Get-Slug $Name
if ([string]::IsNullOrWhiteSpace($slug)) {
    throw "Name must contain at least one letter or number."
}

if ([string]::IsNullOrWhiteSpace($DisplayName)) {
    $titleParts = ($slug -split "-") | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }
    $DisplayName = [string]::Join(" ", $titleParts)
}

if ([string]::IsNullOrWhiteSpace($Description)) {
    $Description = "$DisplayName Civilization VII mod."
}

$modsRoot = Join-Path $WorkspaceRoot "mods"
$template = Join-Path $modsRoot "_template"
$target = Join-Path $modsRoot $slug
$modId = "erunyan6-$slug"
$prefix = Get-KeyPrefix $slug
$currentBuild = $null
$manifestFile = "C:\Program Files (x86)\Steam\steamapps\appmanifest_1295660.acf"

if (Test-Path -LiteralPath $manifestFile) {
    $match = Select-String -LiteralPath $manifestFile -Pattern '"buildid"\s+"([^"]+)"' | Select-Object -First 1
    if ($match) {
        $currentBuild = $match.Matches[0].Groups[1].Value
    }
}

if (-not (Test-Path -LiteralPath $template)) {
    throw "Template folder does not exist: $template"
}

if (Test-Path -LiteralPath $target) {
    throw "Mod folder already exists: $target"
}

Copy-Item -LiteralPath $template -Destination $target -Recurse

$oldModInfo = Join-Path $target "_template.modinfo"
$newModInfo = Join-Path $target "$slug.modinfo"
Rename-Item -LiteralPath $oldModInfo -NewName "$slug.modinfo"

$nameKey = "LOC_${prefix}_NAME"
$descriptionKey = "LOC_${prefix}_DESCRIPTION"

$modInfoContent = Get-Content -LiteralPath $newModInfo -Raw
$modInfoContent = $modInfoContent.Replace("template-local-mod", $modId)
$modInfoContent = $modInfoContent.Replace("LOC_TEMPLATE_LOCAL_MOD_NAME", $nameKey)
$modInfoContent = $modInfoContent.Replace("LOC_TEMPLATE_LOCAL_MOD_DESCRIPTION", $descriptionKey)
$modInfoContent = $modInfoContent.Replace("template-local-mod-main", "$slug-main")
$modInfoContent | Set-Content -LiteralPath $newModInfo -Encoding utf8

$textFile = Join-Path $target "text\ModuleText.xml"
$textContent = Get-Content -LiteralPath $textFile -Raw
$textContent = $textContent.Replace("LOC_TEMPLATE_LOCAL_MOD_NAME", $nameKey)
$textContent = $textContent.Replace("LOC_TEMPLATE_LOCAL_MOD_DESCRIPTION", $descriptionKey)
$textContent = $textContent.Replace("Template Local Mod", $DisplayName)
$textContent = $textContent.Replace("Starter template for a local Civilization VII mod.", $Description)
$textContent | Set-Content -LiteralPath $textFile -Encoding utf8

$readmeLines = @(
    "# $DisplayName",
    "",
    $Description,
    "",
    "## Mod Metadata",
    "",
    "- ID: ``$modId``",
    "- Folder: ``$slug``",
    "- Text prefix: ``$prefix``",
    "",
    "## Workflow",
    "",
    "Validate:",
    "",
    '```powershell',
    "powershell -ExecutionPolicy Bypass -File tools\Test-Civ7Workspace.ps1",
    '```',
    "",
    "Deploy:",
    "",
    '```powershell',
    "powershell -ExecutionPolicy Bypass -File tools\Deploy-Civ7Mod.ps1 -ModName $slug -Clean",
    '```'
)
$readme = [string]::Join([Environment]::NewLine, $readmeLines)
$readme | Set-Content -LiteralPath (Join-Path $target "README.md") -Encoding utf8

$manifest = [ordered]@{
    id = $modId
    name = $DisplayName
    description = $Description
    author = $Author
    status = "draft"
    lastValidatedGameBuild = $currentBuild
    managedBy = "codex-civ7-workspace"
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $target "manifest.json") -Encoding utf8

& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-Civ7Workspace.ps1") -WorkspaceRoot $WorkspaceRoot
if ($LASTEXITCODE -ne 0) {
    throw "Workspace validation failed after creating $slug."
}

Write-Host "Created mod $slug with id $modId"
