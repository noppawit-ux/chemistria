import json, re, os
from PIL import Image
SRC='/tmp/pfx/src/src/fx'; OUT='/tmp/pfx/out'; DST='/home/claude/classroom/web/assets/pixelfx'
os.makedirs(DST, exist_ok=True)
# id : (max_frames, skip)
SEL={ 'fire/fireball':(36,1),'explosions/small-explosion':(110,2),'lightning/zap-hit':(28,1),'melee/sword-slash':(24,1),
 'impacts/crit-hit':(28,1),'impacts/hit-spark':(16,1),'impacts/blunt-hit':(28,1),'impacts/shield-block':(34,1),
 'projectiles/magic-missile':(58,1),'holy/heal-aoe':(88,2),'holy/divine-shield':(72,1),'status/rage':(36,1),'shadow/curse':(103,2),
 'arcane/star-fall':(76,1),'arcane/spell-charge':(48,1),'nature/acid-splash':(85,2),'nature/poison-cloud':(70,2),
 'spawn/shatter-death':(100,2),'pickups/collect-burst':(42,1),'status/haste':(36,1) }
man={}
for id,(mx,skip) in SEL.items():
    cat,name=id.split('/'); d=json.load(open(f'{OUT}/{id}/{name}.json')); im=Image.open(f'{OUT}/{id}/{name}.png').convert('RGBA')
    fw=d['frames'][0]['frame']['w']; fh=d['frames'][0]['frame']['h']; cols=im.width//fw
    meta=open(f'{SRC}/{id}.js').read(); m=re.search(r'origin:\s*\[(\d+),\s*(\d+)\]',meta); ox,oy=(int(m[1]),int(m[2])) if m else (fw//2,fh//2)
    loop='loop: true' in meta
    idx=list(range(0,min(mx,len(d['frames'])),skip)); fr=[im.crop(((i%cols)*fw,(i//cols)*fh,(i%cols)*fw+fw,(i//cols)*fh+fh)) for i in idx]
    # union bbox
    bb=None
    for f in fr:
        b=f.getchannel('A').point(lambda v:255 if v>8 else 0).getbbox()
        if b: bb=b if bb is None else (min(bb[0],b[0]),min(bb[1],b[1]),max(bb[2],b[2]),max(bb[3],b[3]))
    bb=bb or (0,0,fw,fh); cw,ch=bb[2]-bb[0],bb[3]-bb[1]; n=len(fr); c2=min(n,8 if cw<200 else 6); r2=(n+c2-1)//c2
    sh=Image.new('RGBA',(cw*c2,ch*r2),(0,0,0,0))
    for k,f in enumerate(fr): sh.alpha_composite(f.crop(bb),((k%c2)*cw,(k//c2)*ch))
    key=name; sh.save(f'{DST}/{key}.png',optimize=True)
    ms=round(sum(x['duration'] for x in d['frames'])/len(d['frames'])*skip)
    man[key]=dict(w=cw,h=ch,n=n,cols=c2,ms=ms,ox=ox-bb[0],oy=oy-bb[1],loop=loop,id=id)
    print(key,n,cw,ch,os.path.getsize(f'{DST}/{key}.png')//1024,'KB',ms,'ms')
open('/home/claude/classroom/web/pixelfx.js','w').write('/* สไปรต์เอฟเฟกต์พิกเซลจาก pixelfx (https://github.com/patch-gg/pixelfx) · MIT License · (c) patch-gg */\nconst PFX_DATA = '+json.dumps(man,separators=(',',':'))+';\n')
