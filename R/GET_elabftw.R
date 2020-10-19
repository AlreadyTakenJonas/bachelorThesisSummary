#' @importFrom magrittr %>%
#' @export
GET.elabftw <- function(experiment.id, 
                        node.id       = "#experimental-data", 
                        dec           = ",",
                        # Sys.getenv() gets the enviourment variable with the API token. Its defined in ~/.Revirons 
                        api.key       = Sys.getenv("READ_ELABFTW_TOKEN"), 
                        url           = "https://repo.ipht-jena.de/elabftw/api/v1/experiments/" ) {
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
