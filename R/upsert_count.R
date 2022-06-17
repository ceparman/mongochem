#' Title
#'
#' @param bit
#' @param count
#' @param db
#'
#' @return
#' @export
#'
#' @examples
upsert_count <- function(bit,count,db){
  db$update(
    jsonlite::toJSON( list( bit = bit),auto_unbox = T) ,
    jsonlite::toJSON(list(`$set` = list(count = count)),auto_unbox = T),
    upsert = TRUE
  )
}



