#!/usr/bin/env bash
# Reads one /api/tick response. When the bot is not linked to WhatsApp (or keeps failing) it opens a GitHub issue,
# which GitHub emails to the repo owner; when the bot is healthy again the issue is closed automatically. Free, no extra service.
out="$1"
echo "$out"
field() { echo "$out" | sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p"; }
outcome=$(field outcome)
err=$(field error)
case "$outcome" in
  not_linked) state=down ;;
  error) if [ "$err" = logged_out ]; then state=down; else state=error; fi ;;
  ok|idle|synced|sent|blocked|paused) state=up ;;
  *) exit 0 ;;   # locked / too_soon / no answer: says nothing about the bot's health
esac

R="$GITHUB_REPOSITORY"
open=$(gh issue list -R "$R" --label bot-alert --state open --json number -q '.[0].number' 2>/dev/null)

if [ "$state" = up ]; then
  echo 0 > /tmp/errors
  [ -n "$open" ] && gh issue close "$open" -R "$R" -c "✅ הבוט חזר לעבוד ($(TZ=Asia/Jerusalem date '+%d/%m %H:%M'))."
  exit 0
fi

if [ "$state" = error ]; then
  n=$(( $(cat /tmp/errors 2>/dev/null || echo 0) + 1 )); echo "$n" > /tmp/errors
  [ "$n" -lt 15 ] && exit 0      # a few failed calls in a row are normal; 15 minutes of failures are not
  title="⚠️ הבוט של מנדי נכשל ברצף"
  why="15 קריאות רצופות נכשלו. השגיאה האחרונה: \`$err\`"
else
  title="⚠️ הבוט של מנדי לא מחובר לוואטסאפ"
  why="וואטסאפ לא מקושר לבוט, ולכן לא נשלחות הודעות ולא נקלטות תשובות."
fi
[ -n "$open" ] && exit 0
gh label create bot-alert -R "$R" --color d73a4a --description "Mendy bot health" 2>/dev/null
gh issue create -R "$R" --label bot-alert --title "$title" --body "@khnzyw710-hub $why

מה לעשות: להיכנס לדשבורד ← מערכת, ולסרוק את ה-QR מהטלפון של מנדי (וואטסאפ ← מכשירים מקושרים).
https://mendy-dashboard.vercel.app/system

הנושא הזה ייסגר לבד כשהבוט יחזור לעבוד."
