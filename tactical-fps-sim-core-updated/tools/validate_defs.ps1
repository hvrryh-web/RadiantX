param(
  [string]$DefsPath = "$(Resolve-Path ..\Defs)"
)

Write-Host "Validating defs in $DefsPath"

function Read-Json($p) { Get-Content $p -Raw | ConvertFrom-Json }

# Load flexible sets (matching the C# loader patterns)
$weaponFiles = Get-ChildItem -Path $DefsPath -Filter "weapons*.json" -File
$utilFiles = Get-ChildItem -Path $DefsPath -Filter "utilities*.json" -File
$agentFiles = Get-ChildItem -Path $DefsPath -Filter "agents*.json" -File

$weapons = @()
foreach ($f in $weaponFiles) { $weapons += Read-Json $f.FullName }

$utils = @()
foreach ($f in $utilFiles) { $utils += Read-Json $f.FullName }

$agents = @()
foreach ($f in $agentFiles) { $agents += Read-Json $f.FullName }

$weaponIds = @{}
$weapons | ForEach-Object { $weaponIds[$_.id] = $true }

$utilIds = @{}
$utils | ForEach-Object { $utilIds[$_.id] = $true }

$errors = 0
$agents | ForEach-Object {
  $a = $_
  foreach ($wid in $a.loadoutWeaponIds) {
    if (-not $weaponIds.ContainsKey($wid)) {
      Write-Host "ERROR: Agent $($a.id) missing weapon $wid" -ForegroundColor Red
      $errors++
    }
  }
  foreach ($uid in $a.loadoutUtilityIds) {
    if (-not $utilIds.ContainsKey($uid)) {
      Write-Host "ERROR: Agent $($a.id) missing utility $uid" -ForegroundColor Red
      $errors++
    }
  }
}

if ($errors -gt 0) { throw "$errors validation errors." }
Write-Host "OK: defs validated."
