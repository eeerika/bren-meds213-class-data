# Time for the attribute/variable metadata present in a data entity
# These data entities might be dataTable, spatialRaster or other type
# For this challenge you'll describe the attributes at the file level for tabular data.
# Open the insect-record.csv file and complete the tribble below.
# What is a tribble in R?

# Challenge. Open the insect-record.csv file and complete the tribble for the dataset.

# Open the insects

# Attributes

attributes <-
  tibble::tribble(
    ~attributeName,          ~attributeDefinition,                                  ~formatString,   ~definition,                     
    "id",                    "insect id",                                           NA,              NA,)

    
               
# Time to create an attributeList and describe the col_classes
# Hint! Check: https://docs.ropensci.org/EML/reference/set_attributes.html

attributeList <- set_attributes(attributes, col_classes = 
                                  c("character"))

# Data file format

physical <- set_physical("insect-record.csv")


# Assembling the dataTable

dataTable <- list(
  entityName = "insect-record.csv",
  entityDescription = "Insect observations",
  physical = physical,
  attributeList = attributeList)

# When done, make sure to have this code copied into the 02_eml-losapio.R script, update the elements table and re-run the code.
# Alternatively, you may create a 04_eml-losapio-complete.R.