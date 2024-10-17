import instrgui_2182a as gui
from instrcomms import Communications
import time
import matplotlib.pyplot as plt
import datetime as dt

running = False
reading = [0, 0]
parameters = {}
channel_options = []
channel_readings = [[],[]]
active_channel = 0
timestamps = [[],[]]
run = 0

inst2182A = Communications("ASRL6::INSTR")
inst2182A.connect()
inst2182A.write("*RST")
inst2182A.write("*CLS")
#inst2182A.write("TRAC:CLE")
#inst2182A.write("FROM:ELEM READ")
#inst2182A.write("TRAC:POIN 1024")


instrument_options = [
            

            gui.InstrumentOption("Multiplier", "multip", "1"),
            gui.InstrumentOption("Measurement Interval", "meas_int", '0'),
            gui.InstrumentOption("NPLC", "nplc", "5"),

            gui.InstrumentOption("Channel 1", "channel1", "", True),
            gui.InstrumentOption("Filter Count", "filter_count1", "10"),
            gui.InstrumentOption("Measurement Range", "meas_range1", "1"),

            gui.InstrumentOption("Reading CH-1", "chan1_read", "inactive"),
            
            gui.InstrumentOption("Channel 2", "channel2", "", True),
            gui.InstrumentOption("Filter Count", "filter_count2", "10"),
            gui.InstrumentOption("Measurement Range", "meas_range2", "1"),

            gui.InstrumentOption("Reading CH-2", "chan2_read", "inactive"),
]

messages = "Choose Settings"

layout = gui.open_gui_return_input(
    instrument_options, messages, "saved_parameters.txt"
    )

def run_inst(window):
    global reading    
    global channel_options
    global timestamps
    global channel_readings
    global active_channel

    #--------------------------------
    #INSTRUMENT SET UP
    #--------------------------------

    #Based on channel selection, creates a list of eligible channels 
    if parameters["channel1"] == True and parameters["channel2"] == True:
        channel_options = [1,2]
    elif parameters["channel1"] == True and parameters["channel2"] != True:
        channel_options = [1]
    elif parameters["channel1"] != True and parameters["channel2"] == True:
        channel_options = [2]
    else:
        channel_options = []

    #Non-channel-specific settings
    inst2182A.write(":SENS:FUNC 'VOLT:DC'")
    inst2182A.write(":SENS:VOLT:NPLC {0}".format(parameters["nplc"]))
    
    inst2182A.write(":SYST:AZER:STAT OFF")
    inst2182A.write(":CALC:FORM MXB")
    inst2182A.write(":CALC:KMAT:MMF {0}".format(parameters["multip"]))
    inst2182A.write(":TRAC:FEED CALC")

    inst2182A.write(":TRAC:FEED:CONT NEXT") 

    #Channel specific settings
    for chan in channel_options:
        inst2182A.write(":SENS:VOLT:CHAN{0}:LPAS:STAT OFF".format(chan))

        inst2182A.write(":SENS:VOLT:CHAN{0}:DFIL:STAT ON".format(chan))
        inst2182A.write(":SENS:VOLT:CHAN{0}:DFIL:COUN {0}".format(chan, parameters["filter_count{}".format(chan)]))

        inst2182A.write(":SENS:VOLT:CHAN{0}:RANG {0}".format(chan,parameters["meas_range{}".format(chan)]))

    inst2182A.write(f":SENS:CHAN {channel_options[0]}")

    #user defined measurement interval
    interval = float(parameters["meas_int"])

    start = time.time()

    #takes continuous readings to display on GUI and store into channel_readings matrix
    while True:
        
        if running:
            
            for chan in channel_options:

                reading = inst2182A.query("READ?")          #LINE OF CODE TO CALL READING TO STORE

                #reading[chan-1] += 1                                #COMMENT OUT FOR SIMULATION MODE -> OFF
                channel_readings[chan-1].append(reading)     
                timestamps[chan-1].append(time.time()-start)

                active_channel = chan
                #writes evetn to main thread to update GUI with reading
                window.write_event_value(('-THREAD-', 'IS ON'), 'IS ON')

                if len(channel_options) > 1: 
                    inst2182A.write(":SENS:CHAN {}".format((chan % 2 ) + 1)) #switches sensing channel for "dual" channel function
                    inst2182A.write("*WAI")

        else:
            
            #inst2182A.write("TRAC:FEED:CONT NEV")
            reading = 0

            #writes event to main thread to update reading as inactive
            window.write_event_value(('-THREAD-', 'IS OFF'), 'IS OFF')

            #inst2182A.write("TRAC:CLE")
            #inst2182A.write("*RST")
            channel_readings = [[],[]]
            timestamps = [[],[]]

            break
        time.sleep(interval)

def plot_function(readings, times):
    global run
    
    run += 1
    #if channel_options has both channels enabled, subplot function needed
    if len(channel_options) > 1:
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 6))

        # Plot the first function in the first subplot
        ax1.scatter(times[0], readings[0], label='Channel 1')
        ax1.set_title('Channel 1')
        ax1.set_xlabel('Time')
        ax1.set_ylabel('Voltage')
        ax1.legend()

        # Plot the second function in the second subplot
        ax2.scatter(times[1], channel_readings[1], label='Channel 2')
        ax2.set_title('Channel 2')
        ax2.set_xlabel('Time')
        ax2.set_ylabel('Voltage')
        ax2.legend()

        fig.suptitle("Dual Channel Measurements")
        plt.show()

    #if single channel enabled, plot as normal
    else:
        # Create a plot
        plt.scatter(times[channel_options[0]-1], readings[channel_options[0]-1])

        # Add a title and labels
        plt.title('')
        plt.xlabel('X-axis Label')
        plt.ylabel('Y-axis Label')

        # Show the plot
        plt.show()

    date = dt.date.today()
    run_time = dt.datetime.now().time().strftime("%H.%M.%S")

    with open(f"Data_Run {run}_{date}_{run_time}.csv", "a+", encoding="utf-8") as csv_file:
        
        for chan in channel_options:
            csv_file.write(f"Channel {chan},,,")
        csv_file.write("\n")

        for chan in channel_options:
            csv_file.write("Voltage Reading, Timestamp,,")
        csv_file.write("\n")
        
        for i in range(0, len(readings[chan-1])):
            for chan in channel_options:
               csv_file.write( f"{readings[chan-1][i]}, {times[chan-1][i]},,")
            csv_file.write("\n")

        csv_file.flush()
        csv_file.close()

            

def main():
    # Create the GUI window
    global running
    global parameters

    #open window
    window = gui.sg.Window(
        "Instrument Parameter GUI", layout, element_justification="center"
    )

    while True:
        #monitor events
        event, parameters = window.read()  

        #close window conditions
        if event == gui.sg.WIN_CLOSED or event == 'Cancel':
            break
        
        #After RUN, intrument is set up and makes readings according to user settings
        if event == '-RUN-':
            window['-RUN-'].update(disabled = True)
            window['-STOP-'].update(disabled = False)         
            window['-MESSAGE-'].update('running')
            running = True
            #start thread to perform set up and readings
            window.start_thread(lambda: run_inst(window), ('-THREAD-', '-THEAD ENDED-'))
            
        elif event[0] == '-THREAD-':
            #while thread is running, use new reading to update window
            if event [1] == 'IS ON':
                    window['chan{}_read'.format(active_channel)].update(reading)
            #when thread ends, update readings as inactive
            elif event [1] == 'IS OFF':
                for chan in channel_options:
                    window['chan{}_read'.format(chan)].update("inactive")
                    
        #after STOP, plot respective readings and timestamps using matplotlib
        elif event == '-STOP-':
            window['-RUN-'].update(disabled = False)
            window['-STOP-'].update(disabled = True)
            window['-MESSAGE-'].update('idle')
            running = False
            plot_function(channel_readings, timestamps)


        

    window.close()

main()

inst2182A.disconnect()