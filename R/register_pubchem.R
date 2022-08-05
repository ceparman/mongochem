
#' Register a molecule from Pubmed locally
#'
#' @param id
#' @param db_info
#' @param comments
#'
#' @return
#' @export
#'
#' @examples
register_pubchem <- function(id,db_info,comments="") {


#get mol file

#https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/2244/SDF

sdf_url <- paste0("https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/",id,"/SDF")

temp_file <- tempfile()

download.file(url = sdf_url ,destfile = temp_file )

structure <- rcdk::load.molecules(temp_file)

sdk_prop <- map( structure, rcdk::get.properties)

form <- rcdk::get.mol2formula(structure[[1]])

  #Get fingerprint bits and counts


  fp <- rcdk::get.fingerprint(structure[[1]],depth = 2,size = 2048,type = "circular",circular.type = 'ECFP6',verbose = T)

  fpl <- list(fp)

  mfp_bits <- lapply(fpl, function(x) as.character(x@bits))


  mfp_count <- length(mfp_bits)

  mols <- mongochem::mol2sdf(structure[[1]])


  full_record <- data.frame (  `Base ID` = id,
                                 `Id Type` = "PubChem",
                                 `ID` = paste0("PubChem-",id),
                                 link  =  paste0("https://pubchem.ncbi.nlm.nih.gov/compound/",id),
                                 Collection = "PubChem",
                                 `Molecular Weight` = round(as.numeric(sdk_prop[[1]]$PUBCHEM_MOLECULAR_WEIGHT,2)),
                                 `Exact Mass`   =     round(as.numeric(sdk_prop[[1]]$PUBCHEM_EXACT_MASS,3)),
                                 `Formal Charge` =    round(as.numeric(sdk_prop[[1]]$PUBCHEM_TOTAL_CHARGE,3)),
                                  smiles =            sdk_prop[[1]]$PUBCHEM_OPENEYE_CAN_SMILES,
                                  Formula =         sdk_prop[[1]]$PUBCHEM_MOLECULAR_FORMULA ,
                                 `Atom Count`=   paste(form@isotopes[,1], form@isotopes[,2] ,sep=":",collapse = ","),
                                 mfp_count = mfp_count,
                                 mfp_bits =  I(mfp_bits),
                                 mol = mols,
                                 comments = comments,
                                 check.names = F
  )


  url_path = paste0(db_info$dbscheme ,db_info$creds$user,":",db_info$creds$pass,db_info$dbinstance)


  db <- mongolite::mongo(db=db_info$dbname,url = url_path ,collection = "molecules")


  #insert into database

  insert_results <-  db$insert(full_record)



  db2 <- mongolite::mongo(db_info$dbname,url = url_path, collection = "mfp_counts")

  #Insert count table

  mongochem::update_mfp_counts(db,db2)

  db$disconnect()

  db2$disconnect()





}
