#' Bind Lists Of Data Frames By Row
#' 
#' This function takes a list of lists of data frames as argument. The function row binds the first tables of every sublist, the second tables of every
#' sublist, the third tables of every sublist and so on together. The result is a single list of tables. It is also possible to sort the tables by any
#' row after row binding them.
#' 
#' @param listlist.tables The list of list of tables that will be row binded into a single list of tables.
#' @param sort.byrow The index of the row that will be used to sort the whole table by. If NULL the tables won't be sorted.
#' @param ... Parameters that will be passed on to the order function. order is used for sorting the tables.
#' @return A list of the row binded data frames. 
#'
#' @importFrom magrittr %>%
#' @export
better.rbind <- function(listlist.tables, sort.byrow=NULL, ...) {
  # Check if all table lists are the same length before row binding the tables between the table lists
  if ( sapply(listlist.tables, length) %>% unique %>% length > 1 ) stop("The list of list of tables contains list of tables with different lengths. Every list of tables must be the same length!")
  
  # Loop over all tables in the sublists of tables by their index
  list.tables.binded <- lapply( seq_along(listlist.tables[[1]]), function(index) {
    # Row bind the tables from different sublists with the same index by writing them into a list and row bind the list
    lapply(listlist.tables, function(sublist.tables) { sublist.tables[[index]] }) %>% dplyr::bind_rows(.) %>% return
  })
  
  # Sort the tables by a specific row if the row is specified
  if (!is.null(sort.byrow)) list.tables.binded <- lapply(list.tables.binded, function(table) table[ order(table[,sort.byrow], ...), ])
  
  # Return row binded list of tables
  return(list.tables.binded)
}