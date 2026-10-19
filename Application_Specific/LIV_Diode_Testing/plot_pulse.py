"""
Visualize pulse waveforms produced by completePulse_CaseI_2601B_PULSE_DMM.tsp.

Expected input (tab-separated, as printed to the TSB console):
    Time (s)   Current (A)   Voltage (V)   CurrentPD(A)

    Current / Voltage : laser diode, digitized by the 2601B-PULSE
    CurrentPD(A)      : photodiode current, digitized by the DMM6500/7510

The file holds nPulse back-to-back waveforms of noReadings samples each; pulses
are split wherever the timestamp jumps (the gap between pulse periods).

Usage (or just press Run in VS Code - edit DATA_FILE below to change the input):
(the plot is also saved as <data file>.png next to the data)
    python plot_pulse.py [data_file] [--save out.png] [--no-save] [--no-show]

Requires: numpy, matplotlib  (pip install numpy matplotlib)
"""

import argparse
import sys
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm, colors

from plot_liv import SURFACE, INK, INK_2, style_axis

# ---- Edit this to change the input file (relative to this script, or absolute) ----
DATA_FILE = "completePulse.txt"

# Categorical order (fixed, never cycled); past 8 pulses switch to a sequential ramp
SERIES = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100",
          "#e87ba4", "#008300", "#6250d6", "#e34948"]

# Samples whose current is within this fraction of the pulse peak count as the plateau
PLATEAU_FRAC = 0.95


def load_pulses(path):
    """Return list of per-pulse dicts (t relative to pulse start, i, v, ipd)."""
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
        if len(parts) < 4:
            continue
        try:
            rows.append([float(p) for p in parts[:4]])
        except ValueError:
            break  # end of the data block
    if len(rows) < 2:
        sys.exit(f"No data rows found in {path}")

    d = np.array(rows)
    dt = np.diff(d[:, 0])
    gaps = np.where(dt > 10 * np.median(dt))[0] + 1
    pulses = []
    for seg in np.split(d, gaps):
        pulses.append({"t": seg[:, 0] - seg[0, 0], "i": seg[:, 1],
                       "v": seg[:, 2], "ipd": seg[:, 3]})
    return pulses, float(np.median(dt))


def plateau(p):
    """Mean I, V, Ipd over the flat top of the pulse."""
    top = p["i"] >= PLATEAU_FRAC * p["i"].max()
    return p["i"][top].mean(), p["v"][top].mean(), p["ipd"][top].mean(), top.sum()


def current_unit(values):
    """Pick A/mA/uA/nA so the largest reading shows as a readable number."""
    peak = np.max(np.abs(values))
    for scale, unit in ((1, "A"), (1e3, "mA"), (1e6, "µA"), (1e9, "nA")):
        if peak * scale >= 1:
            return scale, unit
    return 1e9, "nA"


def plot_pulses(pulses, title):
    n = len(pulses)
    if n <= len(SERIES):
        line_colors = SERIES[:n]
        ramp = None
    else:
        ramp = cm.ScalarMappable(colors.Normalize(1, n), cm.Blues)
        line_colors = [ramp.to_rgba(k + 1 + 0.35 * n) for k in range(n)]

    pd_scale, pd_unit = current_unit(np.concatenate([p["ipd"] for p in pulses]))

    fig, (ax_i, ax_v, ax_pd) = plt.subplots(3, 1, sharex=True, figsize=(8, 9))
    fig.patch.set_facecolor(SURFACE)
    fig.suptitle(title, color=INK, fontsize=13, x=0.06, ha="left")
    style_axis(ax_i, "Laser current (mA)")
    style_axis(ax_v, "Laser voltage (V)")
    style_axis(ax_pd, f"Photodiode current ({pd_unit})")
    ax_pd.set_xlabel("Time from pulse start (µs)", color=INK_2)

    for k, (p, c) in enumerate(zip(pulses, line_colors)):
        i_top = plateau(p)[0]
        label = f"Pulse {k + 1}  ({i_top * 1e3:.0f} mA)"
        t_us = p["t"] * 1e6
        kw = dict(color=c, linewidth=2)
        ax_i.plot(t_us, p["i"] * 1e3, label=label, **kw)
        ax_v.plot(t_us, p["v"], **kw)
        ax_pd.plot(t_us, p["ipd"] * pd_scale, **kw)

    if ramp is None:
        ax_i.legend(frameon=False, labelcolor=INK_2, fontsize=9,
                    loc="upper left", bbox_to_anchor=(0, 1.12), ncol=min(n, 4))
    else:
        cb = fig.colorbar(ramp, ax=[ax_i, ax_v, ax_pd], pad=0.02)
        cb.set_label("Pulse #", color=INK_2)

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
    sys.stdout.reconfigure(encoding="utf-8")

    pulses, dt = load_pulses(args.data)
    print(f"{len(pulses)} pulse(s), {len(pulses[0]['t'])} samples each, "
          f"sample interval {dt * 1e6:.1f} µs")
    print(f"{'Pulse':>5} {'I_top (mA)':>11} {'V_top (V)':>10} {'Ipd_top (A)':>12} {'n_top':>6}")
    for k, p in enumerate(pulses):
        i, v, ipd, n = plateau(p)
        print(f"{k + 1:>5} {i * 1e3:>11.3f} {v:>10.4f} {ipd:>12.4e} {n:>6}")

    # Warn if the photodiode does not follow the laser pulse
    i_all = np.concatenate([p["i"] for p in pulses])
    pd_all = np.concatenate([p["ipd"] for p in pulses])
    corr = np.corrcoef(i_all, pd_all)[0, 1]
    if not np.isfinite(corr) or corr < 0.5:
        print(f"WARNING: photodiode current does not follow the laser pulse "
              f"(r = {corr:.2f}); PD readings look like noise.")

    fig = plot_pulses(pulses, f"Pulse waveforms - {Path(args.data).name}")
    if not args.no_save:
        out = Path(args.save) if args.save else Path(args.data).with_suffix(".png")
        fig.savefig(out, dpi=150, facecolor=SURFACE)
        print(f"Saved {out}")
    if not args.no_show:
        plt.show()


if __name__ == "__main__":
    main()
