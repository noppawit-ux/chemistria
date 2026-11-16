"""สร้างรูปโครงสร้างสำหรับข้อสอบไอโซเมอร์ด้วย RDKit -> web/assets/exam/isomer/*.png"""
import os, sys
from rdkit import Chem
from rdkit.Chem import Draw
from rdkit.Chem.Draw import rdMolDraw2D
OUT = os.path.join(os.path.dirname(__file__), "..", "web", "assets", "exam", "isomer")
os.makedirs(OUT, exist_ok=True)
M = {
 "pentane": "CCCCC", "2mebutane": "CC(C)CC", "neopentane": "CC(C)(C)C",
 "butane": "CCCC", "isobutane": "CC(C)C",
 "1propanol": "CCCO", "2propanol": "CC(O)C", "ethanol": "CCO", "dme": "COC",
 "1butene": "C=CCC", "cis2butene": "C/C=C\\C", "trans2butene": "C/C=C/C", "propene": "C=CC", "isobutene": "C=C(C)C",
 "cisdce": "Cl/C=C\\Cl", "transdce": "Cl/C=C/Cl", "11dce": "C=C(Cl)Cl", "2pentene": "C/C=C/CC", "2me2butene": "CC=C(C)C",
 "2butanol": "CC(O)CC", "lactic": "CC(O)C(=O)O", "2clbutane": "CC(Cl)CC", "3mehexane": "CCC(C)CCC", "3pentanol": "CCC(O)CC",
 "propanal": "CCC=O", "acetone": "CC(C)=O", "23dbp": "CC(Br)C(Br)CC",
 "r2butanol": "CC[C@H](C)O", "s2butanol": "CC[C@@H](C)O",
 "cyclobutane": "C1CCC1", "mecyclopropane": "CC1CC1",
}
def draw(smi, path, w=300, h=220):
    m = Chem.MolFromSmiles(smi); d = rdMolDraw2D.MolDraw2DCairo(w, h); o = d.drawOptions()
    o.bondLineWidth = 3; o.padding = 0.12; o.setBackgroundColour((1, 1, 1, 1)); o.addStereoAnnotation = False
    d.DrawMolecule(m); d.FinishDrawing(); open(path, "wb").write(d.GetDrawingText())
def pair(a, b, path):
    ms = [Chem.MolFromSmiles(M[a]), Chem.MolFromSmiles(M[b])]
    img = Draw.MolsToGridImage(ms, molsPerRow=2, subImgSize=(250, 190), useSVG=False); img.save(path)
for k, s in M.items(): draw(s, os.path.join(OUT, k + ".png"))
for a, b, n in [("butane", "isobutane", "p_chain"), ("pentane", "neopentane", "p_chain2"), ("1propanol", "2propanol", "p_pos"), ("1butene", "cis2butene", "p_pos2"),
                ("ethanol", "dme", "p_func"), ("propanal", "acetone", "p_func2"), ("cisdce", "transdce", "p_geo"), ("r2butanol", "s2butanol", "p_enan")]:
    pair(a, b, os.path.join(OUT, n + ".png"))
print(len(os.listdir(OUT)), "files")
