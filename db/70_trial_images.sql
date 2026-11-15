-- 70: ภาพบอสด่านเลื่อนแรงค์ (ต้องรันหลัง 69) — ใส่เฉพาะบอสที่ยังไม่มีภาพ ครูเปลี่ยนภาพเองที่แท็บมอนสเตอร์ได้
update monsters set image = 'assets/monsters/' || key || '.png'
 where key in ('trial_silver','trial_gold','trial_platinum','trial_emerald','trial_diamond','trial_master','trial_grandmaster','trial_challenger')
   and (image is null or image = '');
