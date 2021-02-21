#' Request Experimental Data From eLabFTW Via API
#' 
#' This function fetches experimental data from the online labbook eLabFTW as a data frame. The html table that will be returned
#' as data frame must be marked with a html property, like an id or a class. The table will be selected with the help of this
#' css selector.
#' 
#' Keep in mind: Tables that have a caption required by GET.elabftw.bycaption() can't be parsed by this function.
#' 
#' @param experiment.id The eLabFTW id of the experiment that will be fetched. The id can be found in the url of the experiment.
#' @param node.selector A css selector that uniquely identifies the html table that should be read. This argument will be passed
#' to rvest::html_nodes() unaltered. Therefore it is also possible to use an XPath selector.
#' @param dec The decimal separator used in the table. The default is the German number notation with a comma instead of a period!
#' @param header Is the first line of the table the column names or data? If true, the first row is no data.
#' @param api.key The eLabFT API-key. See the eLabFTW documentation for details. The default settings retrieve this value from
#' the enviourmental variable READ_ELABFTW_TOKEN. This variable can be set in the ~/.Renviron file.
#' @param url The url to the eLabFTW API. See the eLabFTW documentation for details. The default settings retrieve this value from
#' the enviourmental variable ELABFTW_API_URL. This variable can be set in the ~/.Renviron file.
#' @param outputHTTP Boolean value. If FALSE only the selected tables  will be returned. If TRUE the selected tables and the original http response received from the API will
#' be returned. The http response contains meta information needed by other parsing functions.
#' @return A list of data frames with the content of the selected html tables from the eLabFTW online labbook. If outputHTTP is 
#' set TRUE the return value is a list containing the list of all dataframes created from the selected html tables and the
#' original http response received from the API.
#' 
#' @importFrom magrittr %>%
#' @export
GET.elabftw.byselector <- function(experiment.id, 
                             node.selector    = "#experimental-data", 
                             dec              = ",",
                             # Default is FALSE for safety reasons. Data might get lost if the default is set TRUE and user doesn't notice
                             header           = F,
                             # Sys.getenv() gets the enviourment variable with the API token. It's defined in ~/.Reviron 
                             api.key          = Sys.getenv("READ_ELABFTW_TOKEN"),
                             # Sys.getenv() gets the enviourment variable with the URL. It's defined in ~/.Reviron 
                             url              = Sys.getenv("ELABFTW_API_URL"),
                             # Default is FALSE for backwards compatibility
                             outputHTTP       = F ) {
  # api url
  url <- paste0(url, "experiments/", experiment.id)
  
  # Get HTML from url
  httpResponse <- httr::GET(url, httr::add_headers(Authorization = api.key)) %>% httr::stop_for_status(.) %>% httr::content(.) 
  page <- httpResponse$body
  
  # Read HTML and extract desired table
  table <- xml2::read_html(page) %>% rvest::html_nodes(node.selector) %>% rvest::html_table(header = header, dec = dec) 
  # Set simple but less descriptive column names
  for (i in seq_along(table)) {
    colnames(table[[i]]) <- c( "X", paste0( "Y", seq(from=1, by=1, length.out=length(table[[i]][1,])-1) ) )
  }
  
  # Return table
  if (outputHTTP == FALSE) return(table)
  # Return table and http response
  else return( list(table = table, http = httpResponse) )
}

#' Request Experimental Data From eLabFTW Via API
#' 
#' This function fetches experimental data from the online labbook eLabFTW as a data frame. The html table that will be returned
#' as data frame must be marked with a caption. The first cell of the first row of the table will be interpreted as the caption.
#' The caption is removed from the final data frame. 
#' 
#' Keep in mind: Tables that have a caption can't be parsed by GET.elabftw.byselector().
#' 
#' @param experiment.id The eLabFTW id of the experiment that will be fetched. The id can be found in the url of the experiment.
#' @param caption A string identifying the table. The caption must be placed in the first cell of the first row of the table.
#' @param dec The decimal separator used in the table. The default is the German number notation with a comma instead of a period!
#' @param header Is the first line of the table the column names or data? If true, the first row is no data.
#' @param api.key The eLabFT API-key. See the eLabFTW documentation for details. The default settings retrieve this value from
#' the enviourmental variable READ_ELABFTW_TOKEN. This variable can be set in the ~/.Renviron file.
#' @param url The url to the eLabFTW API. See the eLabFTW documentation for details. The default settings retrieve this value from
#' the enviourmental variable ELABFTW_API_URL. This variable can be set in the ~/.Renviron file.
#' @param outputHTTP Boolean value. If FALSE only the selected tables  will be returned. If TRUE the selected tables and the original http response received from the API will
#' be returned. The http response contains meta information needed by other parsing functions.
#' @return A list of data frames with the content of the selected html tables from the eLabFTW online labbook. If outputHTTP is 
#' set TRUE the return value is a list containing the list of all data frames created from the selected html tables and the
#' original http response received from the API.
#' 
#' @importFrom magrittr %>%
#' @export
GET.elabftw.bycaption <- function(experiment.id,
                                  caption = "Messdaten",
                                  dec = ",",
                                  header = F,
                                  # Sys.getenv() gets the enviourment variable with the API token. It's defined in ~/.Revirons 
                                  api.key       = Sys.getenv("READ_ELABFTW_TOKEN"),
                                  # Sys.getenv() gets the enviourment variable with the URL. It's defined in ~/.Revirons 
                                  url           = Sys.getenv("ELABFTW_API_URL"),
                                  # Default is FALSE for backwards compatibility
                                  outputHTTP       = F ) {
  # api url
  url <- paste0(url, "experiments/", experiment.id)
  
  # Get HTML from url
  httpResponse <- httr::GET(url, httr::add_headers(Authorization = api.key)) %>% httr::stop_for_status(.) %>% httr::content(.) 
  page <- httpResponse$body
  
  # Extract all table captions
  captionlist <- xml2::read_html(page) %>% rvest::html_nodes("table") %>% rvest::html_node("td")
  # Make a boolean vector, to select the matching tables from a list
  tableselector <- as.character(captionlist) %>% grepl(caption, .)
  
  # Extract all tables that match the caption and convert them into a dataframe
  table <- xml2::read_html(page) %>% rvest::html_nodes("table") %>% .[tableselector]
  # Remove the caption from the tables
  xml2::xml_remove(table %>% rvest::html_node("tr"))
  
  # Convert xml into data frame
  table <- rvest::html_table(table, header = header, dec = dec)
  
  # Set simple but less descriptive column names
  for (i in seq_along(table)) {
    colnames(table[[i]]) <- c( "X", paste0( "Y", seq(from=1, by=1, length.out=length(table[[i]][1,])-1) ) )
  }
  
  # Return table
  if (outputHTTP == FALSE) return(table)
  # Return table and http response
  else return( list(table = table, http = httpResponse) )
}

