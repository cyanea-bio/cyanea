//! cyanea-struct NIFs — PDB/mmCIF parsing, geometry, DSSP, Kabsch, contact maps, Ramachandran.

use crate::bridge::*;
use crate::to_nif_error;

// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif]
pub fn pdb_info(pdb_text: String) -> Result<PdbInfoNif, String> {
    let structure = cyanea_struct::parse_pdb(&pdb_text).map_err(to_nif_error)?;
    Ok(structure_to_pdb_info(&structure))
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn pdb_file_info(path: String) -> Result<PdbInfoNif, String> {
    let contents = std::fs::read_to_string(&path).map_err(|e| e.to_string())?;
    let structure = cyanea_struct::parse_pdb(&contents).map_err(to_nif_error)?;
    Ok(structure_to_pdb_info(&structure))
}

#[rustler::nif]
pub fn pdb_secondary_structure(
    pdb_text: String,
    chain_id: String,
) -> Result<SecondaryStructureNif, String> {
    let structure = cyanea_struct::parse_pdb(&pdb_text).map_err(to_nif_error)?;
    let chain_char = chain_id
        .chars()
        .next()
        .ok_or("chain_id must be a single character")?;
    let chain = structure
        .get_chain(chain_char)
        .ok_or_else(|| format!("chain '{chain_char}' not found"))?;
    let assignment =
        cyanea_struct::assign_secondary_structure(chain).map_err(to_nif_error)?;
    let assignments: Vec<String> = assignment
        .assignments
        .iter()
        .map(|ss| format!("{:?}", ss))
        .collect();
    let (_h, _e, _t, c) = assignment.counts();
    let total = assignment.assignments.len() as f64;
    let coil_fraction = if total > 0.0 { c as f64 / total } else { 0.0 };
    Ok(SecondaryStructureNif {
        assignments,
        helix_fraction: assignment.helix_fraction(),
        sheet_fraction: assignment.sheet_fraction(),
        coil_fraction,
    })
}

#[rustler::nif]
pub fn pdb_rmsd(
    pdb_a: String,
    pdb_b: String,
    chain_a: String,
    chain_b: String,
) -> Result<f64, String> {
    let struct_a = cyanea_struct::parse_pdb(&pdb_a).map_err(to_nif_error)?;
    let struct_b = cyanea_struct::parse_pdb(&pdb_b).map_err(to_nif_error)?;
    let chain_a_char = chain_a
        .chars()
        .next()
        .ok_or("chain_a must be a single character")?;
    let chain_b_char = chain_b
        .chars()
        .next()
        .ok_or("chain_b must be a single character")?;
    let ca = struct_a
        .get_chain(chain_a_char)
        .ok_or_else(|| format!("chain '{}' not found in first structure", chain_a_char))?;
    let cb = struct_b
        .get_chain(chain_b_char)
        .ok_or_else(|| format!("chain '{}' not found in second structure", chain_b_char))?;
    let atoms_a: Vec<&cyanea_struct::Atom> = ca
        .residues
        .iter()
        .filter_map(|r| r.atoms.iter().find(|a| a.name == "CA"))
        .collect();
    let atoms_b: Vec<&cyanea_struct::Atom> = cb
        .residues
        .iter()
        .filter_map(|r| r.atoms.iter().find(|a| a.name == "CA"))
        .collect();
    cyanea_struct::geometry::rmsd(&atoms_a, &atoms_b).map_err(to_nif_error)
}

// ===========================================================================
// New NIFs
// ===========================================================================

#[rustler::nif]
pub fn mmcif_info(mmcif_text: String) -> Result<PdbInfoNif, String> {
    let structure = cyanea_struct::parse_mmcif(&mmcif_text).map_err(to_nif_error)?;
    Ok(structure_to_pdb_info(&structure))
}

#[rustler::nif]
pub fn pdb_contact_map(
    pdb_text: String,
    chain_id: String,
    cutoff: f64,
) -> Result<ContactMapResultNif, String> {
    let structure = cyanea_struct::parse_pdb(&pdb_text).map_err(to_nif_error)?;
    let chain_char = chain_id
        .chars()
        .next()
        .ok_or("chain_id must be a single character")?;
    let chain = structure
        .get_chain(chain_char)
        .ok_or_else(|| format!("chain '{chain_char}' not found"))?;
    let cmap = cyanea_struct::compute_contact_map(chain).map_err(to_nif_error)?;
    let n_residues = cmap.size;
    let mut contacts = Vec::new();
    for i in 0..n_residues {
        for j in (i + 1)..n_residues {
            let dist = cmap.get(i, j);
            if dist <= cutoff {
                contacts.push((i, j, dist));
            }
        }
    }
    let total_possible = if n_residues > 1 {
        n_residues * (n_residues - 1) / 2
    } else {
        1
    };
    let contact_density = contacts.len() as f64 / total_possible as f64;
    Ok(ContactMapResultNif {
        contacts,
        n_residues,
        contact_density,
    })
}

#[rustler::nif]
pub fn pdb_kabsch(
    pdb_a: String,
    pdb_b: String,
    chain_a: String,
    chain_b: String,
) -> Result<SuperpositionResultNif, String> {
    let struct_a = cyanea_struct::parse_pdb(&pdb_a).map_err(to_nif_error)?;
    let struct_b = cyanea_struct::parse_pdb(&pdb_b).map_err(to_nif_error)?;
    let ca_char = chain_a.chars().next().ok_or("chain_a must be a single character")?;
    let cb_char = chain_b.chars().next().ok_or("chain_b must be a single character")?;
    let ca = struct_a.get_chain(ca_char).ok_or_else(|| format!("chain '{ca_char}' not found"))?;
    let cb = struct_b.get_chain(cb_char).ok_or_else(|| format!("chain '{cb_char}' not found"))?;
    let atoms_a: Vec<&cyanea_struct::Atom> = ca.residues.iter()
        .filter_map(|r| r.atoms.iter().find(|a| a.name == "CA")).collect();
    let atoms_b: Vec<&cyanea_struct::Atom> = cb.residues.iter()
        .filter_map(|r| r.atoms.iter().find(|a| a.name == "CA")).collect();
    let result = cyanea_struct::kabsch(&atoms_a, &atoms_b).map_err(to_nif_error)?;
    Ok(SuperpositionResultNif {
        rmsd: result.rmsd,
        rotation: result.rotation.iter().flat_map(|row| row.iter()).cloned().collect(),
        translation: vec![result.translation.x, result.translation.y, result.translation.z],
    })
}

#[rustler::nif]
pub fn pdb_ramachandran(pdb_text: String) -> Result<Vec<RamachandranEntryNif>, String> {
    let structure = cyanea_struct::parse_pdb(&pdb_text).map_err(to_nif_error)?;
    let report = cyanea_struct::ramachandran_report(&structure).map_err(to_nif_error)?;
    Ok(report
        .into_iter()
        .map(|(num, name, phi, psi, region)| RamachandranEntryNif {
            residue_num: num,
            residue_name: name,
            phi,
            psi,
            region: format!("{:?}", region),
        })
        .collect())
}

#[rustler::nif]
pub fn pdb_bfactor_analysis(pdb_text: String) -> Result<BfactorResultNif, String> {
    let structure = cyanea_struct::parse_pdb(&pdb_text).map_err(to_nif_error)?;
    let mut all_bfactors = Vec::new();
    let mut per_chain = Vec::new();
    for chain in &structure.chains {
        let mut chain_bfactors = Vec::new();
        for residue in &chain.residues {
            for atom in &residue.atoms {
                all_bfactors.push(atom.temp_factor);
                chain_bfactors.push(atom.temp_factor);
            }
        }
        if !chain_bfactors.is_empty() {
            let mean = chain_bfactors.iter().sum::<f64>() / chain_bfactors.len() as f64;
            per_chain.push((chain.id.to_string(), mean));
        }
    }
    if all_bfactors.is_empty() {
        return Err("no atoms found in structure".into());
    }
    let n = all_bfactors.len() as f64;
    let mean = all_bfactors.iter().sum::<f64>() / n;
    let variance = all_bfactors.iter().map(|&b| (b - mean).powi(2)).sum::<f64>() / n;
    let min = all_bfactors.iter().cloned().fold(f64::INFINITY, f64::min);
    let max = all_bfactors.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    Ok(BfactorResultNif {
        mean,
        std_dev: variance.sqrt(),
        min,
        max,
        per_chain,
    })
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn mmcif_file_info(path: String) -> Result<PdbInfoNif, String> {
    let contents = std::fs::read_to_string(&path).map_err(|e| e.to_string())?;
    let structure = cyanea_struct::parse_mmcif(&contents).map_err(to_nif_error)?;
    Ok(structure_to_pdb_info(&structure))
}
