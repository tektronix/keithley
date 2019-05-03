# 26xx TSP Tutorials

These Folders and files contain TSP code structured as a tutorial on each TSP topic for the 2600 Series of SMUs.  

For the best experience, have your instrument in front of you and communicate to it with [Test Script Builder](https://www.tek.com/software/TestScriptBuilder/KTS-850J02) over any of the supported communication interfaces.  The terminal of Test Script Builder will be very helpful in understanding how the TSP language works.

If you have a non-A, or A version of a 2600 Series, these tutorials will mostly still work as the TSP language has remained largely the same on all 2600 Series SMUs.  That said, these tutorial were tested with a 2602B SourceMeter&reg; so there may be some incompatabilities.  A few examples are written to require a dual channel SMU (2602, 2604, 2606, 2612, 2614, 2634, & 2636), but they can still provide a good understanding on the topics.

> Python's [PyVISA](https://pyvisa.readthedocs.io/en/master/) also supports a terminal-like shell interface.  See their documentation for more information.

## Directory

[comment]: **[Insturment](./directory)**  

* **[Beeper](./beeper.tsp)**  
As good a place to start as any!

* **[Bit](./bit.tsp)**  
Learn about the bit-wise operations, useful if you want to work with the status model or Digital I/O ports.

* **[Delay](./delay.tsp)**  
How to stop the instrument temporarily.

* **[Digital I/O](./DigitalIO)**  
This set of commands are used to control the digital input / output port on your SMU.

* **[Display](./Display)**  
These commands are used to write and read the front panel display.  There's also a handy script for making a scrolling marque.'

* **[Errorqueue](./errorqueue.tsp)**  
The errorqueue is used to store a record of every error the instrument has output. Read this if you need to manage that.

* **[Exit](./exit.tsp)**  
This reviews both the timer object and the exit() command used to end scripts.

* **[Format](./Format)**  
Format commands are advanced commands used to configure how data is processed inside the instrument and returned to a controller.

* **[Functions](./functions.tsp)**  
TSP is a functional language, so learning how to make and control these functions is very important for writing strong and fast code.

* **[If-Then Branching](./if_Then_Branching.tsp)**  
If-Then Branches are the most basic of computer logic, here's how you perform them in TSP.

* **[Local Variables](./local_variables.tsp)**  
Using Local variables is very important in TSP.  These tutorial will show you why and teach you about how to use them properly.

* **[Localnode](./localnode.tsp)**  
`localnode` is how the instrument your talking to refers to itself, so these commands access some high level settings.

* **[Logical Operators](./logical_operators.tsp)**  
Logical operators are things like `and`, `not`, and `or`.  This tutorial will teach you about them in TSP.

* **[Loops](./Loops)**  
Learn about the differen operating loops in TSP, `For`, `while`, and `repeat ... until`.

* **[Makegetter](./makegetter.tsp)**  
Makegetters turn getting TSP attributes into functions.  Read this if you want to speed up your instrument as much as possible.

  * **[Makesetter](./makesetter.tsp)**  
Makesetters turn setting TSP attributes into functions.  Read this if you want to speed up your instrument as much as possible.

* **[Math](./Math)**  
TSP has a built-in library of Math functions, so don't re-write anything you don't have to!

* **[PrintBuffer](./printBuffer.tsp)**  
The printBuffer command is usefull when you just want the data and you want it now.

  * **[PrintNumber](./printNumber.tsp)**  
The printNumber command if your no frills answer to getting a result.  For formatted answers, see [the strings tutorial](./strings.tsp)

* **[Save Setups](./Save_Setups.tsp)**  
Setups allow you to hop from configuration to configuration without resending all the commands, they can also be exported to other instruments.

* **[Strings](./strings.tsp)**  
This tutorial covers the most important parts of string manipulation (as in text strings, not, you know... fabric).

* **[Tables](./Tables)**  
Tables are very important in TSP, this tutorial will teach you just how important.