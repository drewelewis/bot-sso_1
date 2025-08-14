param(
  [string]$SourceRoot = "src/telemetry/saved_queries",
  [string]$OutputFile = "infra/generatedSavedQueries.bicep",
  [string]$CategoryPrefix = "TeamsBotTelemetry",
  [switch]$DryRun
)

Write-Host "Generating Bicep module from .kql files..." -ForegroundColor Cyan
$repoRoot = (Split-Path $PSScriptRoot -Parent)
Write-Host "Repo root (derived): $repoRoot" -ForegroundColor Gray
Write-Host "Raw SourceRoot param: $SourceRoot" -ForegroundColor Gray
Write-Host "Raw OutputFile param: $OutputFile" -ForegroundColor Gray

function Resolve-RepoPath([string]$path) {
  if ([System.IO.Path]::IsPathRooted($path)) { return $path }
  return (Join-Path $repoRoot $path)
}

$resolvedSource = Resolve-RepoPath $SourceRoot
if (-not (Test-Path $resolvedSource)) { Write-Error "Source folder not found: $resolvedSource"; exit 1 }
try { $fullSource = Resolve-Path $resolvedSource } catch { Write-Error "Cannot resolve SourceRoot $resolvedSource"; exit 1 }
Write-Host "Resolved source: $($fullSource.Path)" -ForegroundColor Gray

$resolvedOutFile = Resolve-RepoPath $OutputFile
$outParent = Split-Path $resolvedOutFile -Parent
if (-not (Test-Path $outParent)) { New-Item -ItemType Directory -Path $outParent -Force | Out-Null }
$outPath = $resolvedOutFile
Write-Host "Resolved output file: $outPath" -ForegroundColor Gray

$kqlFiles = Get-ChildItem -Path $fullSource.Path -Filter *.kql -Recurse | Sort-Object FullName
Write-Host "Discovered $($kqlFiles.Count) .kql files" -ForegroundColor Gray
if (-not $kqlFiles) { Write-Error "No .kql files found under $fullSource"; exit 1 }

# Helper to escape a KQL file content into a single-line string with \n
function Convert-ToBicepString($text) {
  ($text -replace "`r?`n", "\\n") -replace '"', '\\"'
}

$entries = @()
foreach ($file in $kqlFiles) {
  $rel = $file.FullName.Substring($fullSource.Path.Length).TrimStart('\\','/')
  $category = (Split-Path $rel -Parent).Split('\\','/')[-1]
  if (-not $category) { $category = 'misc' }
  $baseName = [IO.Path]::GetFileNameWithoutExtension($file.Name)
  $id = ($category + '-' + $baseName).ToLower()
  $display = "$([cultureinfo]::InvariantCulture.TextInfo.ToTitleCase($category)) - $baseName".Replace('-', ' ')
  $raw = Get-Content $file.FullName -Raw
  $queryLine = Convert-ToBicepString $raw
  $catFull = "${CategoryPrefix}-" + ([cultureinfo]::InvariantCulture.TextInfo.ToTitleCase($category))
  $entries += "    {\n      name: '${id}'\n      displayName: '${display}'\n      category: '${catFull}'\n      query: \"${queryLine}\"\n    }"
}

$bicep = @()
$bicep += "@description('Name of the target Log Analytics workspace')"
$bicep += "param workspaceName string"
$bicep += ""
$bicep += "@description('Generated saved searches from .kql source files. DO NOT EDIT MANUALLY.')"
$bicep += "var savedSearches = ["
$bicep += ($entries -join "`n")
$bicep += "]"
$bicep += ""
$bicep += "resource savedSearchesRes 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = [for s in savedSearches: {"
$bicep += "  name: '${workspaceName}/${s.name}'"
$bicep += "  properties: {"
$bicep += "    displayName: s.displayName"
$bicep += "    category: s.category"
$bicep += "    query: s.query"
$bicep += "    version: 2"
$bicep += "  }"
$bicep += "}]"
$bicep += ""
$bicep += "output savedSearchCount int = length(savedSearches)"

if ($DryRun) {
  Write-Host "--- DRY RUN OUTPUT START ---" -ForegroundColor Yellow
  $bicep | ForEach-Object { Write-Host $_ }
  Write-Host "--- DRY RUN OUTPUT END ---" -ForegroundColor Yellow
  exit 0
}

$bicep -join "`n" | Out-File -FilePath $outPath -Encoding UTF8
Write-Host "Generated: $outPath" -ForegroundColor Green
Write-Host "Saved searches: $($kqlFiles.Count)" -ForegroundColor Green
