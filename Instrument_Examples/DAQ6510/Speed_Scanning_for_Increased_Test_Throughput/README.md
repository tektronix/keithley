
# Speed Scanning for Increased Test Throughput

There are three different multiplex modules available for use with the DAQ6510. This application
example demonstrates how each of the multiplexer modules can impact productivity by changing test
time. The multiplexer modules all share the same basic code base for switching, scanning, and
measuring. Any limits on system speed are the result of the relays in the multiplexer that switch the
signals from the device under test (DUT) into the instrument.

The Model 7700 20-Channel Differential Multiplexer Module uses electromechanical relays which
have low contact resistance and contribute only a minor offset potential (<1 Ω through the end of life
and < 500 nV, respectively). This results in the most accurate readings of the modules but with a 3
ms relay closure time, the slowest scan time in comparison to other options.

The 7703 multiplexer module uses reed relays which have low contact resistance (<1 Ω through the
end of life), but a higher contact potential (6 μV max) which contributes more signal offset and slightly
less precise readings. The benefit of this module is shorter relay close time (less than 1 ms) which
makes it approximately three times faster than the 7700.

The 7710 multiplexer module uses solid-state relays which have the highest contact resistance and
contact potential of the three options (<5 Ω and <1 μV, respectively) and are therefore the least
precise, however the 7710 has the overall speed advantage with a relay close time of less than 0.5
ms, making it twice as fast as the 7703 and at least six times faster than the 7700.

You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
