#' Load Smiles to Local Database
#'
#' @param db_info
#' @param smiles
#' @param id
#' @param id_type
#' @param collection
#'
#' @import dplyr
#' @import magrittr
#' @import foreach
#'
#' @return
#' @export
#'
#' @examples
#
#'



load_smiles <- function(smiles,db_info,id,id_type,collection)
{


    mols <- rcdk::parse.smiles(smiles)
    fp <- rcdk::get.fingerprint(mols[[1]],depth = 2,size = 2048,type = "circular",circular.type = 'ECFP6',verbose = T)
    mfp_bits <- as.character(fp@bits)
    mfp_count <- length(mfp_bits)


    #Create full object
    ##to do: add more objects from text file

    document <- jsonlite::toJSON(list(  id =  id,
                                        id_type = id_type,
                                        smiles =  smiles,
                                        mfp_bits = mfp_bits,
                                        mfp_count = mfp_count,
                                        collection = collection ,
                                        sdfstr = ChemmineR::sdf2str(ChemmineR::smiles2sdf(smiles)[[1]])
                                    ),
                              auto_unbox = T)




  #db connection

  url_path = paste0(db_info$dbscheme ,db_info$creds$user,":",db_info$creds$pass,db_info$dbinstance,"/database")

  db <- mongolite::mongo(db=db_info$dbname,url = url_path ,collection = "molecules")


  #insert into database
  insert_results <-  db$insert(document)


  ## Molecule loaded



  #Counts collection


 #Get new counts

counts <- db$aggregate( '[{"$unwind":"$mfp_bits"},
                        {"$group":{"_id":"$mfp_bits",
                                   "count":{"$sum":1}
                                  }
                        },
                        {"$group":{"_id":null,
                                   "mfp_bits_details":{"$push":{"bit":"$_id","count":"$count"}}}},
                        {"$project":{"_id":0,"mfp_bits_details":1}}

                        ]'  )


#Select changed counts

mfp_counts <- counts$mfp_bits_details[[1]] %>% filter( bit %in% mfp_bits ) %>%
              mutate(count = count + 1)



db2 <- mongolite::mongo(db_info$dbname,url = url_path, collection = "mfp_counts")

#update counts

for(i in 1 :length(mfp_counts)){

     upsert_count(mfp_counts[i,1],mfp_counts[i,2],db2)
 }




#Close connections
  db$disconnect()
  db2$disconnect()


}
