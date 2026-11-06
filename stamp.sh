#!/bin/sh
# ใช้ก่อนปล่อยทุกครั้ง: ./stamp.sh 1.40  → ใส่ ?v=เลขเวอร์ชัน ให้ไฟล์ css/js (กันเบราว์เซอร์มือถือใช้ไฟล์เก่าค้าง)
V="$1"; cd "$(dirname "$0")/web" || exit 1
for f in index.html admin.html; do
  sed -i -E "s#(href|src)=\"(style\.css|config\.js|lib\.js|sfx\.js|pixelfx\.js|fx\.js|games\.js|battle\.js|duel\.js|spell\.js|kb\.js|bgm\.js)(\?v=[0-9.]*)?\"#\1=\"\2?v=$V\"#g" "$f"
done
sed -i -E "s#const APP_VERSION = \"[0-9.]*\"#const APP_VERSION = \"$V\"#" index.html
