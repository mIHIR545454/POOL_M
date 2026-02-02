@echo off
echo ========================================
echo Import to MongoDB Atlas
echo ========================================
echo.

REM Check if backup exists
if not exist "backup\ttc_pool" (
    echo ERROR: No backup found!
    echo Please run export_local_db.bat first
    pause
    exit /b 1
)

echo Please enter your MongoDB Atlas connection string:
echo Example: mongodb+srv://pooladmin:password@cluster.xxxxx.mongodb.net/ttc_pool
echo.
set /p ATLAS_URI="Atlas URI: "

echo.
echo ========================================
echo Importing data to Atlas...
echo ========================================
echo.

REM Import the database using mongorestore
mongorestore --uri "%ATLAS_URI%" ./backup/ttc_pool

echo.
echo ========================================
echo Import complete!
echo ========================================
echo.
echo Your local data has been imported to MongoDB Atlas
echo You can now use this Atlas connection string in Render
echo.
pause
