
#' update_mfp_counts
#'
#' @param mfp_counts
#' @param molecules_db
#' @param mfp_counts_db
#'
#' @return NONE
#' @export
#'
#' @examples

update_mfp_counts <- function(molecules_db,mfp_counts_db){


counts <- molecules_db$aggregate( '[{"$unwind":"$mfp_bits"},
                        {"$group":{"_id":"$mfp_bits",
                                   "count":{"$sum":1}
                                  }
                        },
                        {"$group":{"_id":null,
                                   "mfp_bits_details":{"$push":{"bit":"$_id","count":"$count"}}}},
                        {"$project":{"_id":0,"mfp_bits_details":1}}

                        ]'  )





mfp_counts <- counts$mfp_bits_details[[1]]




mfp_counts_db$remove('{}')

mfp_counts_db$insert(mfp_counts)

#add index if needed

indexes <- names(molecules_db$info()$stats$indexDetails)

if( !("bit_1" %in% indexes)){

  mfp_counts_db$index(add = '{"bit" : 1}')

}



}








