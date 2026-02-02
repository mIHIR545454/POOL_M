@echo off
echo ========================================
echo Exporting ttc_pool database...
echo ========================================

REM Create backup directory if it doesn't exist
if not exist "backup" mkdir backup

REM Export the database using mongodump
echo.
echo Running mongodump...
mongodump --db ttc_pool --out ./backup

echo.
echo ========================================
echo Export complete!
echo ========================================
echo.
echo Your data has been exported to: ./backup/ttc_pool
echo.
echo Next steps:
echo 1. Create MongoDB Atlas account
echo 2. Get your Atlas connection string
echo 3. Run import_to_atlas.bat to import this data
echo.
pause
