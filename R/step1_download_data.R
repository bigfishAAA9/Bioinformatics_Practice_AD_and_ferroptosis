library(GEOquery)
library(AnnoProbe)
dest_dir <- "./geo_data"

filterEM2 <- function(probes_expr,probe2gene,method="mean"){
  colnames(probe2gene) <- c("probeid","symbol")
  probe2gene$probeid=as.character(probe2gene$probeid)
  probe2gene$symbol=trimws(probe2gene$symbol)
  # head(probe2gene)
  
  message(paste0('input expression matrix is ',nrow(probes_expr),' rows(genes or probes) and ',ncol(probes_expr),' columns(samples).\n'))
  message(paste0('input probe2gene is ',nrow(probe2gene),' rows(genes or probes)\n'))
  
  probe2gene=na.omit(probe2gene)
  # if one probe mapped to many genes, we will only keep one randomly.
  probe2gene=probe2gene[!duplicated(probe2gene$probeid),]
  # 这个地方是有问题的，随机挑选一个注释进行后续分析。
  probe2gene = probe2gene[probe2gene$probeid %in% rownames(probes_expr),]
  
  message(paste0('after remove NA or useless probes for probe2gene, ',nrow(probe2gene),' rows(genes or probes) left\n'))
  
  #probes_expr <- exprs(eSet);dim(probes_expr)
  probes_expr <- as.data.frame(probes_expr)
  genes_expr <- tibble::rownames_to_column(probes_expr,var="probeid") %>%
    merge(probe2gene,.,by="probeid")
  genes_expr <- genes_expr[-1]
  # probes_expr[1:4,1:4]
  
  # remove duplicates sympol:method=mead,also median, max ,min
  message("remove duplicates sympols, it will take a while")
  genes_expr <- aggregate(x=genes_expr[,2:ncol(genes_expr)],by=list(genes_expr$symbol),FUN=method,na.rm=T)
  genes_expr <- tibble::column_to_rownames(genes_expr,var = "Group.1")
  # genes_expr[1:4,1:4]
  message(paste0('output expression matrix is ',nrow(genes_expr),' rows(genes or probes) and ',ncol(genes_expr),' columns(samples).'))
  # probes_expr['AGAP6',]
  return(genes_expr)
}

geo_data = getGEO('GSE173954', destdir = dest_dir, getGPL = FALSE)
geo_data <- geo_data[[1]]
exp = exprs(geo_data)
clin = phenoData(geo_data)
clin = clin@data

library(oligo)
celFiles <- list.celfiles('./geo_data/GSM5283439/',listGzipped=T,
                          full.name=TRUE)
exon_data <- oligo::read.celfiles(celFiles)
exon_data_rma <- oligo::rma(exon_data)
exp_probe <- Biobase::exprs(exon_data_rma)
probes_expr = exp_probe

family = getGEO(filenam = 'geo_data/GSE173954_family.soft.gz')
family = family@gpls$GPL17586@dataTable@table
boxplot(exp_probe)

probe2gene = family[, c(1, 8)]
library(stringr)
probe2gene$symbol=trimws(str_split(probe2gene$gene_assignment,'//',simplify = T)[,2])
plot(table(table(probe2gene$symbol)),xlim=c(1,50))
probe2gene = probe2gene[, -2]
probe2gene = probe2gene[!probe2gene$symbol=='---',]


geo = getGEO(filename = './geo_data/GSE5281/GSE5281_series_matrix.txt.gz', getGPL = FALSE)
geo = phenoData(geo)
geo = geo@data
sum(geo$`brain region:ch1` == 'hippocampus' & !is.na(geo$`braak stage:ch1`))

genes_expr <- filterEM2(exp_probe,probe2gene)
