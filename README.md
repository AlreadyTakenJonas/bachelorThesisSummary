# RHotStuff
This package contains a collection of mostly unrelated utility functions written in the R language.

## Installation
To install this package you'll need the `devtools` package. Give following commands your R interpreter:
```
install.package('devtools')
devtools::install_github("AlreadyTakenJonas/RHotStuff")
```
an the package is installed.

## Available Functions

+ better.acos() : The inverse function of cosine. Returns values between 0 and 2pi instead of 0 and pi.
+ polaram.as.spectrum() : Computes the spectrum of a sample from the simulation output of `polaram simulate`. See the Repo of [PolaRam](https://github.com/AlreadyTakenJonas/PolaRam) for details. The frequencies of the peaks must be given, because PolaRam does not know them.
+ GET.elabftw.byselector() : Scraps html tables from the online labbook eLabFTW using its API. Tables are selected by css or XPath selectors.
+ GET.elabftw.bycaption() : Scraps html tables from the online labbook eLabFTW using its API. Tables are selected by caption strings placed in the first cell of the first row of the tables.
