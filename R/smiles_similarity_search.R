

#' Similarity search using smiles
#' @param sim_db  Similarity database
#' @param counts_db fingerprint counts database
#' @param smiles  smiles to search
#' @param threshold tanimoto similarity threshold
#'
#' @return data frame with sim_db id, chemical ID, smiles of hit, similarity score
#' @export
#'
#' @examples
#'
#'\dontrun{
#'
#'smiles <- "CC(=O)OC1=CC=CC=C1C(=O)O"
#'
#'sim_db <- mongolite::mongo(db="chemdb",url = "mongodb://localhost:27017" ,collection = "molecules")
#'
#' counts_db <- mongolite::mongo(db="chemdb",url = "mongodb://localhost:27017" ,collection = "mfp_counts")
#' smiles_similarity_search(sim_db,counts_db,smiles, threshold = 0.7)
#' }
#'

smiles_similarity_search <- function(sim_db,counts_db,smiles, threshold = 0.7){

    print(threshold)

     mols <- rcdk::parse.smiles(smiles)

    qfp <- as.character(
          rcdk::get.fingerprint(mols[[1]],
                                depth = 2,size = 2048,type = "circular",circular.type = 'ECFP6',verbose = T)@bits )
    print(qfp)

    qn <- length(qfp)                   # Number of bits in query fingerprint
    qmin <- ceiling(qn * threshold)     # Minimum number of bits in results fingerprints
    qmax <- qn / threshold              # Maximum number of bits in results fingerprints
    ncommon <- qn - qmin + 1            #

print(ncommon)

    req_bits <- counts_db$find( query = jsonlite::toJSON ( list(
      bit = list( `$in`= qfp))),
      limit=ncommon,
      sort = '{"count": -1}'

    )



    sim_aggregate <- paste0('[  {"$match": {"mfp_count": {"$gte":', qmin,', "$lte":', qmax,'}, "mfp_bits": {"$in":',jsonlite::toJSON(paste0(req_bits$bit)),'}}},
      {"$project": {
       "tanimoto": {"$let": {
         "vars": {"common": {"$size": {"$setIntersection": ["$mfp_bits",',jsonlite::toJSON(paste0(qfp)),']}}},
         "in": {"$divide": ["$$common", {"$subtract": [{"$add": [',qn, ',"$mfp_count"]}, "$$common"]}]}
       }},
       "smiles": 1,
       "id": 1
     }},
     {"$match": {"tanimoto": {"$gte":', threshold,'}}}
   ]')


  d<-  sim_db$aggregate(sim_aggregate)  #execute db aggregate function



  d

}
