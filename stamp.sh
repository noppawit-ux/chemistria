#!/bin/sh
# ใช้ก่อนปล่อยทุกครั้ง: ./stamp.sh 1.40  → ใส่ ?v=เลขเวอร์ชัน ให้ไฟล์ css/js ทุกไฟล์ในโฟลเดอร์ web (กันเบราว์เซอร์มือถือใช้ไฟล์เก่าค้าง)
# ครอบคลุมทุก <script src="..."> / <link href="..."> ที่เป็นไฟล์ในเครื่อง (รวม app/*.js และ admin/*.js)
V="$1"; cd "$(dirname "$0")/web" || exit 1
[ -n "$V" ] || { echo "ใช้: ./stamp.sh 1.75"; exit 1; }
for f in index.html admin.html; do
  sed -i -E "s#(href|src)=\"([A-Za-z0-9_./-]+\.(js|css))(\?v=[0-9.]*)?\"#\1=\"\2?v=$V\"#g" "$f"
done
sed -i -E "s#const APP_VERSION = \"[0-9.]*\"#const APP_VERSION = \"$V\"#" index.html app/*.js 2>/dev/null
echo "stamped $V"
