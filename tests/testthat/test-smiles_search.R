

test_that("similarity search works", {

  smiles <- "CC(=O)OC1=CC=CC=C1C(=O)O"

  sim_db <- mongolite::mongo(db="chemdb",url = "mongodb://localhost:27017" ,collection = "similarity")

  counts_db <- mongolite::mongo(db="chemdb",url = "mongodb://localhost:27017" ,collection = "mfp_counts")
  r<- smiles_similarity_search(sim_db,counts_db,smiles, threshold = 0.7)

  expect_equal(r$id[1],"CHEMBL25")
  expect_equal(r$tanimoto[1],1)
})



test_that("substructure search works", {

  smiles <- "CC(=O)OC1=CC=CC=C1C(=O)O"

  sim_db <- mongolite::mongo(db="chemdb",url = "mongodb://localhost:27017" ,collection = "similarity")


  ss<- smiles_substructure_search(sim_db,smiles)

  expect_equal(ss$id[1],"CHEMBL25")
  expect_true(ss$Overlap_Coefficient[1] > 0.8)
  expect_true("CHEMBL3833404" %in% ss$id)

})


