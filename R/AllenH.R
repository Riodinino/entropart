AllenH <-
function(Ps, q = 1, PhyloTree, Normalize = TRUE, Prune = FALSE, CheckArguments = TRUE) 
{
  if (CheckArguments)
    CheckentropartArguments()
  
  # Tree must be either a phylog, phylo or a hclust object
  if (inherits(PhyloTree, "phylog")) {
    # build a phylo object. Go through an hclust because as.phylo.phylog sometimes generates errors
    hTree <- stats::hclust(PhyloTree$Wdist^2/2, "average")
    Tree <- ape::as.phylo.hclust(hTree)
    # Double edge.lengths to correct as.phylo.hclust
    Tree$edge.length <- 2*Tree$edge.length
  } else {
    if (inherits(PhyloTree, "hclust")) {
      # build a phylo object
      Tree <- ape::as.phylo.hclust(PhyloTree)
      # Double edge.lengths to correct as.phylo.hclust
      Tree$edge.length <- 2*Tree$edge.length
    } else {
      if (inherits(PhyloTree, "phylo")) {
        Tree <- PhyloTree
      } else {
        if (inherits(PhyloTree, "PPtree")) {
          Tree <- PhyloTree$phyTree
        } else {
          stop("Tree must be an object of class phylo, phylog, hclust or PPtree")
        }
      }
    }
  }
  
  # Ps must be named
  if (is.null(names(Ps)))
    stop("Ps must be named to match the tree's species")
  # Verifiy all species are in the tree
  SpeciesNotFound <- setdiff(names(Ps), Tree$tip.label)
  if (length(SpeciesNotFound) > 0) {
    stop(paste("Species not found in the tree: ", SpeciesNotFound, collapse = "; "))
    print(SpeciesNotFound)
  }
  
  # More species in the tree than in Ps?
  SpeciesNotFound <- setdiff(Tree$tip.label, names(Ps))
  if (length(SpeciesNotFound) > 0 ){
    if (Prune) {
      # Prune the tree to keep species in Ps only
      Tree <- ape::drop.tip(Tree, SpeciesNotFound)
    } else {
      # Add species with probability 0 in Ps
      ExtraPs <- rep(0, length(SpeciesNotFound))
      names(ExtraPs) <- SpeciesNotFound
      Ps <- c(Ps, ExtraPs)
    }
  }

    # Branch lengths
  Lengths <- Tree$edge.length
  # Get unnormalized probabilities p(b)
  ltips <- sapply(Tree$edge[, 2], function(node) geiger::tips(Tree, node))
  Branches <- unlist(lapply(ltips, function(VectorOfTips) sum(Ps[VectorOfTips])))
  # Calculate Tbar but do not normalize l(b)
  Tbar <- sum(Lengths*Branches)
  
  # Eliminate unobserved species (or 0log0 will retrun NaN)
  Lengths <- Lengths[Branches!=0]
  Branches <- Branches[Branches!=0]
  
  # Return normalized entropy
  entropy <- -sum(Lengths * Branches^q * lnq(Branches, q))/ifelse(Normalize, Tbar, 1)
  names(entropy) <- "None"
  return (entropy)
}
