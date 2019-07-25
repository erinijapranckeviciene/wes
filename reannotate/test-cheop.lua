-- Lua functions to return MIM, OMIM, ORPHANET, Gene description, Gnomad OE Lof  annotations
-- Identifier mappings are based on the gene NCBI EntrezID
-- Annotation tables generated by create-annotation-tables.sh

omimFile  = "annotation-tables/OmimTable"
gnomadlofFile     = "annotation-tables/GnomadLofTable"
orphanetFile      = "annotation-tables/OrphaTable"

-- ##################### FUNCTION TO READ FILE TO  TABLES ##########################################
-- Function to read external data as a string of type "key1=value1;...; keyX=valueX"
-- in which key ia alphanumeric type but value can be anything text " 00001=any %^&*: type of symbol; 88786=Gene : somegene_and_*(@#$%^) and anything ; ... "
function TableFromFile(File, newT)
for line in io.lines(File) do
  for key, value in string.gmatch(line,"(%w+)=(.+)") do
--    print(key)
--    print(value)
    newT[key]=value
  end
end  
end

-- ##################### INITIALIZE GLOBAL TABLES ####################################################
-- global table to keep entrezid to mim number mapping
OmimTable={}
--print(mimFile)
TableFromFile(omimFile, OmimTable)

-- global table for ORPHANET annotations
OrphaTable={}
--print(orphanetFile)
TableFromFile(orphanetFile,OrphaTable)

-- global table for ORPHANET annotations
GnomadLofTable={}
--print(gnomadlofFile)
TableFromFile(gnomadlofFile,GnomadLofTable)

-- test the contents of the table
-- TableToTest=mimTable
--for k,v in pairs(TableToTest) do print(k,v) end

-- ##################### DEFINE FUNCTIONS ################################################################ 
-- Function returns annotation associated with gene EntrezID from the table 
function EntrezIDToAnnotation (entrezid, annotationTable)
  return annotationTable[tostring(entrezid)]
end

-- Test script 
id = {10, 100, 1000, 9991, 9992, 9994, 9997}
print(" Test annotations")
for i=1,7 do
  entrez=id[i]
  print("For EntrezID")
  print(entrez) 
  print("Omim")
  print( EntrezIDToAnnotation(entrez, OmimTable) )
  print("Orpha")
  print( EntrezIDToAnnotation(entrez, OrphaTable) )
  print("gnomad lof")
  print( EntrezIDToAnnotation(entrez, GnomadLofTable) )
print("\n\n")
end

