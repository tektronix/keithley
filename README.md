<picture>
<source media="(prefers-color-scheme: dark)" srcset="https://theme.tekcloud.com/prod/github/keithley-logo-dark-mode.png" width="200px">
  <source media="(prefers-color-scheme: light)" srcset="https://theme.tekcloud.com/prod/github/keithley-logo-light-mode.png" width="200px">
  <img alt="Keithley Logo" src="https://theme.tekcloud.com/prod/github/keithley-logo-light-mode.png" width="200px">
</picture>

![repo linter workflow](https://github.com/tektronix/keithley/actions/workflows/tek-repo-lint.yml/badge.svg)

# Keithley Instruments 

This GitHub repository stores working and in-progress code examples for Keithley Instruments products. The code and content here is not officially supported unless otherwise stated by a Tektronix employee. It is offered for learning and collaboration purposes.

## Directory

* **[Instrument Examples](./Instrument_Examples)**  
Code examples sorted by instrument, including examples taken from the User's Manuals. This is a good place to start off learning about programming for an instrument.

* **[Application Specific Examples](./Application_Specific)**  
Code in any language for any instrument that fulfills a specific application. These are generally more complex solutions.

* **[Instrument Drivers](./Drivers)**  
Code that makes up a partial or complete instrument driver library for any programming language.

* **[KickStart Template Projects](./KickStart_Template_Projects/)**  
Application specific template projects that can be loaded into [Keithley KickStart software](https://www.tek.com/products/keithley/keithley-control-software-bench-instruments/kickstart). 

* **[TTI Apps](./TTI_Apps)**  
TSP™ Apps for Touch, Test, Invent™ instruments (i.e. Keithley's line of touch screen enabled instruments). These are not traditional TSP scripts.

## Downloading Files

If you don't want to clone this entire repository, it's still possible to take individual files. Navigate to the directory holding the file you want and right-click the file to select _Save link as..._ or some variation on that depending on your browser. The file name will automatically populate and you can save the file where you'd like. Alternatively, you can open the file you want on GitHub and right-click "Raw" at the top of the file to accomplish the same thing.

## Relevant Keithley Software

If you're looking for officially supported software, we invite you to visit [tek.com/software](https://www.tek.com/software). Here are some relevant software options for controlling Keithley equipment:
- [Keithley TSP Toolkit](https://github.com/tektronix/tsp-toolkit), An open source [Visual Studio Code](https://code.visualstudio.com/) extension that facilitates communicating with TSP instruments from VS Code, adds command auto-complete and syntax checking, and provides TSP command documentation from within VS Code.
- [KickStart](https://www.tek.com/products/keithley/keithley-control-software-bench-instruments/kickstart), Instrument control and automation software for both Keithley and Tektronix products.
- [Keithley Automated Characterization Suite (ACS)](https://www.tek.com/products/keithley/semiconductor-test-systems/automated-characterization-suite), Advanced characterization and automation software.
- [More Information on TSP](https://www.tek.com/solutions/application/test-automation/tsp-for-test-automation), our instrument control command set and programming language

## Maintainers

Liz Makley: [Little-LIZard](https://github.com/Little-LIZard)  
Brad Odhner: [Brad-O](https://github.com/Brad-O)  

## License

Licensed under the [Tektronix Sample License](https://www.tek.com/sample-license).

## Contributing

Please review the [Contributing Guidelines](/CONTRIBUTING.md).
