#!/usr/bin/env bash
# تثبيت after-effects-mcp وربطه بـ Claude Desktop على macOS
# التشغيل:  bash setup-mac.sh
set -euo pipefail

for tool in node npm git; do
  command -v "$tool" >/dev/null || { echo "❌ $tool غير مثبت. ثبّت Node.js (https://nodejs.org) و Git ثم أعد التشغيل."; exit 1; }
done

REPO="$HOME/after-effects-mcp"
if [ -d "$REPO" ]; then
  echo "📥 تحديث المستودع الموجود..."; git -C "$REPO" pull
else
  echo "📥 تنزيل المستودع..."; git clone https://github.com/Dakkshin/after-effects-mcp.git "$REPO"
fi

echo "📦 تثبيت الحزم وبناء المشروع..."
(cd "$REPO" && npm install && npm run build)

SERVER_JS="$REPO/build/index.js"
BRIDGE="$REPO/build/scripts/mcp-bridge-auto.jsx"
[ -f "$SERVER_JS" ] || { echo "❌ فشل البناء: $SERVER_JS غير موجود"; exit 1; }

found=0
for ae in /Applications/Adobe\ After\ Effects*; do
  [ -d "$ae" ] || continue
  dest="$ae/Scripts/ScriptUI Panels"
  sudo mkdir -p "$dest"
  sudo cp "$BRIDGE" "$dest/"
  echo "✅ تم نسخ اللوحة إلى: $dest"; found=1
done
[ $found -eq 1 ] || echo "⚠️ لم أجد After Effects في /Applications. انسخ $BRIDGE يدويًا إلى Scripts/ScriptUI Panels"

CFG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
mkdir -p "$(dirname "$CFG")"
AE_CFG="$CFG" AE_SERVER="$SERVER_JS" node -e "const fs=require('fs');const f=process.env.AE_CFG;let c={};try{c=JSON.parse(fs.readFileSync(f,'utf8'))}catch{};c.mcpServers=c.mcpServers||{};c.mcpServers.AfterEffectsMCP={command:'node',args:[process.env.AE_SERVER]};fs.writeFileSync(f,JSON.stringify(c,null,2));console.log('✅ تم تحديث '+f)"

if command -v claude >/dev/null; then
  claude mcp add AfterEffectsMCP --scope user -- node "$SERVER_JS" || true
  echo "✅ تمت الإضافة لـ Claude Code أيضًا"
fi

cat <<'MSG'

🎬 الخطوات الأخيرة داخل After Effects:
  1) After Effects > Settings > Scripting & Expressions
     فعّل: Allow Scripts to Write Files and Access Network
  2) أعد تشغيل After Effects
  3) Window > mcp-bridge-auto.jsx  وتأكد أن Auto-run commands مفعّل
  4) اقفل Claude Desktop بالكامل (Cmd+Q) وافتحه من جديد
MSG
