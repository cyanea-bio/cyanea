//! cyanea-align NIFs — Pairwise alignment, batch, MSA, banded, POA.

use crate::bridge::*;
use crate::to_nif_error;

// ===========================================================================
// Helpers
// ===========================================================================

pub(crate) fn parse_alignment_mode(mode: &str) -> Result<cyanea_align::AlignmentMode, String> {
    match mode {
        "local" => Ok(cyanea_align::AlignmentMode::Local),
        "global" => Ok(cyanea_align::AlignmentMode::Global),
        "semiglobal" => Ok(cyanea_align::AlignmentMode::SemiGlobal),
        _ => Err(format!("unknown alignment mode: {mode} (expected local, global, or semiglobal)")),
    }
}

fn parse_substitution_matrix(name: &str) -> Result<cyanea_align::SubstitutionMatrix, String> {
    match name {
        "blosum62" => Ok(cyanea_align::SubstitutionMatrix::blosum62()),
        "blosum45" => Ok(cyanea_align::SubstitutionMatrix::blosum45()),
        "blosum80" => Ok(cyanea_align::SubstitutionMatrix::blosum80()),
        "pam250" => Ok(cyanea_align::SubstitutionMatrix::pam250()),
        _ => Err(format!("unknown substitution matrix: {name} (expected blosum62, blosum45, blosum80, or pam250)")),
    }
}

// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif]
pub fn align_dna(query: Vec<u8>, target: Vec<u8>, mode: String) -> Result<AlignmentResultNif, String> {
    let mode = parse_alignment_mode(&mode)?;
    let scoring = cyanea_align::ScoringScheme::Simple(cyanea_align::ScoringMatrix::dna_default());
    cyanea_align::align(&query, &target, mode, &scoring)
        .map(AlignmentResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn align_dna_custom(
    query: Vec<u8>,
    target: Vec<u8>,
    mode: String,
    match_score: i32,
    mismatch_score: i32,
    gap_open: i32,
    gap_extend: i32,
) -> Result<AlignmentResultNif, String> {
    let mode = parse_alignment_mode(&mode)?;
    let matrix = cyanea_align::ScoringMatrix::new(match_score, mismatch_score, gap_open, gap_extend)
        .map_err(to_nif_error)?;
    let scoring = cyanea_align::ScoringScheme::Simple(matrix);
    cyanea_align::align(&query, &target, mode, &scoring)
        .map(AlignmentResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn align_protein(
    query: Vec<u8>,
    target: Vec<u8>,
    mode: String,
    matrix: String,
) -> Result<AlignmentResultNif, String> {
    let mode = parse_alignment_mode(&mode)?;
    let sub_matrix = parse_substitution_matrix(&matrix)?;
    let scoring = cyanea_align::ScoringScheme::Substitution(sub_matrix);
    cyanea_align::align(&query, &target, mode, &scoring)
        .map(AlignmentResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn align_batch_dna(
    pairs: Vec<(Vec<u8>, Vec<u8>)>,
    mode: String,
) -> Result<Vec<AlignmentResultNif>, String> {
    let mode = parse_alignment_mode(&mode)?;
    let scoring = cyanea_align::ScoringScheme::Simple(cyanea_align::ScoringMatrix::dna_default());
    let refs: Vec<(&[u8], &[u8])> = pairs.iter().map(|(q, t)| (q.as_slice(), t.as_slice())).collect();
    cyanea_align::align_batch(&refs, mode, &scoring)
        .map(|results| results.into_iter().map(AlignmentResultNif::from).collect())
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn progressive_msa(sequences: Vec<Vec<u8>>, mode: String) -> Result<MsaResultNif, String> {
    let refs: Vec<&[u8]> = sequences.iter().map(|s| s.as_slice()).collect();
    let scoring = match mode.as_str() {
        "dna" => {
            cyanea_align::ScoringScheme::Simple(cyanea_align::ScoringMatrix::dna_default())
        }
        "protein" => cyanea_align::ScoringScheme::Substitution(
            cyanea_align::SubstitutionMatrix::blosum62(),
        ),
        _ => return Err(format!("unknown MSA mode: {mode} (expected dna or protein)")),
    };
    let result = cyanea_align::msa::progressive_msa(&refs, &scoring).map_err(to_nif_error)?;
    let n_sequences = result.n_sequences();
    let n_columns = result.n_columns;
    let conservation = result.conservation();
    Ok(MsaResultNif {
        aligned: result.aligned,
        n_sequences,
        n_columns,
        conservation,
    })
}

// ===========================================================================
// New NIFs
// ===========================================================================

#[rustler::nif]
pub fn banded_align_dna(
    query: Vec<u8>,
    target: Vec<u8>,
    mode: String,
    bandwidth: usize,
) -> Result<AlignmentResultNif, String> {
    let mode = parse_alignment_mode(&mode)?;
    let scoring = cyanea_align::ScoringScheme::Simple(cyanea_align::ScoringMatrix::dna_default());
    let result = match mode {
        cyanea_align::AlignmentMode::Global => {
            cyanea_align::simd::banded_nw(&query, &target, &scoring, bandwidth)
        }
        cyanea_align::AlignmentMode::Local => {
            cyanea_align::simd::banded_sw(&query, &target, &scoring, bandwidth)
        }
        cyanea_align::AlignmentMode::SemiGlobal => {
            cyanea_align::simd::banded_semi_global(&query, &target, &scoring, bandwidth)
        }
    };
    result.map(AlignmentResultNif::from).map_err(to_nif_error)
}

#[rustler::nif]
pub fn banded_score_only(
    query: Vec<u8>,
    target: Vec<u8>,
    mode: String,
    bandwidth: usize,
) -> Result<i32, String> {
    let mode = parse_alignment_mode(&mode)?;
    let scoring = cyanea_align::ScoringScheme::Simple(cyanea_align::ScoringMatrix::dna_default());
    cyanea_align::simd::banded_score_only(&query, &target, &scoring, bandwidth, mode)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn poa_consensus(sequences: Vec<Vec<u8>>) -> Result<Vec<u8>, String> {
    if sequences.is_empty() {
        return Err("at least one sequence required".into());
    }
    let scoring = cyanea_align::poa::PoaScoring {
        match_score: 2,
        mismatch_score: -1,
        gap_score: -2,
    };
    let mut graph = cyanea_align::poa::PoaGraph::from_sequence(&sequences[0]);
    for seq in &sequences[1..] {
        graph.add_sequence(seq, &scoring).map_err(to_nif_error)?;
    }
    Ok(graph.consensus())
}
