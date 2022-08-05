#Validation for molecules
#' valdoc
#'
#' @return
#' @export
#'
#' @examples
valdoc <- function() {

valdoc <- '"validator": { "$jsonSchema":
                                       { "bsonType": "object",
                                         "required": ["Base ID","ID","Id Type","Collection","smiles",
                                                     "Molecular Weight","Exact Mass","Formula","mfp_count","mfp_bits"],
                                         "properties": { "Base ID": {
                                                         "bsonType": "string",
                                                         "description": "must be a string and is required"
                                                         },
                                                         "ID": {
                                                         "bsonType": "string",
                                                         "description": "must be a string and is required"
                                                         },
                                                         "Id Type": {
                                                         "bsonType": "string",
                                                         "description": "must be a string and is required"
                                                         },
                                                         "Collection": {
                                                         "bsonType": "string",
                                                         "description": "must be a string and is required"
                                                         },
                                                          "smiles": {
                                                         "bsonType": "string",
                                                         "description": "valid smiles string"
                                                         },
                                                         "Molecular Weight": {
                                                         "bsonType": "double",
                                                         "description": "reqired fields for MW"
                                                         },
                                                         "Exact Mass": {
                                                         "bsonType": "double",
                                                         "description": "reqired fields for Exact Mass"
                                                         },
                                                         "Formula": {
                                                          "bsonType": "string",
                                                         "description": "formula"
                                                          },
                                                         "mfp_count": {
                                                         "bsonType": "int",
                                                         "description": "fingerprint counts"
                                                         },
                                                          "mfp_bits": {
                                                         "bsonType": "array",
                                                         "description": "fingerprint bits"
                                                         }


                                                      }
                                       }
                     }'


return(valdoc)
}
