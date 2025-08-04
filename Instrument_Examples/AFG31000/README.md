# AFG31000 Examples

These code examples are a good place to start learning how to work with your [AFG31000 Arbitrary Function Generator](https://www.tek.com/en/products/signal-generators/arbitrary-function-generator/afg31000) over a remote interface. 

## Directory

[comment]: **[AFG31000](./directory)**  

* **[Double Pulse 2 Channels](./Double_Pulse_2Ch.py/)**  
Example for 2 channel double pulse on the AFG31k using remote commands. Creates a double pulse waveform, sends it to each channel's edit memory, and outputs it from two channels.

* **[Sending and Saving Arbitrary Waveforms](./Send_and_Save_Arb_Waveform_Example.py/)**  
Creates a sine waveform, sends it to the AFG31000's edit memory 1, and saves the waveform as a .tfwx file to the AFG31k's internal memory.

* **[Transfering Waveforms to the AFG31k](./Transfer_Waveform_File.py/)**  
Transfer an AFG31k waveform file (.tfwx) over a remote communication to an AFG31k (requires AFG31k firmware 1.6.5 or above). Note waveform file to transfer must be in the same directory as this Python script.