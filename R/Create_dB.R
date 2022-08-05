
#' @title Create molecule database
#' @description Creates collection for ShinyChem
#' @param dbInfo Database connection and creds informations.
#' @param valDoc validation document
#' @return returns "created LIMS successful" if sucsessful or error message if function fails.
#' @details DETAILS
#' @examples
#' \dontrun{
#' if(interactive()){
#'  all_creds <- jsonlite::fromJSON(safer::decrypt_string(Sys.getenv("mongo_db_string")))
#'  creds <-all_creds[["user"]]
#'
#'   db_info <- list( dbscheme  = "mongodb://localhost:27017",
#'                 dbinstance =  NULL,
#'                 dbname  = 'chemdb',
#'                 creds <- NULL)
#'valdoc <- mongochem::valdoc()
#'mongochem::db_create(dbinfo,valdoc )
#'  }
#' }
#' @rdname db_create
#' @export

db_create <- function(db_info,valdoc)
{

tryCatch({
#local connection



  url_path = paste0(db_info$dbscheme ,db_info$creds$user,":",db_info$creds$pass,db_info$dbinstance)



#create  database connection

db <- mongolite::mongo(db="chemdb",url = url_path )

#Create molecules
tryCatch( {

eval( parse(text = paste0("db$run(",jsonlite::toJSON( paste0('{"drop":"molecules"}')  ,auto_unbox = T),")" )))

}, error=function(cond){}
)


eval( parse(text = paste0("db$run(",jsonlite::toJSON( paste0('{"create":"molecules",',valdoc,'}')  ,auto_unbox = T),")" )))





#create mfp_counts

tryCatch( {

eval( parse(text = paste0("db$run(",toJSON( paste0('{"drop":"mfp_counts"}')  ,auto_unbox = T),")" )))


}, error=function(cond){}
)


eval( parse(text = paste0("db$run(",toJSON( paste0('{"create":"mfp_counts"}')  ,auto_unbox = T),")" )))



#Create indexes

#Connect to molecules

db <- mongolite::mongo(db=db_info$dbname,url = url_path ,collection = "molecules")

#Create indexes if they don't exist



indexes <- names(db$info()$stats$indexDetails)

if( !("mfp_bits_1" %in% indexes)){

  db$index(add = '{"mfp_bits" : 1}')

}


if( !("mfp_count_1" %in% indexes)){

  db$index(add = '{"mfp_count" : 1}')

}

#Create unique index for ID type and ID  - user Barcode will be IDTYPE-ID

db$run( '{"createIndexes":"molecules","indexes":[{"key":{"Id Type":1,"ID":1},"name":"idtype","unique": true}]  }' )


#Create index on mfp_counts

db <- mongolite::mongo(db=db_info$dbname,url = url_path ,collection = "mfp_counts")

db$index(add = '{"bit":1}')



}, error=function(cond){return("Error Creating database")}

)

db$disconnect()

}
