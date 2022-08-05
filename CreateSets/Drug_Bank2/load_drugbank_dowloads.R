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
library(foreach)
library(doParallel)



drugbank_vocabulary <- read.csv("CreateSets/Drug Bank 2/drugbank vocabulary.csv",check.names = F)

drugbank_structure <- read.SDFset("CreateSets/Drug Bank 2/open structures.sdf")

valid<- ChemmineR::validSDF(drugbank_structure)

drugbank_structure <- drugbank_structure[valid]

drugbank_structure_invalid <- drugbank_structure[!valid]

drugbank_sdf_ids <- unlist(lapply(datablock(drugbank_structure), function(x)  x[[1]] ) )

names(drugbank_sdf_ids) <- NULL

cid(drugbank_structure) <- drugbank_sdf_ids


slot_db <- data.frame( `DrugBank ID` = drugbank_sdf_ids,
                       sdf_slot  = 1:length(drugbank_sdf_ids),
                       check.names = F)

drugbank_vocabulary <- dplyr::left_join(drugbank_vocabulary,slot_db)  |> dplyr::filter( !is.na(sdf_slot) )


drugbank_vocabulary$`Molecular Formula` <- ChemmineR::MF(drugbank_structure)

drugbank_vocabulary$`Molecular Weight` <- ChemmineR::MW(drugbank_structure)

drugbank_vocabulary$`Atom Count` <-  as.character( ChemmineR::atomcount(drugbank_structure)) |>
                                    str_sub(start = 3,end = -1 ) |>
                                    str_sub(start = 1,end = -2 )



