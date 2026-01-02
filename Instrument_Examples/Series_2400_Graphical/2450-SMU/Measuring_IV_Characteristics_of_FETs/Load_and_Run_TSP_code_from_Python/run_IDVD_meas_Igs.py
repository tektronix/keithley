
import io
import sys
import time
import os
import pyvisa
from pyvisa.errors import VisaIOError
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# =========================
# Settings: EDIT AS NEEDED
# =========================
RESOURCE = "TCPIP0::192.168.0.50::INSTR"  # <-- replace with your instrument address
VGS_STEPS_CSV = "2,3,4,5"                 # gate steps (CSV string, e.g., "2,3,4,5")
VDS_START = 0.0
VDS_STEP = 0.1
VDS_POINTS = 51                           # 0..5 V in 0.1 V → 51 points
VDS_DELAY_S = 0.01                        # 10 ms settle per point

# If you use a Jupyter notebook:
# %matplotlib inline



def open_visa(resource):
    rm = pyvisa.ResourceManager()
    inst = rm.open_resource(resource)
    # Keithley 2450 usually uses LF termination
    inst.read_termination = '\n'
    #inst.write_termination = '\n'
    inst.timeout = 10000  # increase if needed for long sweeps
    inst.encoding = 'utf-8'   #<-- was getting an error for non-ASCII in the tsp file?
    return rm, inst


# ---------------------------
# Load TSP Script
# ---------------------------
def load_tsp_script(instr, tsp_file, script_name, auto_run=True):
    """
    Load a TSP script from a file into the instrument runtime memory line-by-line.
    You can write and test that TSP file with the hardware using TSP Toolkit!

    Parameters
    ----------
    instr : pyvisa.Resource
        The instrument handle.
    tsp_file : str
        Filename of the TSP script (relative to this Python file or absolute path).
    script_name : str
        Name to assign to the script on the instrument.
    auto_run : bool
        If True, calls <script_name>.run() after loading.
    """
    file_path = os.path.join(os.path.dirname(__file__), tsp_file)

    # Delete any existing script with the same name
    try:
        instr.write(f"script.delete('{script_name}')")
    except Exception:
        pass  # Ignore if script doesn't exist

    # Begin loading script
    instr.write(f"loadscript {script_name}")

    # Send file contents line by line
    with open(file_path, 'r', encoding='utf-8') as fp:
        for line in fp:
            # Ensure newline termination
            if not line.endswith('\n'):
                line += '\n'
            instr.write(line)

    # End script
    instr.write("endscript")

    # Optionally run the script
    if auto_run:
        instr.write(f"{script_name}.run()")


# ---------------------------
# For Vgs list of values, build a Lua formatted table of values:
#     { 2, 3, 4, 5 }
# ---------------------------
def csv_to_lua_numeric_table_literal(csv: str) -> str:
    items = csv.split(",")
    nums = []
    for s in items:
        s = s.strip()
        # Validate numeric; int/float both fine
        try:
            x = float(s)
        except ValueError:
            raise ValueError(f"CSV contains non-numeric entry: {s!r}")
        if not (x == x) or x in (float('inf'), float('-inf')):
            raise ValueError("NaN/Inf are not representable in Lua numeric literals")
        # Use repr to preserve scientific notation (Lua supports it)
        nums.append(repr(x))
    return "{" + ",".join(nums) + "}"


# ---------------------------
# Call the run_test() Lua function
# Loop until status byte tells us operation is complete
# Call the print_data() Lua function and read results
# ---------------------------
def run_idvd_and_fetch(inst,
                       vgs_steps_csv: str,
                       vds_start: float,
                       vds_step: float,
                       vds_points: int,
                       vds_delay_s: float):
    # Configure VGS steps
    vgs_steps_lua_table = csv_to_lua_numeric_table_literal(VGS_STEPS_CSV)

    script_running = True
    status_byte = 0
    debug = 1
    
    #read status byte before launcing the blocknig task
    status_byte = inst.read_stb()
   
    inst.write(f"benchmark = run_test({vgs_steps_lua_table}, {vds_start}, {vds_step}, {vds_points}, {vds_delay_s})")
    
    #loop until status byte signals RQS bit is set
    while script_running:
        status_byte = inst.read_stb()

        if status_byte & 64 == 64:
            script_running = False
        else
            time.sleep(0.5)  #delay before looping back to get new stb value


    #optional ask for test time
    print(inst.query("print(benchmark)"))  
    
    # Fetch data
    #tell instrument to send us CSV of the data from the buffers
    inst.write("print_results()")  
    response = inst.read()
    
    return response
    

# ---------------------------
#  print_results will return comma separated list:
#     Vds, Ids, Vgs, Igs, repeat,
#  Parse the csv data stream into 4 columns in dataframe
# ---------------------------
def parse_csv_to_df(csv_text: str) -> pd.DataFrame:
    """
    Parse a flat CSV like "Vd,Id,Vg,Ig,Vd,Id,Vg,Ig,..." into a DataFrame with columns:
    ['Vd', 'Id', 'Vg', 'Ig'].

    - Ignores empty tokens/extra commas.
    - Casts to float; sets NaN for non-numeric entries.
    - Drops trailing incomplete quartets (with a warning).
    """
    # Tokenize, trim, and discard empty tokens
    tokens = [t.strip() for t in csv_text.split(",") if t.strip() != ""]
    if not tokens:
        return pd.DataFrame(columns=["Vd", "Id", "Vg", "Ig"])

    # Convert to numeric (float); non-numeric -> NaN
    values = []
    for t in tokens:
        try:
            values.append(float(t))
        except ValueError:
            values.append(float("nan"))

    # Ensure length is a multiple of 4

    remainder = len(values) % 4
    if remainder != 0:
        # You can choose to raise instead; here we just truncate cleanly
        # print(f"Warning: {remainder} trailing values discarded (not a full quartet).")
        values = values[:len(values) - remainder]

    # Reshape: groups of four → rows
    rows = [values[i:i+4] for i in range(0, len(values), 4)]

    df = pd.DataFrame(rows, columns=["Vd", "Id", "Vg", "Ig"])
    return df


# ---------------------------
# Plot the IDVD family of curves
# Save the png file if save_path value provided
#
# ---------------------------
def plot_idvd(df, title="Id–Vd curves by Vg", save_path=None):
    # Ensure numeric sorting for each Vg group (nice smooth lines)
    plt.figure(figsize=(8, 6))
        
    # Round Vg and use that for grouping/legend
    df["Vg_round"] = df["Vg"].round(decimals=2)
    unique_vg = np.sort(df["Vg_round"].unique())


    for vg in unique_vg:
        grp = df[df["Vg_round"] == vg].sort_values("Vd")
        if grp.empty:
            continue
        plt.plot(grp["Vd"], grp["Id"], marker="o", markersize=4, linewidth=1.5, label=f"Vg = {vg:g} V")

    plt.title(title)
    plt.xlabel("Vd (V)")
    plt.ylabel("Id (A)")
    plt.grid(True, linestyle="--", alpha=0.4)
    plt.legend(title="Gate bias", loc="best", fontsize=9)
    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150)
    plt.show()


def main():
    rm, inst = open_visa(RESOURCE)
    try:

        # load once until you reboot instrument 
        # or need to load a modified version of the TSP functions
        first_time_run = 1
        if first_time_run == 1:
            #load_tsp_script(instr, tsp_file, script_name, auto_run=True)
            load_tsp_script(inst, "IDVD_meas_Igs.tsp", "IDVD", auto_run=True)

        #run the test    
        csv_text = run_idvd_and_fetch(inst, VGS_STEPS_CSV, VDS_START, VDS_STEP, VDS_POINTS, VDS_DELAY_S)

        #print("***********  raw string from VISA reads *********")
        #print(csv_text)

        
        df = parse_csv_to_df(csv_text)

        # Show DataFrame summary
        print(df.head(10))
        print()
        
        # Plot Ids vs Vds for each Vgs
        plot_idvd(df, save_path = "IDVD_2450.png")

    finally:
        # Optional: turn outputs off if needed (safe cleanup)
        try:
            #inst.write("emit_last_test_time()")
            # Read the last test time line (non-critical)
            try:
                inst.write("smu.source.output = 0")
                inst.write("node[2].smu.source.output = 0")
            except Exception:
                pass
        except Exception:
            pass
 
        inst.clear()
        inst.close()
        rm.close()

if __name__ == "__main__":
    main()
