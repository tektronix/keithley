"""
Visualize LIV data produced by measurementLIV_CaseI_2601B_PULSE_DMM.tsp.

Expected input (tab-separated, as printed to the TSB console):
     Time (s)   Current (A)   Voltage(V)   DMM1(A)   DMM1(W)

    Current / Voltage : laser diode, measured by the 2601B-PULSE
    DMM1(A)           : photodiode current, measured by the DMM6500/7510
    DMM1(W)           : optical power = |DMM1(A)| * optoFactor

Usage (or just press Run in VS Code - edit DATA_FILE below to change the input):
(the plot is also saved as <data file>.png next to the data)
    python plot_liv.py [data_file] [--save out.png] [--no-save] [--no-show]

Requires: numpy, matplotlib  (pip install numpy matplotlib)
"""

import argparse
import sys
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

# ---- Edit this to change the input file (relative to this script, or absolute) ----
DATA_FILE = "measurementLIV.txt"

# Palette (light mode) - one hue per measure, text stays in neutral ink
SURFACE = "#fcfcfb"
INK = "#0b0b0b"
INK_2 = "#52514e"
GRID = "#e4e3df"
C_L = "#2a78d6"   # optical power
C_V = "#eb6834"   # voltage
C_R = "#6250d6"   # differential resistance

# A linear fit to the L-I curve is only reported as a threshold if it is this good
MIN_FIT_R2 = 0.9


def load_liv(path):
    """Return dict of arrays, skipping any console text before the header."""
    path = Path(path)
    if not path.is_file():
        sys.exit(f"Data file not found: {path}\nEdit DATA_FILE at the top of {Path(__file__).name} or pass a path.")
    lines = path.read_text().splitlines()
    try:
        start = next(i for i, ln in enumerate(lines) if "Current (A)" in ln) + 1
    except StopIteration:
        sys.exit(f"No 'Current (A)' header found in {path}")

    rows = []
    for ln in lines[start:]:
        parts = ln.split()
        if len(parts) < 5:
            continue
        try:
            rows.append([float(p) for p in parts[:5]])
        except ValueError:
            break  # end of the data block
    if not rows:
        sys.exit(f"No data rows found in {path}")

    d = np.array(rows)
    return {"t": d[:, 0], "i": d[:, 1], "v": d[:, 2], "ipd": d[:, 3], "p": d[:, 4]}


def threshold_fit(i, p, win=5):
    """Fit the steepest straight stretch of the L-I curve (win points).

    Returns (Ith, slope, r2) or None if no good fit / non-positive threshold.
    """
    if len(i) < win:
        return None
    best = None
    for k in range(len(i) - win + 1):
        x, y = i[k:k + win], p[k:k + win]
        m, b = np.polyfit(x, y, 1)
        if best is None or m > best[0]:
            ss_tot = np.sum((y - y.mean()) ** 2)
            r2 = 1 - np.sum((y - (m * x + b)) ** 2) / ss_tot if ss_tot > 0 else 0.0
            best = (m, b, r2)
    m, b, r2 = best
    if m <= 0 or r2 < MIN_FIT_R2 or -b / m < 0:
        return None
    return -b / m, m, r2


def style_axis(ax, ylabel):
    ax.set_facecolor(SURFACE)
    ax.set_ylabel(ylabel, color=INK_2)
    ax.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.tick_params(colors=INK_2, length=0)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    for side in ("left", "bottom"):
        ax.spines[side].set_color(GRID)


def plot_liv(d, title):
    i_ma = d["i"] * 1e3
    p_w = d["p"]  # DMM1(W) column is already in watts
    v = d["v"]
    # Differential resistance dV/dI between adjacent sweep points
    i_mid = 0.5 * (i_ma[1:] + i_ma[:-1])
    r_diff = np.diff(v) / np.diff(d["i"])

    fig, (ax_l, ax_v, ax_r) = plt.subplots(
        3, 1, sharex=True, figsize=(8, 9),
        gridspec_kw={"height_ratios": [3, 2, 1.5]},
    )
    fig.patch.set_facecolor(SURFACE)
    fig.suptitle(title, color=INK, fontsize=13, x=0.06, ha="left")

    # L-I
    style_axis(ax_l, "Optical power (W)")
    ax_l.plot(i_ma, p_w, color=C_L, linewidth=2, marker="o", markersize=5,
              markeredgecolor=SURFACE, markeredgewidth=1.5)
    fit = threshold_fit(d["i"], d["p"])
    if fit:
        ith, slope, r2 = fit
        xs = np.array([ith, d["i"].max()])
        ax_l.plot(xs * 1e3, slope * (xs - ith), color=INK_2,
                  linewidth=1, linestyle="--")
        note = (f"I$_{{th}}$ ≈ {ith * 1e3:.1f} mA,  "
                f"slope ≈ {slope:.3f} W/A  (R² {r2:.3f})")
    else:
        note = "No lasing threshold detected - no linear rising L-I segment, check PD signal"
    ax_l.set_title(note, loc="left", color=INK_2, fontsize=9)

    # V-I
    style_axis(ax_v, "Voltage (V)")
    ax_v.plot(i_ma, v, color=C_V, linewidth=2, marker="o", markersize=5,
              markeredgecolor=SURFACE, markeredgewidth=1.5)

    # dV/dI
    style_axis(ax_r, "dV/dI (Ω)")
    ax_r.plot(i_mid, r_diff, color=C_R, linewidth=2, marker="o", markersize=4,
              markeredgecolor=SURFACE, markeredgewidth=1.2)
    ax_r.set_xlabel("Laser drive current (mA)", color=INK_2)

    fig.tight_layout()
    return fig


def main():
    here = Path(__file__).resolve().parent
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("data", nargs="?", default=here / DATA_FILE)
    ap.add_argument("--save", help="image file to write (png/pdf/svg); default: <data file>.png")
    ap.add_argument("--no-save", action="store_true", help="don't write an image")
    ap.add_argument("--no-show", action="store_true", help="don't open a window")
    args = ap.parse_args()

    d = load_liv(args.data)
    print(f"{len(d['i'])} points, I = {d['i'].min()*1e3:.2f} .. {d['i'].max()*1e3:.2f} mA, "
          f"V = {d['v'].min():.3f} .. {d['v'].max():.3f} V, "
          f"P = {d['p'].min():.3f} .. {d['p'].max():.3f} W")

    # Warn if the photodiode does not track the drive current at all
    corr = np.corrcoef(d["i"], d["p"])[0, 1]
    if not np.isfinite(corr) or corr < 0.5:
        print(f"WARNING: optical power is uncorrelated with drive current "
              f"(r = {corr:.2f}); PD readings look like noise.")

    fig = plot_liv(d, f"LIV - {Path(args.data).name}")
    if not args.no_save:
        out = Path(args.save) if args.save else Path(args.data).with_suffix(".png")
        fig.savefig(out, dpi=150, facecolor=SURFACE)
        print(f"Saved {out}")
    if not args.no_show:
        plt.show()


if __name__ == "__main__":
    main()
