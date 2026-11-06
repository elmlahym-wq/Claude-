# تثبيت after-effects-mcp وربطه بـ Claude Desktop على Windows
# شغّل PowerShell "كمسؤول" (Run as Administrator) ثم:
#   Set-ExecutionPolicy -Scope Process Bypass -Force; .\setup-windows.ps1
$ErrorActionPreference = "Stop"

foreach ($tool in @("node", "npm", "git")) {
  if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
    Write-Host "❌ $tool غير مثبت. ثبّت Node.js (https://nodejs.org) و Git (https://git-scm.com) ثم أعد التشغيل." -ForegroundColor Red
    exit 1
  }
}

$repo = Join-Path $HOME "after-effects-mcp"
if (Test-Path $repo) {
  Write-Host "📥 تحديث المستودع الموجود..."
  git -C $repo pull
} else {
  Write-Host "📥 تنزيل المستودع..."
  git clone https://github.com/Dakkshin/after-effects-mcp.git $repo
}

Write-Host "📦 تثبيت الحزم وبناء المشروع..."
Push-Location $repo
npm install
npm run build
Pop-Location

$serverJs = Join-Path $repo "build\index.js"
$bridge   = Join-Path $repo "build\scripts\mcp-bridge-auto.jsx"
if (-not (Test-Path $serverJs)) { Write-Host "❌ فشل البناء: $serverJs غير موجود" -ForegroundColor Red; exit 1 }

# نسخ لوحة الـ Bridge إلى كل إصدارات After Effects الموجودة
$aeDirs = Get-ChildItem "C:\Program Files\Adobe" -Directory -Filter "Adobe After Effects*" -ErrorAction SilentlyContinue
if (-not $aeDirs) {
  Write-Host "⚠️ لم أجد After Effects في C:\Program Files\Adobe. انسخ الملف يدويًا:" -ForegroundColor Yellow
  Write-Host "   $bridge  ->  ...\Adobe After Effects <VERSION>\Support Files\Scripts\ScriptUI Panels\"
} else {
  foreach ($ae in $aeDirs) {
    $dest = Join-Path $ae.FullName "Support Files\Scripts\ScriptUI Panels"
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item $bridge $dest -Force
    Write-Host "✅ تم نسخ اللوحة إلى: $dest"
  }
}

# إضافة السيرفر لإعدادات Claude Desktop (مع الحفاظ على أي سيرفرات موجودة)
$cfgDir  = Join-Path $env:APPDATA "Claude"
$cfgFile = Join-Path $cfgDir "claude_desktop_config.json"
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
$env:AE_CFG = $cfgFile
$env:AE_SERVER = $serverJs
node -e "const fs=require('fs');const f=process.env.AE_CFG;let c={};try{c=JSON.parse(fs.readFileSync(f,'utf8'))}catch{};c.mcpServers=c.mcpServers||{};c.mcpServers.AfterEffectsMCP={command:'node',args:[process.env.AE_SERVER]};fs.writeFileSync(f,JSON.stringify(c,null,2));console.log('✅ تم تحديث '+f)"

# Claude Code (لو مثبت)
if (Get-Command claude -ErrorAction SilentlyContinue) {
  claude mcp add AfterEffectsMCP --scope user -- node "$serverJs" 2>$null
  Write-Host "✅ تمت الإضافة لـ Claude Code أيضًا"
}

Write-Host ""
Write-Host "🎬 الخطوات الأخيرة داخل After Effects:" -ForegroundColor Cyan
Write-Host "  1) Edit > Preferences > Scripting & Expressions"
Write-Host "     فعّل: Allow Scripts to Write Files and Access Network"
Write-Host "  2) أعد تشغيل After Effects"
Write-Host "  3) Window > mcp-bridge-auto.jsx  وتأكد أن Auto-run commands مفعّل"
Write-Host "  4) أغلق Claude Desktop تمامًا (من الـ tray) وافتحه من جديد"
