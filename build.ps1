# build.ps1 -- outputs to deploy\yyyymmddhhmmss
# Usage:
#   .\build.ps1                   -- build only
#   .\build.ps1 -deploy           -- build + deploy
#   $env:SWA_TOKEN="xxx"; $env:WEBAPP_NAME="xxx"; .\build.ps1 -deploy

param(
    [switch]$deploy
)

$ErrorActionPreference = "Stop"

$TIMESTAMP    = Get-Date -Format "yyyyMMddHHmmss"
$ROOT_DIR     = $PSScriptRoot
$DEPLOY_DIR   = Join-Path (Join-Path $ROOT_DIR "deploy") $TIMESTAMP
$FRONTEND_DIR = Join-Path $ROOT_DIR "frontend"
$BACKEND_DIR  = Join-Path $ROOT_DIR "backend"

# ---------- Deploy config ----------
$SWA_TOKEN      = if ($env:SWA_TOKEN)      { $env:SWA_TOKEN }      else { "" }
$SWA_ENV        = if ($env:SWA_ENV)        { $env:SWA_ENV }        else { "production" }
$WEBAPP_NAME    = if ($env:WEBAPP_NAME)    { $env:WEBAPP_NAME }    else { "nile-demo" }
$RESOURCE_GROUP = if ($env:RESOURCE_GROUP) { $env:RESOURCE_GROUP } else { "test-g" }
# -----------------------------------

$DO_DEPLOY = $deploy.IsPresent

function Assert-ExitCode {
    if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE" }
}

Write-Host "==> Build timestamp: $TIMESTAMP"
Write-Host "==> Output folder:   $DEPLOY_DIR"
Write-Host "==> Deploy mode:     $DO_DEPLOY"
Write-Host ""

# ------------------------------------------------------------------
# 1. Build Frontend (Vue 3 + Vite)
# ------------------------------------------------------------------
Write-Host "[1/2] Building frontend..."
Push-Location $FRONTEND_DIR
npm install; Assert-ExitCode
npm run build; Assert-ExitCode
Pop-Location

$frontendOut = Join-Path $DEPLOY_DIR "frontend"
New-Item -ItemType Directory -Force -Path $frontendOut | Out-Null
Copy-Item -Recurse -Force "$FRONTEND_DIR\dist\*" $frontendOut
Write-Host "     OK Frontend built -> deploy/$TIMESTAMP/frontend/"

# ------------------------------------------------------------------
# 2. Build Backend (.NET 8)
# ------------------------------------------------------------------
Write-Host "[2/2] Building backend..."
Push-Location $BACKEND_DIR
$backendOut = Join-Path $DEPLOY_DIR "backend"
dotnet publish backend.csproj --configuration Release --output $backendOut --no-self-contained --runtime linux-x64; Assert-ExitCode
Pop-Location
Write-Host "     OK Backend built  -> deploy/$TIMESTAMP/backend/"

# ------------------------------------------------------------------
# 3. Zip backend -- skip .pdb
# ------------------------------------------------------------------
Write-Host "[3/3] Zipping backend..."
$zipPath     = Join-Path $DEPLOY_DIR "backend.zip"
$backendRoot = Join-Path $DEPLOY_DIR "backend"

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')
Get-ChildItem -Path $backendRoot -Recurse -File |
    Where-Object { $_.Extension -ne ".pdb" } |
    ForEach-Object {
        $entryName = $_.FullName.Substring($backendRoot.Length + 1)
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entryName) | Out-Null
    }
$zip.Dispose()
Write-Host "     OK Backend zipped -> deploy/$TIMESTAMP/backend.zip"

# ------------------------------------------------------------------
# 4. Deploy
# ------------------------------------------------------------------
if ($DO_DEPLOY) {
    Write-Host ""
    Write-Host "[Deploy] Starting deployment..."

    # Frontend -> Azure Static Web Apps
    if ([string]::IsNullOrEmpty($SWA_TOKEN)) {
        Write-Host "     SKIP: SWA_TOKEN not set -- skipping frontend deploy"
        Write-Host "     Set with: `$env:SWA_TOKEN=`"<your-deployment-token>`""
    } else {
        Write-Host "     Deploying frontend..."
        swa deploy $frontendOut --deployment-token $SWA_TOKEN --env $SWA_ENV
        Write-Host "     OK Frontend deployed!"
    }

    # Backend -> Azure App Service
    Write-Host "     Deploying backend..."
    az webapp deploy --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --src-path $zipPath --type zip
    Write-Host "     OK Backend deployed!"
}

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
Write-Host ""
Write-Host "==> Build complete!"
Write-Host ""
Write-Host "    deploy/$TIMESTAMP/"
Write-Host "    +-- frontend/        <- Azure Static Web Apps"
Write-Host "    +-- backend.zip      <- Azure App Service"
Write-Host ""

if (-not $DO_DEPLOY) {
    Write-Host "To deploy both, run:"
    Write-Host "  `$env:SWA_TOKEN=`"<token>`"; .\build.ps1 -deploy"
    Write-Host ""
    Write-Host "To deploy backend only:"
    Write-Host "  az webapp deploy --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --src-path deploy/$TIMESTAMP/backend.zip --type zip"
}
