#' Check The Attached Files Of A Entry On eLabFTW
#' 
#' This function downloads all tables of a labbook entry in the online labbook eLabFTW together with a list of all files that are attached to the entry.
#' The list of file names will be compared to all table entries. All file names that are not mentioned in the tables will be returned. All file names
#' that are mentioned in the tables but not attached will be returned. All file names of files that are attached multiple times will be returned. eLabFTW
#' allows the user to attach different files with the exact same file name for some fucking reason. The purpose of this function is spell checking the 
#' file names and finding missing attachments to ensure a smooth processing of the tables.
#' 
#' @param expID The unique id of the eLabFTW entry. The id can be found in the url of the labbook entry.
#' @param extension The file extension the function recognises. Only strings and factors ending in one of the given extensions will be counted as missing
#' file, if they do not match any of the attached file names.
#' @return A list containing three vectors: A vector of all file names that are attached to the labbook entry but never mentioned in any of the tables,
#' a vector of file names that are mentioned in the tables of the labbook entry, but are not attached to the labbook entry, and a vector of all file names
#' that are attached multiple times.
#'
#' @importFrom magrittr %>%
#' @export

check.attachment.elabftw <- function(expID, extension = c(".csv", ".txt")) {
  # Download all tables of the experiment from elabFTW including the list of attached files
  tables <- GET.elabftw.byselector(expID, header=F, node.selector="table", outputHTTP=T)
  
  # Format expected file extensions according to regex and collapse all given extensions into a single regex expression
  file.extension <- gsub("\\.", "\\\\.", extension) %>% paste0(., "$") %>% paste0(., collapse="|")
  
  # Extract the vector of all elements of every table in the protocol
  table.elements <- tables$table %>% unlist %>% unname %>% unique
  # Save all elements of the tables that have one of the expected file extensions in a new variable
  # This creates a vector of files that are expected to be attached to the labbook entry
  expected.files <- table.elements[grepl(file.extension, table.elements)] %>% unique
  # Extract the vector with the name of all files that are attached to the protocol
  # !!! DO NOT USE unique() ON THIS VARIABLE !!!
  # This vector will be checked for duplicates!
  attachment    <- tables$http$uploads %>% sapply(., function(file) { return(file$real_name) })
  
  # Compare the list of attached files to all files that are mentioned in the tables of the labbook
  # Save the list of all file names that don't occur in any table into variable
  unmentioned.files <- attachment[!(attachment %in% table.elements)] %>% unique
  # Compare the list of files that are expected to be attached to the protocol to the list of all attached files
  # Save the list of all file names that don't occur in the attachment into a variable
  missing.files <- expected.files[!(expected.files %in% attachment)]
  # Check the vector of attached files for duplicates
  # eLabFTW allows the user to upload multiple files with the exact file names
  # !!! DO NOT USE unique() ON THIS VARIABLE !!!
  # This variable contains an element multiple times if the same file is attached more than two times!
  duplicate.files <- attachment[duplicated(attachment)]
  
  # Inform user how many attached files are mentioned in the tables of the labbook
  paste0("Number of attached but unmentioned files : ", length(unmentioned.files), "\n") %>% cat
  # Inform user how many files are mentioned in the tables of the labbook but not attached to it
  paste0("Number of mentioned but unattached files : ", length(missing.files), "\n") %>% cat
  # Inform user how many files are attached multiple times
  paste0("Number of duplicate files                : ", length(duplicate.files), "\n") %>% cat
  paste0("Number of attached files                 : ", length(attachment), "\n") %>% cat
  
  # Return the names of all unmentioned and missing files
  list("unmentioned" = unmentioned.files, "missing" = missing.files, "duplicate" = duplicate.files) %>% return
}
