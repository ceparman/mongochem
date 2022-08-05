library(mongolite)
library(jsonlite)
library(config)
library(stringr)

library(webchem)
library(ChemmineR)
library(ChemmineOB)
library(fingerprint)
library(rcdk)
library(fmcsR)
library(dplyr)
library(purrr)
library(foreach)
library(doParallel)
library(rJava)

.jinit()

options(java.parameters = "-Xmx15000m")

drugbank_vocabulary <- read.csv("CreateSets/Drug_Bank2/drugbank vocabulary.csv",check.names = F)

system("obabel CreateSets/Drug_Bank2/openstructures.sdf -O CreateSets/Drug_Bank2/cleaned.sdf -r" )

#convertFormatFile(from = "SDF", to ="SDF",
#                  fromFile = "CreateSets/Drug Bank2/open structures.sdf",
#                  toFile = "CreateSets/Drug Bank2/cleaned.sdf",
#                  options=data.frame(args="-r"))

drugbank_structure <- rcdk::load.molecules("CreateSets/Drug_Bank2/cleaned.sdf")



sdk_prop <- map( drugbank_structure, rcdk::get.properties)

drugbank_sdf_ids <- unlist(map(sdk_prop , function(x) x$DRUGBANK_ID))

drugbank_vocabulary <- drugbank_vocabulary  |> filter(`DrugBank ID` %in% drugbank_sdf_ids)


safe_form <- purrr::safely(get.mol2formula)


forms <-  purrr::map(drugbank_structure,safe_form )


#Create strings version of mol file

mols <- lapply(drugbank_structure, mongochem::mol2sdf)

#Get fingerprint bits and counts


fp <- lapply( drugbank_structure,rcdk::get.fingerprint,depth = 2,size = 2048,type = "circular",circular.type = 'ECFP6',verbose = T)

mfp_bits <- lapply(fp, function(x) as.character(x@bits))


mfp_count <- lapply(mfp_bits,length)


calc_sdf_prop <- data.frame (  `Base ID` = drugbank_sdf_ids,
                               `Id Type` = rep("DrugBank",length(drugbank_sdf_ids)),
                              `ID` = paste0("DrugBank-",drugbank_sdf_ids),
                              link  =  paste0("https://go.drugbank.com/drugs/",drugbank_sdf_ids),
                              Collection = rep("Drug Bank",length(drugbank_sdf_ids)),
                              `Molecular Weight` = round(unlist(map(drugbank_structure,get.natural.mass)),2),
                              `Exact Mass` = unlist(map(forms, function(x) { if(is.null(x$result)) {
                                return(NA)} else{
                                  round(x$result@mass,3)}
                              })),
                              `Formal Charge` = unlist(map(forms, function(x) { if(is.null(x$result)) {
                                return(NA)} else{
                                  round(x$result@charge,3)}
                              })),
                              smiles =unlist(map(drugbank_structure, get.smiles, smiles.flavors("Canonical"))),
                              Formula = unlist(map(forms, function(x) { if(is.null(x$result)) {
                                return(NA)} else{
                                  x$result@string}
                                     })),
                              `Atom Count`= unlist(map(forms, function(x){ if(is.null(x$result)) {
                                return(NA)} else{
                                  paste(x$result@isotopes[,1],x$result@isotopes[,2],sep=":",collapse = ",")}
                                   })),
                              mfp_count = unlist(mfp_count),
                               mfp_bits = I(mfp_bits),
                              mol = unlist(mols),

                              check.names = F
                               )








full <- drugbank_vocabulary |>
                             left_join(calc_sdf_prop,by = c("DrugBank ID" = "Base ID")) |>
                             rename(`Base ID` = "DrugBank ID")


saveRDS(full,"CreateSets/Drug_Bank2/full.Rds")


full <- readRDS("CreateSets/Drug_Bank2/full.Rds")

#Remove single atom entries

full_cleaned <- full[which(!is.na(full$Formula)),]


#documents  <- lapply(purrr::transpose(full), function(x) x)

#jdoc <- unlist(lapply(documents,jsonlite::toJSON,auto_unbox=T))

#connect to data base


# all_creds <- jsonlite::fromJSON(safer::decrypt_string(Sys.getenv("mongo_db_string")))
# creds <-all_creds[["user"]]
#
# db_info <- list (
#
#   dbscheme  = 'mongodb+srv://',
#   dbinstance =  '@cluster0.41ox5.mongodb.net',
#   dbname  = 'chemdb',
#   creds = creds
# )



all_creds <- jsonlite::fromJSON(safer::decrypt_string(Sys.getenv("mongo_db_string")))

creds <-all_creds[["user"]]


#Connecto local db

# db_info <- list( dbscheme  = "mongodb://localhost:27017",
#                  dbinstance =  NULL,
#                  dbname  = 'chemdb',
#                  creds <- NULL)
#



db_info <- list (

     dbscheme  = 'mongodb+srv://',
     dbinstance =  '@cluster0.41ox5.mongodb.net',
     dbname  = 'chemdb',
     creds = creds
   )

valdoc <- mongochem::valdoc()

mongochem::db_create(db_info,valdoc )

url_path = paste0(db_info$dbscheme ,db_info$creds$user,":",db_info$creds$pass,db_info$dbinstance)


db <- mongolite::mongo(db=db_info$dbname,url = url_path ,collection = "molecules")


#insert into database

insert_results <-  db$insert(full_cleaned)



# Full Counts collection

db2 <- mongolite::mongo(db_info$dbname,url = url_path, collection = "mfp_counts")

#Insert

mongochem::update_mfp_counts(db,db2)

db$disconnect()

db2$disconnect()


