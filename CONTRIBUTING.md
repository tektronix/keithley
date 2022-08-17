# Contributing to the Keithley Instruments Example Repo

Thank you for your interest in contributing to the official example code repo for Keithley Instruments products! This code in this repo is not officially supported and is maintained on a volunteer basis by Keithley engineers. We welcome any input or additions from the community that meet these contributing guidelines. 

First, please consult the Tektronix [Code of Conduct](https://tektronix.github.io/Code-Of-Conduct/) that governs the usage of this repo.

- [Contributing to the Keithley Instruments Example Repo](#contributing-to-the-keithley-instruments-example-repo)
    - [Contributor License Agreement](#contributor-license-agreement)
  - [General Contribution Requirements](#general-contribution-requirements)
    - [Branches and Pull Requests](#branches-and-pull-requests)
    - [READMEs](#readmes)
  - [Application Specific Examples](#application-specific-examples)
    - [Battery Simulation Models](#battery-simulation-models)
  - [Instrument Drivers](#instrument-drivers)
  - [Instrument Examples](#instrument-examples)
  - [TTI Apps](#tti-apps)

### Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License Agreement. You (or your employer) retain the copyright to your contribution; this simply gives us permission to use and redistribute your contributions as part of the project.

You generally only need to submit a CLA once, so if you've already submitted one (even if it was for a different project), you probably don't need to do it again.

## General Contribution Requirements

All examples should be safe for people and instruments. 

Examples that explicitly call for, or result in, unsafe conditions are are not allowed. (For example, a script designed to source current into a fully charged lithium ion battery.) 

Examples that put instruments in a unsafe operating conditions, or deliberately crash instrument firmware/software are not allowed. (For example, a script that calls for 3 or more SMUs to be placed together in series.)

All examples must involve at least one Keithley instrument.

### Branches and Pull Requests

To contribute, Fork this repo and create a new branch that will contain your additions or modification. When your changes are complete, or if you're ready for feedback, submit a pull request against the branch you're wishing to add to or modify. The only permanent branch of this repo is `main`, which represents the most up-to-date examples. Other branches might be made if Keithley engineers are working on larger projects.

If you see something you're not sure is a bug, or if you'd like to request an example, please submit an Issue via GitHub.  

If you'd like help from a Keithley engineer in developing an example, please submit a pull request with what you have so far placed in the proper part of the repository, including any new directories your example may need. 

### READMEs

README.md files are spread throughout this repo to help with readability on GitHub. Because this repo is not a cohesive codebase, but rather a collection of separate pieces of reference material, these READMEs are vital in helping people find the best example for their scenario. These READMEs are meant to describe what content is within different folders, they are not necessarily meant to be documentation. Examples should either start with commented documentation that describes the code's usage, or include separate documentation in a contained folder. 

When editing files, ensure any READMEs that address your edited files reflect your changes. When adding files, add READMEs as prudent. If you're adding several folder directories, or many different files, or a totally new type of example, a README is probably needed. If you're adding or removing files to a folder that already has a README, you should edit that README to reflect your changes. 

Lists in READMEs should have this format:

```
* **[Name of Example](./directory_of_example)** ((Use 2 spaces at the end of this line.))
Description of Example.
```

which appears as:

* **[Name of Example](./directory_of_example/)**  
Description of Example.

## Application Specific Examples

These examples can include one or multiple Keithley instruments, as well as other equipment. They should accomplish a specific application task, not just demonstrate general behavior of an instrument. Examples should include documentation, either in comments or in separate files, with instructions on accomplishing the application.

Examples should be placed in their own folder within the [Application Specific directory](./Application_Specific/). Multiple examples of the same application may be placed in the same folder, but a README should document the differences.

### Battery Simulation Models

Battery models for the [2281S Battery Simulator](https://www.tek.com/tektronix-and-keithley-dc-power-supplies/2281s) are stored in [this folder](./Application_Specific/Battery_Simulation/2281S_Battery_Models/). We welcome new battery models that follow the format created by the [Model Generation Script for the 2400 Series Graphical SMUs](./Application_Specific/Battery_Simulation/Model_Generation_Script/). 

Battery models should be in their own folder named with the format:*Brand\_Type/Model#\_Chemistry/trademark*. It is strongly preferred to include the `*_SetupAndRawData.csv` file with a model, but that is not a requirement. You can have multiple models for the same battery in the same folder, made under different conditions. Each pair of files must have a unique name. The name of a model does not have to meet a specific requirement, other than it must be readable by the 2281S. 

To request a battery model, open an issue on GitHub with the "Code Request" template, but please be aware that Keithley cannot fulfill every request for battery models. The [2281S Reference Manual](https://www.tek.com/en/support/product-support?series=Keithley%20Series%202281S%20Battery%20Simulator&type=manual) includes documentation on creating new battery models. 

## Instrument Drivers

Drivers should properly reflect the capabilities of the instrument. Any language is welcome.

## Instrument Examples

These examples should demonstrate behavior of the instrument. They are ideally to be used as reference for creating your own, application specific code. 

## TTI Apps

TTI Apps should follow the conventions outlined in the [TTI display API](/TTI_Apps/TTI_Display_API/README.md), particularly the section on [creating Apps](/TTI_Apps/TTI_Display_API/README.md#tti-apps).