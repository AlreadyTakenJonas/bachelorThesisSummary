# Bachelor Thesis Jonas Eichhorn 2020/21

This repository combines all data, scripts, the written work and the presentation of my bachelor thesis.

The folders [analysis](analysis), [RHotStuff](RHotStuff) and [PolaRam](PolaRam) are merged into this repository from their own repositories on the 21.Feb.2021: [analysis (scripts for evaluating the data)](https://github.com/AlreadyTakenJonas/bachelorThesis), [PolaRam (program for simulating the polarisation of light)](https://github.com/AlreadyTakenJonas/PolaRam) and [RHotStuff (R-Package used by the evaluationg scripts)](https://github.com/AlreadyTakenJonas/RHotStuff). The scripts in [analysis](analysis) download the data they process from the IPHT's [elabFTW-Server](https://elab.ipht-jena.de/). They expect two variables to be set in R's environment: READ_ELABFTW_TOKEN and ELABFTW_API_URL. These variables contain the API-key and the url of the API used to download the data from elabFTW. See the implementation of the R-package [RHotStuff](RHotStuff) for details.

The folder [defense](defense) containts the power point presentation used to present the thesis to the working group. Including some R scripts to create animations and images included in the presentation.

The folder [sketches](sketches) containts some libre office and R files creating images and figures used in the [thesis](thesis) and/or the [defense](defense).

The folder [thesis](thesis) contains the submitted version of the bachelor thesis with some minor annotations added after submitting the thesis. It also contains the all .tex/.Rtex files and images used to compile the pdf-file. The folder is copied from the [overleaf project](https://www.overleaf.com/project/5fd754e7c9eaca60829b3bb6).

The folder [elabFTW](elabFTW) contains the description of every experiment and the generated data. These information were originally saved to the IPHT's [elabFTW-Server](https://elab.ipht-jena.de/). The folder contains the raw data, the description of the experiments with a list of all attached files as pdf and a .json-file with the original HTML-file containing tables, meta data and descriptions.

