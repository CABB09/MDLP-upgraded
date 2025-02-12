mylog <-
  function(x){
    x[which(x<=1.0e-10)] <- 1
    return (log(x))
  }

ent <-
  function(y){
    p <- table(y)/length(y)
    e <- -sum(p*mylog(p))
    return(e)
  }

mdlStop <-
  function(ci,y,entropy){
    n <- length(y)
    es <- ent(y)
    left <- 1:ci; right <- (ci+1):n     
    gain <- es-entropy   
    l0 <- levels(factor(y))
    l1 <- levels(factor(y[left])); l2 <- levels(factor(y[right]))         
    k <- length(l0)
    k1 <- length(l1); k2 <- length(l2)
    delta <- mylog(3^k-2)-(k*es-k1*ent(y[left])-k2*ent(y[right]))
    cond <- mylog(n-1)/n+delta/n        
    if(gain<cond) return (NULL)
    return(gain)}

cutIndex <-
  function(x,y){
    n <- length(y)
    initEnt <- 9999 
    entropy <- initEnt; ci <- NULL;
    for (i in 1:(n-1)){
      if(x[i+1]!=x[i]) {
        ct <- (x[i]+x[i+1])/2
        wx <- which(x<=ct)
        wn <- length(wx)/n
        e1 <- wn*ent(y[wx])
        e2 <- (1-wn)*ent(y[-wx])
        val <- e1+e2
        if(val<entropy) {
          entropy <- val
          ci <- i
        }
      }
    }
    if(is.null(ci)) return(NULL) 
    return (c(ci, entropy))
  }

cutPoints <-
  function(x,y){
    od <- order(x)    
    xo <- x[od]
    yo <- y[od]    
    depth <- 1     
    
    gr <- function(low,upp,depth=depth){ 
      x <- xo[low:upp]  
      y <- yo[low:upp]  
      n <- length(y) 
      ct <- cutIndex(x,y)
      if(is.null(ct)) return (NULL) ## when cut index=NULL
      ci <- ct[1]; entropy <- ct[2]
      ret <- mdlStop(ci,y,entropy) # MDL Stop
      if(is.null(ret)) return(NULL)
      return(c(ci,depth+1)) 
    } 
    
    ## xo: original x in ascending order of x; 
    ## yo: original y reordered in ascending order of x 
    part <- function(low=1, upp=length(xo), cutPoints=NULL,depth=depth){
      x <- xo[low:upp]
      y <- yo[low:upp]
      n <- length(x)
      if(n<2) return (cutPoints)
      cc <- gr(low, upp, depth=depth)
      ci <- cc[1]
      depth <- cc[2]
      if(is.null(ci)) return(cutPoints)
      cutPoints <- c(cutPoints,low+ci-1)
      cutPoints <- as.integer(sort(cutPoints))
      return(c(part(low, low+ci-1,cutPoints,depth=depth), 
               part(low+ci,upp,cutPoints,depth=depth)))
    }
    
    res <- part(depth=depth)
    ci <- NULL ;cv <- numeric()
    if(!is.null(res)) {
      ci <- as.integer(res)
      cv <- (xo[ci]+xo[ci+1])/2
    }
    res <- unique(cv)## returns cutIndex and cutValues
    return(res)
  }

# Cargar paquetes necesarios
library(parallel)
library(data.table)

# Función MDLP paralelizada
mdlp_parallel <- function(data, target_col) {
  # Número de columnas predictoras
  predictor_cols <- setdiff(names(data), target_col)
  xd <- data           # Copia de los datos para discretizar
  cutp <- list()       # Lista para almacenar puntos de corte
  
  # Crear clúster con los núcleos disponibles
  n_cores <- detectCores() - 1  # Usa todos los núcleos menos 1 para el sistema
  cl <- makeCluster(n_cores)
  
  # Exportar funciones y datos al clúster
  clusterExport(cl, c("cutPoints", "ent", "mylog", "mdlStop", "cutIndex"))
  
  # Paralelizar el cálculo de los puntos de corte
  cutp <- parLapply(cl, predictor_cols, function(col_name) {
    x <- data[[col_name]]         # Obtener columna actual
    y <- data[[target_col]]       # Reimportar la variable objetivo dentro del clúster
    cuts1 <- cutPoints(x, y)      # Calcular puntos de corte
    cuts <- c(min(x), cuts1, max(x))  # Agregar límites
    if (length(cuts1) == 0) {
      return(rep("All", length(x)))  # Si no hay cortes, devolver "All"
    }
    as.integer(cut(x, cuts, include.lowest = TRUE))
  })
  
  # Incorporar los datos discretizados en el dataset
  for (i in seq_along(predictor_cols)) {
    xd[[predictor_cols[i]]] <- cutp[[i]]
  }
  # Detener el clúster
  stopCluster(cl)
  # Devolver los resultados
  return(list(cutp = cutp, Disc.data = xd))
}

# Ruta a la base de datos  
file_path <- "C:/Users/Carlo/Desktop/IA/MDLP/bases de datos/gamma.csv"

# Cargar la base de datos
data <- fread(file_path)

inicio <- Sys.time()

# Aplicar MDLP
result <- mdlp_parallel(data, target_col = "class")

# Guardar resultados
discretized_data <- result$Disc.data

write.csv(discretized_data, "C:/Users/Carlo/Desktop/IA/MDLP/base de datos discretizadas con mdlp R/gamma.csv", row.names = FALSE)

fin <- Sys.time()
# Verificar resultados
print(head(discretized_data))
print(fin - inicio)
