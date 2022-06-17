

#' Create_pubchem_sdf_set
#'
#' @param sdf_file
#' @param mol_text_file
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
create_pubchem_sdf_set <- function(sdf_file,mol_text_file,collection, min_mw = 1, max_mw = 10000, n_cores =2)
{

#Read sdf
##to do: return list of skipped molecules

sdfset <-  ChemmineR::read.SDFset(sdf_file ,skipErrors)


#Remove large molecules and small (than cause issues with smiles and searching)

mw <- ChemmineR::MW(sdfset)

sdfset <- sdfset[ (  (mw < max_mw) & (mw > min_mw) ) ]

#Get pubchem_ids
pubchem_id <- ChemmineR::sdfid(sdfset)

#Read collection text

collection_text <- readr::read_csv(mol_text_file, show_col_types = FALSE)  %>%
                       filter(cid %in% pubchem_id )

#Get Smiles
smiles <- collection_text$isosmiles

#setup parallel backend to use many processors
cores=parallel::detectCores()
cl <- parallel::makeCluster( min( (cores-2), n_cores) ) #not to overload your computer
doParallel::registerDoParallel(cl)


#Process structure in parallel

documents <-  foreach::foreach(i =1:length(sdfset),.packages=c("rcdk","jsonlite","ChemmineR")) %dopar% {

  textid <- which(collection_text$cid ==  pubchem_id[i] )

  mols <- rcdk::parse.smiles(smiles[textid])
  fp <- rcdk::get.fingerprint(mols[[1]],depth = 2,size = 2048,type = "circular",circular.type = 'ECFP6',verbose = T)
  mfp_bits <- as.character(fp@bits)
  mfp_count <- length(mfp_bits)


#Create full object
##to do: add more objects from text file

document <- jsonlite::toJSON(list(  id =  pubchem_id[i],
                                    id_type = "PubChem",
                            smiles =  smiles[i],
                            mfp_bits = mfp_bits,
                            mfp_count = mfp_count,
                            collection = collection ,
                            sdfstr = ChemmineR::sdf2str(sdfset[[i]])
                        ),auto_unbox = T
                  )

  document

}

#Stop Cluster
parallel::stopCluster(cl)


#Create single JSON object

documents <- unlist(documents)

return(documents)
}
