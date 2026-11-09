#!/usr/bin/env bash
# ชุดทดสอบ RPC/RLS ของ Chemistria — ใช้ Postgres ในเครื่อง (ไม่แตะ Supabase จริง)
# วิธีใช้:  cd tests && ./run.sh          (ต้องมี psql และสิทธิ์สร้างฐานข้อมูลชั่วคราว)
# ผลลัพธ์: แสดง PASS/FAIL ทีละข้อ แล้วออกด้วยรหัส 0 เมื่อผ่านทั้งหมด
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DB="ct_test_$$"
PSQL=(psql -X -q -v ON_ERROR_STOP=1)
if [ "$(id -u)" = "0" ] && id postgres >/dev/null 2>&1; then RUN=(su postgres -c); else RUN=(bash -c); fi
q() { "${RUN[@]}" "$1"; }
q "createdb $DB"
trap 'q "dropdb --if-exists $DB" >/dev/null 2>&1 || true' EXIT
q "psql -X -q -v ON_ERROR_STOP=1 -d $DB -f $HERE/stub.sql" >/dev/null
q "psql -X -q -v ON_ERROR_STOP=1 -d $DB -f ${SETUP:-$HERE/../db/setup_all.sql}" >/dev/null 2>"$HERE/.setup.err" || { echo "โหลด setup_all.sql ไม่ผ่าน:"; tail -5 "$HERE/.setup.err"; exit 2; }
set +e
q "psql -X -v ON_ERROR_STOP=1 -d $DB -f $HERE/rpc_tests.sql" 2>&1 | sed -n -e 's/^.*NOTICE:  //p' -e 's/^.*\(ERROR:.*\)$/\1/p' | grep -E "^(PASS|FAIL|SUMMARY|ERROR)" | tee "$HERE/.last.txt"
grep -q "^SUMMARY" "$HERE/.last.txt" || { echo "ERROR: ชุดทดสอบหยุดกลางคัน"; exit 1; }
grep -q "^FAIL\|^ERROR" "$HERE/.last.txt" && exit 1 || exit 0
