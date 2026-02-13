//! cyanea-phylo NIFs — Newick/NEXUS I/O, tree distances, tree building, bootstrap.

use crate::bridge::*;
use crate::to_nif_error;

// ===========================================================================
// Helpers
// ===========================================================================

fn parse_distance_model(s: &str) -> Result<cyanea_phylo::DistanceModel, String> {
    match s {
        "p" => Ok(cyanea_phylo::DistanceModel::P),
        "jc" => Ok(cyanea_phylo::DistanceModel::JukesCantor),
        "k2p" => Ok(cyanea_phylo::DistanceModel::Kimura2P),
        _ => Err(format!(
            "unknown distance model: {s} (expected p, jc, or k2p)"
        )),
    }
}

// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif]
pub fn newick_info(newick: String) -> Result<NewickInfoNif, String> {
    let tree = cyanea_phylo::parse_newick(&newick).map_err(to_nif_error)?;
    let leaf_count = tree.leaf_count();
    let leaf_names = tree.leaf_names();
    let roundtripped = cyanea_phylo::write_newick(&tree);
    Ok(NewickInfoNif {
        leaf_count,
        leaf_names,
        newick: roundtripped,
    })
}

#[rustler::nif]
pub fn newick_robinson_foulds(newick_a: String, newick_b: String) -> Result<usize, String> {
    let tree_a = cyanea_phylo::parse_newick(&newick_a).map_err(to_nif_error)?;
    let tree_b = cyanea_phylo::parse_newick(&newick_b).map_err(to_nif_error)?;
    cyanea_phylo::robinson_foulds(&tree_a, &tree_b).map_err(to_nif_error)
}

#[rustler::nif]
pub fn evolutionary_distance(
    seq_a: Vec<u8>,
    seq_b: Vec<u8>,
    model: String,
) -> Result<f64, String> {
    match model.as_str() {
        "p" => cyanea_phylo::p_distance(&seq_a, &seq_b).map_err(to_nif_error),
        "jc" => {
            let p = cyanea_phylo::p_distance(&seq_a, &seq_b).map_err(to_nif_error)?;
            cyanea_phylo::jukes_cantor(p).map_err(to_nif_error)
        }
        "k2p" => {
            let seqs: Vec<&[u8]> = vec![seq_a.as_slice(), seq_b.as_slice()];
            let dm = cyanea_phylo::sequence_distance_matrix(
                &seqs,
                cyanea_phylo::DistanceModel::Kimura2P,
            )
            .map_err(to_nif_error)?;
            Ok(dm.get(0, 1))
        }
        _ => Err(format!(
            "unknown distance model: {model} (expected p, jc, or k2p)"
        )),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn build_upgma(
    sequences: Vec<Vec<u8>>,
    names: Vec<String>,
    model: String,
) -> Result<String, String> {
    let model = parse_distance_model(&model)?;
    let refs: Vec<&[u8]> = sequences.iter().map(|s| s.as_slice()).collect();
    let dm = cyanea_phylo::sequence_distance_matrix(&refs, model).map_err(to_nif_error)?;
    let tree = cyanea_phylo::upgma(&dm, &names).map_err(to_nif_error)?;
    Ok(cyanea_phylo::write_newick(&tree))
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn build_nj(
    sequences: Vec<Vec<u8>>,
    names: Vec<String>,
    model: String,
) -> Result<String, String> {
    let model = parse_distance_model(&model)?;
    let refs: Vec<&[u8]> = sequences.iter().map(|s| s.as_slice()).collect();
    let dm = cyanea_phylo::sequence_distance_matrix(&refs, model).map_err(to_nif_error)?;
    let tree = cyanea_phylo::neighbor_joining(&dm, &names).map_err(to_nif_error)?;
    Ok(cyanea_phylo::write_newick(&tree))
}

// ===========================================================================
// New NIFs
// ===========================================================================

#[rustler::nif]
pub fn nexus_parse(nexus_text: String) -> Result<NexusFileNif, String> {
    let nexus = cyanea_phylo::nexus::parse(&nexus_text).map_err(to_nif_error)?;
    Ok(NexusFileNif {
        taxa: nexus.taxa.clone(),
        tree_names: nexus.trees.iter().map(|t| t.name.clone()).collect(),
        tree_newicks: nexus.trees.iter().map(|t| cyanea_phylo::write_newick(&t.tree)).collect(),
    })
}

#[rustler::nif]
pub fn nexus_write(taxa: Vec<String>, trees_newick: Vec<String>) -> Result<String, String> {
    let mut parsed_trees = Vec::new();
    let mut names = Vec::new();
    for (i, newick) in trees_newick.iter().enumerate() {
        let tree = cyanea_phylo::parse_newick(newick).map_err(to_nif_error)?;
        parsed_trees.push(tree);
        names.push(format!("tree{}", i + 1));
    }
    let tree_refs: Vec<(&str, &cyanea_phylo::PhyloTree)> = names
        .iter()
        .zip(parsed_trees.iter())
        .map(|(n, t)| (n.as_str(), t))
        .collect();
    Ok(cyanea_phylo::nexus::write(&taxa, &tree_refs))
}

#[rustler::nif]
pub fn robinson_foulds_normalized(newick_a: String, newick_b: String) -> Result<f64, String> {
    let tree_a = cyanea_phylo::parse_newick(&newick_a).map_err(to_nif_error)?;
    let tree_b = cyanea_phylo::parse_newick(&newick_b).map_err(to_nif_error)?;
    cyanea_phylo::robinson_foulds_normalized(&tree_a, &tree_b).map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn bootstrap_support(
    sequences: Vec<Vec<u8>>,
    tree_newick: String,
    n_replicates: usize,
    model: String,
) -> Result<Vec<f64>, String> {
    let model = parse_distance_model(&model)?;
    let refs: Vec<&[u8]> = sequences.iter().map(|s| s.as_slice()).collect();
    let tree = cyanea_phylo::parse_newick(&tree_newick).map_err(to_nif_error)?;
    let builder = |seqs: &[Vec<u8>]| -> cyanea_core::Result<cyanea_phylo::PhyloTree> {
        let seq_refs: Vec<&[u8]> = seqs.iter().map(|s| s.as_slice()).collect();
        let names: Vec<String> = (0..seqs.len()).map(|i| format!("t{}", i)).collect();
        let dm = cyanea_phylo::sequence_distance_matrix(&seq_refs, model)?;
        cyanea_phylo::neighbor_joining(&dm, &names)
    };
    cyanea_phylo::bootstrap_support(&refs, &tree, builder, n_replicates).map_err(to_nif_error)
}

#[rustler::nif]
pub fn ancestral_reconstruction(
    tree_newick: String,
    leaf_states: Vec<String>,
) -> Result<Vec<String>, String> {
    let tree = cyanea_phylo::parse_newick(&tree_newick).map_err(to_nif_error)?;
    let leaves = tree.leaves();
    if leaves.len() != leaf_states.len() {
        return Err(format!(
            "expected {} leaf states but got {}",
            leaves.len(),
            leaf_states.len()
        ));
    }
    // Convert string states to u8 indices and pair with NodeIds
    let mut state_map: Vec<String> = Vec::new();
    let mut leaf_state_pairs: Vec<(usize, u8)> = Vec::new();
    for (i, state) in leaf_states.iter().enumerate() {
        let idx = state_map.iter().position(|s| s == state).unwrap_or_else(|| {
            state_map.push(state.clone());
            state_map.len() - 1
        });
        leaf_state_pairs.push((leaves[i], idx as u8));
    }
    let result = cyanea_phylo::reconstruct::fitch(&tree, &leaf_state_pairs)
        .map_err(to_nif_error)?;
    Ok(result.states.iter().map(|&s| {
        state_map.get(s as usize).cloned().unwrap_or_else(|| format!("state_{}", s))
    }).collect())
}

#[rustler::nif]
pub fn branch_score_distance(newick_a: String, newick_b: String) -> Result<f64, String> {
    let tree_a = cyanea_phylo::parse_newick(&newick_a).map_err(to_nif_error)?;
    let tree_b = cyanea_phylo::parse_newick(&newick_b).map_err(to_nif_error)?;
    cyanea_phylo::branch_score_distance(&tree_a, &tree_b).map_err(to_nif_error)
}
