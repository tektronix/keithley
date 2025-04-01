# tested with
# EA Elektro-Automatik GmbH & Co. KG, PS 9040-20 T
# over RS-232

import pyvisa
import pyvisa.constants as pyconst
import time
import numpy as np
import matplotlib.pyplot as plt

#instrument_resource_string = "TCPIP0::192.168.1.176::5025::SOCKET"   
#EA uses port 5025 on LAN
instrument_resource_string = "ASRL2::INSTR"

resource_mgr = pyvisa.ResourceManager()
my_instr = resource_mgr.open_resource(instrument_resource_string)

my_instr.write_termination = '\n'  
my_instr.read_termination = '\n'

my_instr.baud_rate = 9600
my_instr.data_bits = 8
my_instr.parity = pyconst.Parity.none
my_instr.stop_bits = pyconst.StopBits.one
#my_instr.flow_control = flow_control
my_instr.write_termination = "\n"
my_instr.send_end = True

my_instr.timeout = 5000   #timeout in msec
my_instr.VI_ATTR_TCPIP_KEEPALIVE = True

my_instr.write("*IDN?")
print(my_instr.read())

my_instr.write("SYST:LOCK ON")  # enable remote control

# some configuration
# Create a list of voltage levels
voltage_list = {}
start_v = 0
stop_v = 20
num_pts = 81
my_array = np.linspace(start_v, stop_v, num_pts)
voltage_list = my_array.tolist()
print("Number of entries in list: " + str(len(voltage_list)))

volts = []
amps = []

initial_volts = 0
current_limit = 0.5
current_trip = current_limit * 1.2  # make trip value 20% higher than current limit
max_watts = stop_v * current_trip    # set power limit

#set some limits and current OCP alarm trip level
cmd_list = ["*RST",
            "*CLS",
            "SOUR:VOLT %g" %initial_volts,
            "SOUR:CURR %g" %current_limit,
            "CURR:PROT %g" %current_trip,
            "SOUR:POW %g" %max_watts]    

for cmd in cmd_list:
    my_instr.write(cmd)



LOOP_DELAY = 0.1  #seconds to wait after commanding the source level

my_instr.write("OUTP ON")

for j in range(0,1):
    if j > 0 : 
        my_instr.write("VOLT 0")
        time.sleep(0.35)
    for i in range( 0 ,len(voltage_list)):
        my_instr.write(":VOLT " + str(voltage_list[i]))
        time.sleep(LOOP_DELAY)
        temp_volts = my_instr.query("MEAS:VOLT?")
        temp_curr = my_instr.query("MEAS:CURR?")
        volts.append(float(temp_volts[:-2]))
        amps.append(float(temp_curr[:-2]))
        #print(str(i) + " *** " + my_instr.query("STAT:OPER:COND?") + " *** " + str(voltage_list[i]))
        # value of 265 = CV mode
        # value of 512 = CC mode in current limiting
        
        
    
 
#set the voltage back to zero
my_instr.write("VOLT 0")
time.sleep(0.05)
#output off
my_instr.write("OUTP OFF")


my_instr.write("SYST:ERR?")
print("Response to error query: %s" %my_instr.read())   #read the response


#plot the data
#plot the absolute value of current vs. voltage   
x_min = 0  #min(volts) * 1.1
x_max = max(volts) * 1.1
y_min = abs(min(amps)) / 10
y_max = abs(max(amps)) * 10
#plt.axis([x_min,x_max,y_min,y_max]) 
plt.plot(volts, amps, 'o-g')
plt.title('Sweep V, Measure I')
plt.margins(x=0.1, y=0.1)
plt.grid(True)
plt.show()

#print("*******************")
#print(y_max)
#print(y_min)
#print(x_max)
#print(x_min)
#print("*******************")

#put instrument back to local and close connection
my_instr.write("SYST:LOCK OFF")  # disable remote control
my_instr.clear()
my_instr.close()
resource_mgr.close()