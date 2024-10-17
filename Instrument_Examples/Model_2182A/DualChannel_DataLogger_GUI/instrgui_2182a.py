"""
Helps easily create GUIs for PyVISA instrumentation.

Provides class InstrumentOption which encapsulates information about a particular GUI option,
and function open_gui_return_input which takes in a list of InstrumentOptions, creates a GUI,
and returns the user's input when the GUI submit button is pressed.

GUI is formatted as a singular column of instrument options, with each option input presented 
as either a text box or check box.

Typical usage example:
    instrument_options = [
            InstrumentOption("High Current", "high_current", "0.001"),
            InstrumentOption("Filter Type", "filter_type"),
            InstrumentOption("Use Low to Earth", "lowToEarth_on", False, True),
            InstrumentOption("Use Input Capacitor", "inputCap_on", False, True),
        ]

    messages = "Message to display in GUI"

    parameters = open_gui_return_input(
        instrument_options, messages, "saved_parameters.txt"
    )


    Copyright 2023 Tektronix, Inc.                      
    See www.tek.com/sample-license for licensing terms. 

"""

import PySimpleGUI as sg


class InstrumentOption:
    """Class that encapsulates information about instrument parameters to present on GUI.

    A list of these can be passed to function open_gui_return_input() in order to automatically
    generate a PySimpleGUI GUI window for getting instrument parameters from a user.

    Attributes:
        option_label: A string indicating the option name displayed in the GUI.
        gui_key: The key (string) used to retrieve the input value from PySimpleGUI.
        default_value: A string (or bool if is_bool is True) indicating the default GUI value.
        is_bool: A boolean indicating if the GUI option should be a text field or boolean checkbox.
    """

    def __init__(
        self,
        label: str,
        gui_key: str,
        default_value="0",
        is_bool: bool = False,
        tooltip: str = "",
        permanent_tooltip=False,
    ) -> None:
        self.label = label
        self.gui_key = gui_key
        self.default_value = default_value
        self.is_bool = is_bool
        self.tooltip = tooltip
        self.permanent_tooltip = permanent_tooltip

    def py_simple_gui_row(self, label_length: int = 30):
        """Returns a list corresponding to a PySimpleGUI row for the instrument option input"""
        sg_option_label = sg.Text(
            text=self.label, size=label_length, justification="right"
        )
        tooltip_with_label = self.label
        if self.tooltip != "":
            tooltip_with_label += ": " + self.tooltip

        if self.permanent_tooltip:
            sg_text_note = sg.Text(
                text=self.tooltip,
                expand_x=True,
                font="Arial 10 italic",
                justification="left",
            )
        else:
            sg_text_note = sg.Text(
                text="",
                expand_x=True,
                font="Arial 10 italic",
                justification="left",
            )
        if self.is_bool:
            return [
                sg_option_label,
                sg.Checkbox(
                    text="",
                    tooltip=tooltip_with_label,
                    expand_x=True,
                    default=self.default_value,
                    key=self.gui_key,
                ),
                sg_text_note,
            ]
        else:
            return [
                sg_option_label,
                sg.Input(
                    tooltip=tooltip_with_label,
                    default_text=self.default_value,
                    size=10,
                    key=self.gui_key,
                ),
                sg_text_note,
            ]


def open_gui_return_input(
    instrument_options, messages: str, saved_parameters_filename: str
):
    """Create GUI window with options specified by instrument_options, return input on user submit.

    Args:
        instrument_options (object): List of InstrumentOption objects to be added to GUI.

        messages (str): String that will be displayed as a note on the GUI window.

        saved_parameters_filename (str): Path name of file where user parameters will be saved
            to and reloaded from.

    Returns:
        (dict): Dictionary containing instrument parameters entered in the GUI, with keys determined
            by the gui_key attributes of the InstrumentOption objects in instrument_options.
    """
    # Open the parameters file or create one
    try:
        with open(saved_parameters_filename, "r", encoding="utf-8") as file:
            saved_params = file.read().splitlines()
    except FileNotFoundError:
        with open(saved_parameters_filename, "x", encoding="utf-8") as file:
            saved_params = []

    # Set GUI parameter default values to previously saved parameters
    if len(saved_params) == len(instrument_options):
        for i, value in enumerate(saved_params):
            if instrument_options[i].is_bool:
                instrument_options[i].default_value = True if value == "True" else False
            else:
                instrument_options[i].default_value = value


    # Get max length of any instrument_option label, used for alignment
    max_label_length = max(len(option.label) for option in instrument_options)

    # Iterate over instrument options and generate row in for each in column 1
    col1 = [
        option.py_simple_gui_row(label_length=max_label_length)
        for option in instrument_options
    ]


    # Create second column containing additional messages/notes
    col2 = [
        [
            sg.Text(
                messages,
                key = '-MESSAGE-', 
                justification="center",
            )
        ]
    ]

    layout = [
        [sg.Column(col1, element_justification="right"),sg.Column(col2)],
        [sg.Button("Run", key = "-RUN-"), sg.Button("Stop" ,key = "-STOP-", disabled = True), sg.Button("Cancel")],
    ]

    return layout




