"""Card & Krueger (1994): Table 5 specification tests and the IV test of the first-difference model.

Usage: python -I ck_table5_iv.py <path/to/public.dat>
Published values are transcribed from Table 5 (AER 84(4), p. 783) and the IV result from p. 784.
Rows 10-11 (Newark, Camden) need ZIP codes, which the public file does not contain.
"""
import sys

import numpy as np
import pandas as pd

COLS = """sheet chain co_owned state southj centralj northj pa1 pa2 shore ncalls empft emppt
nmgrs wage_st inctime firstinc bonus pctaff meals open hrsopen psoda pfry pentree nregs nregs11
type2 status2 date2 ncalls2 empft2 emppt2 nmgrs2 wage_st2 inctime2 firstin2 special2 meals2
open2r hrsopen2 psoda2 pfry2 pentree2 nregs2 nregs112""".split()
raw = pd.read_csv(sys.argv[1], sep=r"\s+", header=None, names=COLS, na_values=".")

CTRL = ["bk", "kfc", "roys", "co_owned"]


def build(pt=0.5, managers=True, temp_closed_as_closed=False, pa_gap=False):
    d = raw.copy()
    m1 = d.nmgrs if managers else 0
    m2 = d.nmgrs2 if managers else 0
    d["emptot"] = d.emppt * pt + d.empft + m1
    d["emptot2"] = d.emppt2 * pt + d.empft2 + m2
    d["closed"] = (d.status2 == 3).astype(float)
    if temp_closed_as_closed:
        tc = d.status2.isin([2, 4, 5])
        d.loc[tc, "emptot2"] = 0.0
        d.loc[tc, "closed"] = 1.0
    d["demp"] = d.emptot2 - d.emptot
    d["pchempc"] = 2 * d.demp / (d.emptot2 + d.emptot)
    d.loc[d.emptot2 == 0, "pchempc"] = -1
    d["dwage"] = d.wage_st2 - d.wage_st
    g = np.where(d.wage_st >= 5.05, 0.0, (5.05 - d.wage_st) / d.wage_st)
    g = np.where(d.wage_st.isna(), np.nan, g)
    d["gap"] = g if pa_gap else np.where(d.state == 0, 0.0, g)
    d["nj"] = d.state
    for k, nm in enumerate(["bk", "kfc", "roys", "wendys"], 1):
        d[nm] = (d.chain == k).astype(float)
    return d[d.demp.notna() & ((d.closed == 1) | ((d.closed == 0) & d.dwage.notna()))].copy()


def ols(d, y, xs, w=None):
    d = d[[y] + xs + ([w] if w else [])].dropna()
    X = np.column_stack([np.ones(len(d))] + [d[x].to_numpy(float) for x in xs])
    Y = d[y].to_numpy(float)
    W = d[w].to_numpy(float) if w else np.ones(len(d))
    XtWX = X.T @ (X * W[:, None])
    b = np.linalg.solve(XtWX, X.T @ (W * Y))
    e = Y - X @ b
    s2 = (W * e * e).sum() / (len(d) - X.shape[1])
    se = np.sqrt(np.diag(s2 * np.linalg.inv(XtWX)))
    return b[1], se[1], len(d)


def row(d, extra=None, w=None, cols=("nj", "gap")):
    extra = extra or []
    out = []
    for y in ("demp", "pchempc"):
        for key in ("nj", "gap"):
            if key not in cols or (w and y == "demp"):
                out.append(None)
            else:
                out.append(ols(d, y, [key] + CTRL + extra, w))
    return out


PUB = {
    1: [(2.30, 1.19), (14.92, 6.21), (0.05, 0.05), (0.34, 0.26)],
    2: [(2.20, 1.21), (14.42, 6.31), (0.04, 0.05), (0.34, 0.27)],
    3: [(2.34, 1.17), (14.69, 6.05), (0.05, 0.07), (0.28, 0.34)],
    4: [(2.34, 1.20), (15.23, 6.23), (0.06, 0.06), (0.30, 0.33)],
    5: [(2.27, 1.21), (14.60, 6.26), (0.04, 0.06), (0.17, 0.29)],
    6: [(2.58, 1.19), (16.88, 6.36), (0.06, 0.05), (0.42, 0.27)],
    7: [(2.27, 1.20), (15.79, 6.24), (0.05, 0.05), (0.40, 0.26)],
    8: [(2.41, 1.28), (14.08, 7.11), (0.05, 0.05), (0.31, 0.29)],
    9: [None, None, (0.13, 0.05), (0.81, 0.26)],
    12: [None, (-0.30, 22.00), None, (-0.33, 0.74)],
}


def fmt(cell, pub):
    if cell is None:
        return f"{'-':>27}"
    b, s, n = cell
    tag = ""
    if pub:
        ok = abs(round(b, 2) - pub[0]) < 0.006 and abs(round(s, 2) - pub[1]) < 0.006
        tag = "=" if ok else "x"
    return f"{b:7.2f} ({s:5.2f}) n={n:3d} {tag:1}"


base = build()
# wave-2 interview week; one date is coded 111191 (1991), read as 1992
dt = pd.to_datetime(base.date2.astype("Int64").astype(str).str.zfill(6).str[:4] + "92", format="%m%d%y", errors="coerce")
wk = dt.dt.isocalendar().week
base["wk46"] = (wk == 46).astype(float)
base["wk47"] = (wk == 47).astype(float)
base["wkdec"] = (wk >= 48).astype(float)

rows = [
    (1, "Base specification", base, {}),
    (2, "Temporarily closed stores as closed", build(temp_closed_as_closed=True), {}),
    (3, "Exclude managers (same 357 stores)", (lambda m: m[m.index.isin(base.index)])(build(managers=False)), {}),
    (4, "Part-time weight 0.4", build(pt=0.4), {}),
    (5, "Part-time weight 0.6", build(pt=0.6), {}),
    (6, "Exclude NJ shore stores", base[base.shore != 1], {}),
    (7, "Wave-2 interview week dummies", base, {"extra": ["wk46", "wk47", "wkdec"]}),
    (8, "Exclude stores called >2 times (ncalls>=3)", base[~(base.ncalls >= 3)], {}),
    ("8b", "  variant: ncalls>=2", base[~(base.ncalls >= 2)], {}),
    (9, "Weight by initial employment", base, {"w": "emptot"}),
]
pa = build(pa_gap=True)
pa = pa[pa.nj == 0]
rows.append((12, "Pennsylvania only, placebo gap", pa, {"cols": ("gap",)}))

print("Table 5. Each cell: ours (SE) n, then = if it matches the published value at 2 decimals, x if not")
print(f"{'':45}{'(i) NJ, change':>27}{'(ii) GAP, change':>27}{'(iii) NJ, prop.':>27}{'(iv) GAP, prop.':>27}")
nmatch = ntot = 0
for r, label, d, kw in rows:
    cells = row(d, **kw)
    pub = PUB.get(r, [None] * 4)
    line = f"{str(r):>3} {label:41}" + "".join(fmt(c, p) for c, p in zip(cells, pub))
    print(line)
    if r in PUB:
        for c, p in zip(cells, pub):
            if c is not None and p is not None:
                ntot += 1
                nmatch += abs(round(c[0], 2) - p[0]) < 0.006 and abs(round(c[1], 2) - p[1]) < 0.006
    if r in PUB:
        print(f"{'':45}" + "".join(f"{'paper ' + (f'{p[0]:.2f} ({p[1]:.2f})' if p else '-'):>27}" for p in pub))
print(f"Matched {nmatch} of {ntot} published cells (coefficient and SE at 2 decimals).")
print(f"Counts: shore stores in sample {int(base.shore.sum())} (paper: 35 excluded); "
      f"ncalls>=3: {int((base.ncalls >= 3).sum())}, ncalls>=2: {int((base.ncalls >= 2).sum())} (paper: 70, 69 in NJ)")

# IV test: change in employment on wave-1 employment, instrumented by registers
d = base[["demp", "emptot", "gap", "nregs", "nregs11"] + CTRL].dropna()
y = d.demp.to_numpy(float)
exog = np.column_stack([np.ones(len(d))] + [d[c].to_numpy(float) for c in ["gap"] + CTRL])
Z = np.column_stack([exog, d.nregs, d.nregs11])
X = np.column_stack([exog, d.emptot])
Xhat = Z @ np.linalg.lstsq(Z, X, rcond=None)[0]
b = np.linalg.lstsq(Xhat, y, rcond=None)[0]
e = y - X @ b
s2 = e @ e / (len(d) - X.shape[1])
se = np.sqrt(np.diag(s2 * np.linalg.inv(Xhat.T @ Xhat)))
fs = np.linalg.lstsq(Z, d.emptot.to_numpy(float), rcond=None)
b_ols, se_ols, _ = ols(d, "demp", ["emptot", "gap"] + CTRL)
print()
print("IV test of the first-difference model (paper p. 784: coefficient 0.04, SE 0.24)")
print(f"  2SLS coefficient of wave-1 FTE: {b[-1]:.2f} (SE {se[-1]:.2f}), n={len(d)}; GAP coefficient {b[1]:.2f} ({se[1]:.2f})")
print(f"  OLS for comparison: {b_ols:.2f} (SE {se_ols:.2f})  <- pulled negative by measurement error")
