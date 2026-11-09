#!/usr/bin/env bash
# ตรวจหน้าเว็บแบบเร็ว (ไม่ต้องมีฐานข้อมูล): ไวยากรณ์ JS ทุกไฟล์ + ทุก <script src>/<link href> ที่เป็นไฟล์ในเครื่องมีอยู่จริง + ทุกไฟล์ใน app/ admin/ ถูกเรียกใช้
set -u; cd "$(dirname "$0")/../web"; bad=0
for f in *.js app/*.js admin/*.js; do node --check "$f" 2>/dev/null || { echo "FAIL ไวยากรณ์: $f"; bad=1; }; done
for h in index.html admin.html; do
  for p in $(grep -oE '(src|href)="[A-Za-z0-9_./-]+\.(js|css)(\?v=[0-9.]*)?"' $h | sed -E 's/^(src|href)="//; s/(\?v=[0-9.]*)?"$//'); do
    [ -f "$p" ] || { echo "FAIL $h อ้างไฟล์ที่ไม่มี: $p"; bad=1; }; done
done
for f in app/*.js; do grep -q "$f" index.html || { echo "FAIL ไม่ได้โหลดใน index.html: $f"; bad=1; }; done
for f in admin/*.js; do grep -q "$f" admin.html || { echo "FAIL ไม่ได้โหลดใน admin.html: $f"; bad=1; }; done
[ $bad = 0 ] && echo "PASS หน้าเว็บ: ไวยากรณ์และการอ้างไฟล์ถูกต้องทั้งหมด"; exit $bad
