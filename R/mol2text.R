#' Title
#'
#' @param molecule
#'
#' @return
#' @export
#'
#' @examples
mol2text <-function(molecule) {

sdg <- rJava::.jnew("org.openscience.cdk.layout.StructureDiagramGenerator" )

sdg$setMolecule(molecule )
sdg$generateCoordinates()
mol <- sdg$getMolecule()
t <- mol$toString()
t
}

#mol2text(drugbank_structure[[1]])

