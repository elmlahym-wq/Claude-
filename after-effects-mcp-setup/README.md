# ربط Claude بـ After Effects (after-effects-mcp)

سكريبتات تثبيت تلقائي لـ [Dakkshin/after-effects-mcp](https://github.com/Dakkshin/after-effects-mcp).
السكريبت بينزّل المشروع، يبنيه، ينسخ لوحة الـ Bridge لـ After Effects، ويضيف السيرفر لإعدادات Claude Desktop (و Claude Code لو موجود).

## المتطلبات
- Adobe After Effects 2022 أو أحدث
- [Node.js](https://nodejs.org) (LTS) و [Git](https://git-scm.com)
- Claude Desktop

## Windows
1. نزّل الملف `setup-windows.ps1`.
2. افتح **PowerShell كمسؤول** (Run as Administrator) في نفس الفولدر.
3. شغّل:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass -Force; .\setup-windows.ps1
   ```

## macOS
```bash
bash setup-mac.sh
```
(هيطلب باسورد الجهاز علشان ينسخ اللوحة جوه فولدر After Effects.)

## بعد التثبيت (مهم)
1. في After Effects: **Edit > Preferences > Scripting & Expressions** (على الماك: **After Effects > Settings**) وفعّل **Allow Scripts to Write Files and Access Network**.
2. أعد تشغيل After Effects.
3. افتح **Window > mcp-bridge-auto.jsx** وسيب اللوحة مفتوحة، وتأكد إن **Auto-run commands** متعلّم عليه.
4. اقفل Claude Desktop تمامًا وافتحه تاني — هتلاقي أدوات `AfterEffectsMCP` في قائمة الأدوات.

## جرّب
اكتب لـ Claude مثلًا:
> اعمل كومبوزيشن 1920x1080 اسمها Intro مدتها 5 ثواني، وحط فيها نص "Hello" في النص بيعمل Fade in.

## الإعداد اليدوي (لو السكريبت ما اشتغلش)
أضف ده لملف `claude_desktop_config.json`
(Windows: `%APPDATA%\Claude\` — Mac: `~/Library/Application Support/Claude/`):
```json
{
  "mcpServers": {
    "AfterEffectsMCP": {
      "command": "node",
      "args": ["C:\\Users\\<اسمك>\\after-effects-mcp\\build\\index.js"]
    }
  }
}
```
وانسخ `build/scripts/mcp-bridge-auto.jsx` إلى:
- Windows: `C:\Program Files\Adobe\Adobe After Effects <VERSION>\Support Files\Scripts\ScriptUI Panels\`
- Mac: `/Applications/Adobe After Effects <VERSION>/Scripts/ScriptUI Panels/`

## مشاكل شائعة
- **الأوامر مش بتتنفذ:** اتأكد إن لوحة mcp-bridge-auto مفتوحة والـ Auto-run مفعّل، وإن خيار Allow Scripts متفعّل.
- **Claude مش شايف الأدوات:** اقفل Claude Desktop من الـ tray/Cmd+Q مش بس الشباك، واتأكد إن المسار في الإعدادات صحيح وإن `node` شغال من الترمنال.
