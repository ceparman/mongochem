
#' Title
#'
#' @param mol
#'
#' @return
#' @export
#'
#' @examples
mol2sdf <- function(mol) {

wr <- rJava::.jnew("java.io.CharArrayWriter")

sdfw <-rJava::.jnew("org.openscience.cdk.io.MDLV2000Writer")

sdfw$setWriter(wr)

sdfw$writeMolecule(mol)

wr$toString()

}




#fileConn<-file("output.sdf")
#writeLines(mol2sdf(drugbank_structure[[2]]), fileConn)
#close(fileConn)
