

#' Title
#'
#' @param sdf_file
#' @param mol_text_file
#' @param db_info
#' @param collection
#' @param min_mw
#' @param max_mw
#' @param n_cores
#' @import dplyr
#' @import magrittr
#' @import foreach
#'
#' @return
#' @export
#'
#' @examples
load_pubchem_sdf <- function(sdf_file,mol_text_file,db_info,collection, min_mw = 1, max_mw = 1000, n_cores =2)
{

# #Read sdf
# ##to do: return list of skipped molecules
#
# sdfset <-  ChemmineR::read.SDFset(sdf_file ,skipErrors)
#
#
# #Remove large molecules and small (than cause issues with smiles and searching)
#
# mw <- ChemmineR::MW(sdfset)
#
# sdfset <- sdfset[ (  (mw < max_mw) & (mw > min_mw) ) ]
#
# #Get pubchem_ids
# pubchem_id <- ChemmineR::sdfid(sdfset)
#
# #Read collection text
#
# collection_text <- readr::read_csv(mol_text_file, show_col_types = FALSE)  %>%
#                        filter(cid %in% pubchem_id )
#
# #Get Smiles
# smiles <- collection_text$isosmiles
#
# #setup parallel backend to use many processors
# cores=parallel::detectCores()
# cl <- parallel::makeCluster( min( (cores-2), n_cores) ) #not to overload your computer
# doParallel::registerDoParallel(cl)
#
#
# #Process structure in parallel
#
# documents <-  foreach::foreach(i =1:length(sdfset),.packages=c("rcdk","jsonlite","ChemmineR")) %dopar% {
#
#   textid <- which(collection_text$cid ==  pubchem_id[i] )
#
#   mols <- rcdk::parse.smiles(smiles[textid])
#   fp <- rcdk::get.fingerprint(mols[[1]],depth = 2,size = 2048,type = "circular",circular.type = 'ECFP6',verbose = T)
#   mfp_bits <- as.character(fp@bits)
#   mfp_count <- length(mfp_bits)
#
#
# #Create full object
# ##to do: add more objects from text file
#
# document <- jsonlite::toJSON(list(  id =  pubchem_id[i],
#                                     id_type = "PubChem",
#                             smiles =  smiles[i],
#                             mfp_bits = mfp_bits,
#                             mfp_count = mfp_count,
#                             collection = collection ,
#                             sdfstr = ChemmineR::sdf2str(sdfset[[i]])
#                         ),auto_unbox = T
#                   )
#
#   document
#
# }
#

#Create single JSON object

documents <-  mongochem::create_pubchem_sdf_set( sdf_file = sdf_file, mol_text_file = mol_text_file,
                                                collection = collection,
                                                min_mw = min_mw, max_mw = max_mw,
                                                n_cores = n_cores)

#db connection

url_path = paste0(db_info$dbscheme ,db_info$creds$user,":",db_info$creds$pass,db_info$dbinstance)


db <- mongolite::mongo(db=db_info$dbname,url = url_path ,collection = "molecules")


#insert into database
insert_results <-  db$insert(documents)



#Create indexes if they don't exist


indexes <- names(db$info()$stats$indexDetails)

if( !("mfp_bits_1" %in% indexes)){

  db$index(add = '{"mfp_bits" : 1}')

}


if( !("mfp_count_1" %in% indexes)){

  db$index(add = '{"mfp_count" : 1}')

}

#disconnect



## Molecules loaded


#Counts collection

db2 <- mongolite::mongo(db_info$dbname,url = url_path, collection = "mfp_counts")


update_mfp_counts(db,db2)

# counts <- db$aggregate( '[{"$unwind":"$mfp_bits"},
#                         {"$group":{"_id":"$mfp_bits",
#                                    "count":{"$sum":1}
#                                   }
#                         },
#                         {"$group":{"_id":null,
#                                    "mfp_bits_details":{"$push":{"bit":"$_id","count":"$count"}}}},
#                         {"$project":{"_id":0,"mfp_bits_details":1}}
#
#                         ]'  )
#
#
#
# mfp_counts <- counts$mfp_bits_details[[1]]
#
#
#
#
# db2$remove('{}')
#
# db2$insert(mfp_counts)
#
# #add index if needed
#
# indexes <- names(db2$info()$stats$indexDetails)
#
# if( !("bit_1" %in% indexes)){
#
#   db2$index(add = '{"bit" : 1}')
#
# }


db$disconnect()
db2$disconnect()




}


