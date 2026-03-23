#!/bin/bash
# Build script — outputs to deploy/yyyymmddhhmmss
# Usage:
#   ./build.sh                          — build only
#   ./build.sh --deploy                 — build + deploy ทั้ง frontend และ backend
#   SWA_TOKEN=xxx WEBAPP_NAME=xxx ./build.sh --deploy
set -e

TIMESTAMP=$(date +"%Y%m%d%H%M%S")
DEPLOY_DIR="$(pwd)/deploy/$TIMESTAMP"
FRONTEND_DIR="$(pwd)/frontend"
BACKEND_DIR="$(pwd)/backend"

# ---------- Deploy config (แก้ค่าตรงนี้ หรือส่งเป็น env var) ----------
SWA_TOKEN="${SWA_TOKEN:-}"                          # deployment token ของ Azure Static Web Apps
SWA_ENV="${SWA_ENV:-production}"                    # environment ของ Static Web Apps
WEBAPP_NAME="${WEBAPP_NAME:-nile-demo}"             # ชื่อ Azure App Service
RESOURCE_GROUP="${RESOURCE_GROUP:-test-g}"          # ชื่อ Resource Group
# -----------------------------------------------------------------------

DO_DEPLOY=false
for arg in "$@"; do
  [[ "$arg" == "--deploy" ]] && DO_DEPLOY=true
done

echo "==> Build timestamp: $TIMESTAMP"
echo "==> Output folder:   $DEPLOY_DIR"
echo "==> Deploy mode:     $DO_DEPLOY"
echo ""

# ------------------------------------------------------------------
# 1. Build Frontend (Vue 3 + Vite)
# ------------------------------------------------------------------
echo "[1/2] Building frontend..."
cd "$FRONTEND_DIR"
npm ci --silent
npm run build

mkdir -p "$DEPLOY_DIR/frontend"
cp -r dist/. "$DEPLOY_DIR/frontend/"
echo "     ✓ Frontend built → deploy/$TIMESTAMP/frontend/"

# ------------------------------------------------------------------
# 2. Build Backend (.NET 8)
# ------------------------------------------------------------------
echo "[2/2] Building backend..."
cd "$BACKEND_DIR"
dotnet publish backend.csproj \
  --configuration Release \
  --output "$DEPLOY_DIR/backend" \
  --no-self-contained \
  --runtime linux-x64

echo "     ✓ Backend built  → deploy/$TIMESTAMP/backend/"

# ------------------------------------------------------------------
# 3. Zip backend (สำหรับ deploy ด้วยมือ)
# ------------------------------------------------------------------
echo "[3/3] Zipping backend..."
cd "$DEPLOY_DIR/backend"
zip -r ../backend.zip . -x "*.pdb" > /dev/null
echo "     ✓ Backend zipped → deploy/$TIMESTAMP/backend.zip"

# ------------------------------------------------------------------
# 4. Deploy (ถ้าใช้ --deploy flag)
# ------------------------------------------------------------------
if [[ "$DO_DEPLOY" == true ]]; then
  echo ""
  echo "[Deploy] Starting deployment..."

  # --- Frontend → Azure Static Web Apps ---
  if [[ -z "$SWA_TOKEN" ]]; then
    echo "     ✗ SWA_TOKEN ไม่ได้ตั้งค่า — ข้าม frontend deploy"
    echo "       ตั้งค่าด้วย: export SWA_TOKEN=<your-deployment-token>"
  else
    echo "     Deploying frontend..."
    swa deploy "$DEPLOY_DIR/frontend" \
      --deployment-token "$SWA_TOKEN" \
      --env "$SWA_ENV"
    echo "     ✓ Frontend deployed!"
  fi

  # --- Backend → Azure App Service ---
  echo "     Deploying backend..."
  az webapp deploy \
    --name "$WEBAPP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --src-path "$DEPLOY_DIR/backend.zip" \
    --type zip
  echo "     ✓ Backend deployed!"
fi

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
echo ""
echo "==> Build complete!"
echo ""
echo "    deploy/$TIMESTAMP/"
echo "    ├── frontend/        ← Azure Static Web Apps"
echo "    └── backend.zip      ← Azure App Service"
echo ""

if [[ "$DO_DEPLOY" == false ]]; then
  echo "To deploy both, run:"
  echo "  SWA_TOKEN=<token> ./build.sh --deploy"
  echo ""
  echo "To deploy backend only:"
  echo "  az webapp deploy --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --src-path deploy/$TIMESTAMP/backend.zip --type zip"
fi
