#' Parse Tables With References To Files On eLabFTW
#' 
#' TODO: DESCRIPTION
#' 
#' @export
parseTable.elabftw <- function(parseableTables) {
  # Get tables and meta data
  tables    <- parseableTables$table
  metadata  <- parseableTables$http
  
  # Process every table in the list
  lapply( tables, function(table) {
    
    # Loop over every item of the data frame
    newtable <- lapply( element, function(element) {
      
      
      
    } )
    
  } )
  
}