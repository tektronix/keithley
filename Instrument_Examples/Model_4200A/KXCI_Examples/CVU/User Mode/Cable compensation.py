"""
This example performs allows the user to make cable compensation
measurements (load, custom, open, and short) using the
4200A-SCS CVU via an ethernet connection.
Device used: N/A
"""

from instrcomms import Communications

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" #Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" #Set PyVISA read terminator

my4200.query("BC") #Clear all readings from the buffer
my4200.query(":CVU:RESET") #Resets the CVU card
my4200.query(":CVU:MODE 0") #Sets the mode to User Mode

'''
Uncomment the compensation mode chosen to run, and enter the cable length
0: <= 0.5 m Cable
1.5: > 0.5 m to < 2.5 m Cable
3.0: >= 2.5 m to 5 m Cable
4.0: Custom Cable Length
5.0: CVIV 2W Cable
6.0: CVIV 4W Black 0.75 m Cable
7.0: CVIV 4W Blue 0.61 m Cable
'''

#my4200.query(":CVU:CABLE:COMP:LOAD 1.5, 50") #Load compensation 
#my4200.query(":CVU:CABLE:COMP:MEASCUSTOM") #Custom cable length compensation
#my4200.query(":CVU:CABLE:COMP:OPEN 1.5") #Open compensation
#my4200.query(":CVU:CABLE:COMP:SHORT 1.5") #Short compensation

my4200.disconnect() # Close communications with the 4200A-SCS