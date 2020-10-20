#' Request Experimental Data From eLabFTW Via API
#' 
#' This function fetches experimental data from the online labbook eLabFTW as a data frame. The html table that will be returned
#' as data frame musst be marked with a html property, like an id or a class. The table will be selected with the help of this
#' unique id, class or similar.
#' 
#' @param experiment.id The eLabFTW id of the experiment that will be fetched. The id can be found in the url of the experiment.
#' @param node.id A css selector that uniquely identifies the html table that should be read.
#' @param dec The decimal separator used in the table. The default is the German number notation with a comma instead of a period!
#' @param api.key The eLabFT API-key. See the eLabFTW documentation for details. The default settings retrieve this value from
#' the enviourmental variable READ_ELABFTW_TOKEN. This variable can be set in the ~/.Renviron file.
#' @param url The url to the eLabFTW API. See the eLabFTW documentation for details. The default settings retrieve this value from
#' the enviourmental variable ELABFTW_API_URL. This variable can be set in the ~/.Renviron file.
#' @return A dataframe with the content of the selected html table from the eLabFTW online labbook.
#' 
#' @importFrom magrittr %>%
#' @export
GET.elabftw <- function(experiment.id, 
                        node.id       = "#experimental-data", 
                        dec           = ",",
                        # Sys.getenv() gets the enviourment variable with the API token. It's defined in ~/.Revirons 
                        api.key       = Sys.getenv("READ_ELABFTW_TOKEN"),
                        # Sys.getenv() gets the enviourment variable with the URL. It's defined in ~/.Revirons 
                        url           = Sys.getenv("ELABFTW_API_URL") ) {
  # api url
  url <- paste0(url, experiment.id)
  
  # Get HTML from url
  page <- httr::GET(url, httr::add_headers(Authorization = api.key)) %>% httr::stop_for_status(.) %>% httr::content(.) %>% .$body
  
  # Read HTML and extract desired table
  table<- xml2::read_html(page) %>% rvest::html_nodes(node.id) %>% rvest::html_table(header = T, dec = dec) %>% .[[1]]
  # Set simple but less descriptive column names
  colnames(table) <- c( "X", paste0( "Y", seq(from=1, by=1, length.out=length(table[1,])-1) ) )
  
  # Return table
  table
}
