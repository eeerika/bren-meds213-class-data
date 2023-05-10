# Required packages
library(EML)
library(emld)

# Below is a minimal valid EML record with a tile, creator and contact info.

me <- list(individualName = list(givenName = "Renata", surName = "Curty"))
eml_mini <- list(dataset = list(
  title = "This is a minimal valid EML dataset record",
  creator = me,
  contact = me)
)

#We then need to run 
write_eml(eml_mini, "eml-mini.xml")
eml_validate("eml-mini.xml")

#We should get [1] TRUE with no errors and a min.xml record

# As we learned this is too bare bones, and not enough for findability, reusability and interoperability.
# We need richer metadata!
# Time to open the 02_eml-losapio.R script file.
