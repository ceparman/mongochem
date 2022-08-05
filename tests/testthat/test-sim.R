


smiles <- "CC(=O)OC1=CC=CC=C1C(=O)O"


  all_creds <- jsonlite::fromJSON(safer::decrypt_string(Sys.getenv("mongo_db_string")))
  creds <-all_creds[["user"]]


  db_info <- list (

    dbscheme  = 'mongodb+srv://',
    dbinstance =  '@cluster0.41ox5.mongodb.net',
    dbname  = 'chemdb',
    creds = creds
  )


  url_path = paste0(db_info$dbscheme ,db_info$creds$user,":",db_info$creds$pass,db_info$dbinstance ,"/database")

  ss_db <- mongolite::mongo(db="chemdb",url = url_path ,collection = "molecules")

  mongochem::smiles_substructure_search(ss_db,smiles,max_mismatches = 2,threshold = .8,al = 0,au = 2,bl = 0,bu = 2,
                                        min_overlap_coefficient =.7)
