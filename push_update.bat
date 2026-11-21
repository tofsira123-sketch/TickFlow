@echo off
echo ============================================
echo   TickFlow - GitHub Quick Push Helper
echo ============================================
echo.
git status -s
echo.
set /p MSG="Update message likhun (default: Update TickFlow): "
if "%MSG%"=="" set MSG=Update TickFlow
git add .
git commit -m "%MSG%"
git push
echo.
echo Done! GitHub-er Actions tab-e giye notun APK download korun.
pause
