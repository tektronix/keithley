
# Creating GUIs

These examples are applicable to a range of instruments, not having the same level of focus as those in the higher-level paths dedicated to specific instrument models. 

## Directory

[comment]: **[General](./directory)**  

* instrgui.py<br>
--- Helps easily create GUIs for PyVISA instrumentation.<br>
--- Provides class InstrumentOption which encapsulates information about a particular GUI option, and function open_gui_return_input which takes in a list of InstrumentOptions, creates a GUI, and returns the user's input when the GUI submit button is pressed.<br>
--- GUI is formatted as a singular column of instrument options, with each option input with each option input presented as either a text box or check box.<br>

