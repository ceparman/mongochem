library(mongolite)
library(jsonlite)
library(config)

library(webchem)
library(ChemmineR)
library(ChemmineOB)
library(fingerprint)
library(rcdk)
library(fmcsR)
library(dplyr)
library(foreach)
library(doParallel)



#required files

##IDs

#ID type
#ID

##Structure

#Canonical SMILES
#sdfstr
#2D plot

##Properties
#exact Mass
#Molecular Formula
#Molecular Weight

#mfp_bits
#mfp_count

library(mongochem)

#Atlas creds
#all_creds <- jsonlite::fromJSON(safer::decrypt_string(Sys.getenv("mongo_db_string")))
#creds <-all_creds[["user"]]
#



db_info <- list( dbscheme  = "mongodb://localhost:27017",
                 dbinstance =  NULL,
                 dbname = "chemdb",
                 creds <- NULL)

url_path = paste0(db_info$dbscheme ,db_info$creds$user,":",db_info$creds$pass,db_info$dbinstance)


db <- mongolite::mongo(db="chemdb",url = url_path ,collection = "molecules")

db2 <- mongolite::mongo(db="chemdb",url = url_path ,collection = "mfp_counts")



sdf_file <- "CreateSets/Drug Bank/PubChem_compound_text_drugbank_records.sdf"
sdf_collection <- "DrugBank"


sdfset <-  ChemmineR::read.SDFset(sdf_file ,skipErrors)

sdfset<- sdfset[ 1:100] #Small set for development
sdf_file_small <- "CreateSets/Drug_Bank/small_set.sdf"

write.SDF(sdfset,sdf_file_small)

#Load existing documents

document <- mongochem::create_pubchem_sdf_set(
              sdf_file = "CreateSets/Drug_Bank/small_set.sdf",
              mol_text_file = "CreateSets/Drug_Bank/PubChem_compound_text_drugbank.csv",
              collection = "Drug Bank",
              min_mw = 1, max_mw = 1000, n_cores = 5)

mongochem::load_molecule_collection(document,db_info )



#Load from SDF


load_pubchem_sdf("CreateSets/Drug_Bank/small_set.sdf","CreateSets/Drug_Bank/PubChem_compound_text_drugbank.csv",
                 db_info,"Drug Bank", min_mw = 1, max_mw = 1000, n_cores =5)

