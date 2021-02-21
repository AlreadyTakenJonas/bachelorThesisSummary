# RHotStuff
This package contains a collection of mostly unrelated utility functions written in the R language. You'll find a summary of all available functionalities below; for more details have a look at the [man pages](./man).

## Installation
To install this package you'll need the `devtools` package. Give following commands your R interpreter:
```
install.package("devtools")
devtools::install_github("AlreadyTakenJonas/RHotStuff", ref="main")
```
and the package is installed. You will need to install the appropriate version of Rtools first.

## Trouble Shooting

### Missing SSL Certificates

If the API server lacks the proper ssl certificates to open a https connection following error will occur:
```
Fehler in curl::curl_fetch_memory(url, handle = handle) : 
  SSL certificate problem: self signed certificate
```
This can be fixed by telling the `httr` package to give a fuck and connect anyway. This can be done by running
```
httr::set_config(httr::config(ssl_verifypeer = 0L))
```
This will make `httr` ignore certificates in all https connections of the R-session. Be careful! This effects all https connections not only those to the eLab server. 

## Available Functions

Function                  | Description
:------------------------:|-------------------------------------------------------------------------------------
better.acos               | The inverse function of cosine. Returns values between 0 and 2pi instead of 0 and pi.
polaram.as.spectrum       | Computes the spectrum of a sample from the simulation output of `polaram simulate`. See the Repo of [PolaRam](https://github.com/AlreadyTakenJonas/PolaRam) for details. The frequencies of the peaks must be given, because PolaRam does not know them.
GET.elabftw.byselector    | Scraps html tables from the online labbook eLabFTW using its API. Tables are selected by css or XPath selectors.
GET.elabftw.bycaption     | Scraps html tables from the online labbook eLabFTW using its API. Tables are selected by caption strings placed in the first cell of the first row of the tables.
parseTable.elabftw        | Combines data frames created by GET.elabftw.byselector and GET.elabftw.bycaption and files attached to a protocol in the online labbook eLabFTW. The file paths written in the data frames will be replaced by a single value derived from the content of the files (e.g. the mean or a sum).
qmean                     | Combines the quantile and the mean function to allow the computation of a mean without considering outliners.
better.subtraction        | Computes the signed distance between two modular numbers.
check.version             | Checks if the running R script is compatible with the used version of this library. This library does change a lot in a short period of time.
check.attachment.elabftw  | Checks the attachment of an entry in the online labbook eLabFTW for missing, misspelled and duplicate files.
getStokes.from.expData    | Preprocessing function for experiments that measure the Stokes vector of lasers before and after travelling trough an optical fiber. This function calculates the first three Stokes parameters for all measurements from GET.elabftw's or parseTable.elabftw's output. The return values of getStokes.from.metaData and getStokes.from.expData have the same format.
getStokes.from.metaData   | Preprocessing function for experiments that measure the Stokes vector of lasers before and after travelling trough an optical fiber. This function calculates the first three Stokes parameters for the meta data of the experiment from GET.elabftw's or parseTable.elabftw's output. The return values of getStokes.from.metaData and getStokes.from.expData have the same format.
better.rbind              | This function takes a list of lists of data.frames as input and row binds the data.frames to create a list of row binded data.frames. Data.frames with the same list index will be row binded. Data.frames with different list indices will be left untouched.
parseTimeSeries.elab      | Combines data frames created by GET.elabftw.byselector and GET.elabftw.bycaption and files attached to a protocol in the online labbook eLabFTW. The attached files supposed to be spectra. The table will be turned into a time series, showing the changing spectra for different measuring conditions.
theme_hot                 | A custom ggplot2 theme. It's pretty hot.
