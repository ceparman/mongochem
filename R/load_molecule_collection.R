
#' load_molecule_collection
#'
#' @param document JSON document created with mongochem::create_pubchem_sdf_set
#' @param db_info db connection info
#'
#' @return
#' @export
#'
#' @examples
load_molecule_collection <- function(document,db_info ){



url_path = paste0(db_info$dbscheme ,db_info$creds$user,":",db_info$creds$pass,db_info$dbinstance)


db <- mongolite::mongo(db=db_info$dbname,url = url_path ,collection = "molecules")


#insert into database

insert_results <-  db$insert(document)



#Create indexes if they don't exist


  indexes <- names(db$info()$stats$indexDetails)

  if( !("mfp_bits_1" %in% indexes)){

    db$index(add = '{"mfp_bits" : 1}')

  }


  if( !("mfp_count_1" %in% indexes)){

    db$index(add = '{"mfp_count" : 1}')

  }



# Full Counts collection

db2 <- mongolite::mongo(db_info$dbname,url = url_path, collection = "mfp_counts")

#Insert

update_mfp_counts(db,db2)


#Disconnect

db$disconnect()

db2$disconnect()




}





