@echo off
echo ========================================
echo   Firestore Index Debug Helper
echo ========================================
echo.
echo STILL GETTING ERROR: FAILED_PRECONDITION
echo.
echo The error shows this exact query:
echo Query(notifications where recipientId==i5P1Iu492Le9JJQzvvaTL16YeLW2 order by -timestamp, -__name__)
echo.
echo REQUIRED INDEX MUST HAVE EXACTLY:
echo Collection: notifications
echo Fields: 
echo   1. recipientId (Ascending)
echo   2. timestamp (Descending) 
echo   3. __name__ (Descending)
echo.
echo URGENT ACTION NEEDED:
echo 1. Go to: https://console.firebase.google.com/project/stut-flut-mana/firestore/indexes
echo 2. Look for notifications collection indexes
echo 3. Verify index exists with EXACT fields above
echo 4. Check status is "Enabled" not "Building" or "Error"
echo 5. If missing, click "Add Index" and create it manually
echo.
echo ALTERNATIVE: Apply temporary fix to remove __name__ ordering
echo This would require a small code change to work around the issue.
echo.
pause
