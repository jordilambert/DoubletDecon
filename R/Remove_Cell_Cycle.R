#' Remove Cell Cycle
#'
#' This function looks for enrichment of cell cycle gene expression clusters and removes those genes.
#' @param data Processed data from Clean_Up_Input.
#' @param species Species as scientific species name, KEGG ID, three letter	species abbreviation, or NCBI ID.
#' @param log_file_name used for saving run notes to log file
#' @return data - data.frame with cell cycle gene cluster removed.
#' @keywords cell cycle KEGG
#' @export

Remove_Cell_Cycle<-function(data, species, log_file_name){

  #load in table of species names
  data(CCtable)
  
  IDtype=which(apply(CCtable, 2, function(x) any(grepl(paste0("\\<", species, "\\>"), x))))
  ccclust=0
  if(IDtype>0){
    #Find the row containing species name information for the provided species
    IDrow=which(apply(CCtable, 1, function(x) any(grepl(paste0("\\<", species, "\\>"), x))))

    for(rowCluster in 1:(length(unique(data[2:nrow(data),1])))){
      genes=rownames(subset(data[2:nrow(data),], data[2:nrow(data),1]==rowCluster)) #get the genes for the row cluster
      sink("/dev/null") #hides mygene output
      geneEquiv=queryMany(genes, species=CCtable[IDrow,4], fields="entrezgene", scopes=c("symbol","alias","name"), return.as="DataFrame") #convert to entrezid
      sink()
      entrezIDs=geneEquiv@listData$entrezgene #grab entrezids
      KEGGresults=enrichKEGG(entrezIDs, organism=CCtable[IDrow,3], pvalueCutoff=0.05, pAdjustMethod="BH", qvalueCutoff=0.1) #submit entrezids for KEGG enrichment

      #look to see if "Cell Cycle is in the list"
      KEGGresultsCC=nrow(subset(KEGGresults, KEGGresults$Description=="Cell cycle"))
      if(KEGGresultsCC>0){
        data=subset(data, (data[,1]!=rowCluster | is.na(data[,1]))) #Remove the cell cycle cluster, is.na() required so we don't lose the "column_clusters-flat" row
        ccclust=ccclust+1
      }
    }
  }
  cat(paste0(ccclust, " cell cycle clusters removed"), file=log_file_name, append=TRUE, sep="\n")
  cat(paste0(ccclust, " cell cycle clusters removed"), sep="\n")

  return(data)
}
