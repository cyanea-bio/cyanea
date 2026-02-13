//! cyanea-chem NIFs — SMILES parsing, molecular properties, fingerprints, substructure.

use crate::bridge::*;
use crate::to_nif_error;

// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif]
pub fn smiles_properties(smiles: String) -> Result<MolecularPropertiesNif, String> {
    let mol = cyanea_chem::parse_smiles(&smiles).map_err(to_nif_error)?;
    let props = cyanea_chem::compute_properties(&mol);
    Ok(MolecularPropertiesNif {
        formula: props.formula,
        weight: props.molecular_weight,
        exact_mass: props.exact_mass,
        hbd: props.hydrogen_bond_donors,
        hba: props.hydrogen_bond_acceptors,
        rotatable_bonds: props.rotatable_bonds,
        ring_count: props.ring_count,
        aromatic_ring_count: props.aromatic_ring_count,
        atom_count: mol.atom_count(),
        bond_count: mol.bond_count(),
    })
}

#[rustler::nif]
pub fn smiles_fingerprint(
    smiles: String,
    radius: usize,
    nbits: usize,
) -> Result<Vec<u8>, String> {
    let mol = cyanea_chem::parse_smiles(&smiles).map_err(to_nif_error)?;
    let fp = cyanea_chem::morgan_fingerprint(&mol, radius, nbits);
    Ok(fingerprint_to_bytes(&fp))
}

#[rustler::nif]
pub fn tanimoto(
    smiles_a: String,
    smiles_b: String,
    radius: usize,
    nbits: usize,
) -> Result<f64, String> {
    let mol_a = cyanea_chem::parse_smiles(&smiles_a).map_err(to_nif_error)?;
    let mol_b = cyanea_chem::parse_smiles(&smiles_b).map_err(to_nif_error)?;
    let fp_a = cyanea_chem::morgan_fingerprint(&mol_a, radius, nbits);
    let fp_b = cyanea_chem::morgan_fingerprint(&mol_b, radius, nbits);
    Ok(cyanea_chem::tanimoto_similarity(&fp_a, &fp_b))
}

#[rustler::nif]
pub fn smiles_substructure(target: String, pattern: String) -> Result<bool, String> {
    let target_mol = cyanea_chem::parse_smiles(&target).map_err(to_nif_error)?;
    let pattern_mol = cyanea_chem::parse_smiles(&pattern).map_err(to_nif_error)?;
    Ok(cyanea_chem::has_substructure(&target_mol, &pattern_mol))
}

// ===========================================================================
// New NIFs
// ===========================================================================

#[rustler::nif]
pub fn canonical_smiles(smiles: String) -> Result<String, String> {
    let mol = cyanea_chem::parse_smiles(&smiles).map_err(to_nif_error)?;
    Ok(cyanea_chem::canonical_smiles(&mol))
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn parse_sdf_file(path: String) -> Result<Vec<SdfMoleculeNif>, String> {
    let contents = std::fs::read_to_string(&path).map_err(|e| e.to_string())?;
    let molecules = cyanea_chem::parse_sdf(&contents);
    let mut results = Vec::new();
    for mol_result in molecules {
        let mol = mol_result.map_err(to_nif_error)?;
        let props = cyanea_chem::compute_properties(&mol);
        results.push(SdfMoleculeNif {
            name: mol.name.clone(),
            atom_count: mol.atom_count(),
            bond_count: mol.bond_count(),
            formula: props.formula,
            weight: props.molecular_weight,
        });
    }
    Ok(results)
}

#[rustler::nif]
pub fn maccs_fingerprint(smiles: String) -> Result<Vec<u8>, String> {
    let mol = cyanea_chem::parse_smiles(&smiles).map_err(to_nif_error)?;
    let fp = cyanea_chem::maccs_fingerprint(&mol);
    Ok(fingerprint_to_bytes(&fp))
}
