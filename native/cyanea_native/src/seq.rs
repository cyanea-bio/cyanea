//! cyanea-seq NIFs — Sequence I/O, validation, operations, k-mers, pattern matching.

use crate::bridge::*;
use crate::to_nif_error;


// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif(schedule = "DirtyCpu")]
pub fn fasta_stats(path: String) -> Result<FastaStatsNif, String> {
    cyanea_seq::parse_fasta_stats(&path)
        .map(FastaStatsNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn validate_dna(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.into_bytes())
}

#[rustler::nif]
pub fn validate_rna(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::RnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.into_bytes())
}

#[rustler::nif]
pub fn validate_protein(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::ProteinSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.into_bytes())
}

#[rustler::nif]
pub fn dna_reverse_complement(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.reverse_complement().into_bytes())
}

#[rustler::nif]
pub fn dna_transcribe(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.transcribe().into_bytes())
}

#[rustler::nif]
pub fn dna_gc_content(data: Vec<u8>) -> Result<f64, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.gc_content())
}

#[rustler::nif]
pub fn rna_translate(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::RnaSequence::new(&data).map_err(to_nif_error)?;
    seq.translate()
        .map(|p| p.into_bytes())
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn sequence_kmers(data: Vec<u8>, k: usize) -> Result<Vec<Vec<u8>>, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    let kmers = seq
        .kmers(k)
        .map_err(to_nif_error)?
        .map(|kmer| kmer.to_vec())
        .collect();
    Ok(kmers)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn parse_fastq(path: String) -> Result<Vec<FastqRecordNif>, String> {
    cyanea_seq::parse_fastq_file(&path)
        .map(|records| records.into_iter().map(FastqRecordNif::from).collect())
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn fastq_stats(path: String) -> Result<FastqStatsNif, String> {
    cyanea_seq::parse_fastq_stats(&path)
        .map(FastqStatsNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn protein_molecular_weight(data: Vec<u8>) -> Result<f64, String> {
    let seq = cyanea_seq::ProteinSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.molecular_weight())
}

// ===========================================================================
// New NIFs
// ===========================================================================

#[rustler::nif]
pub fn horspool_search(text: Vec<u8>, pattern: Vec<u8>) -> Vec<usize> {
    cyanea_seq::horspool(&text, &pattern)
}

#[rustler::nif]
pub fn myers_search(text: Vec<u8>, pattern: Vec<u8>, max_dist: usize) -> Vec<(usize, usize)> {
    cyanea_seq::myers_bitparallel(&text, &pattern, max_dist)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn fm_index_build(text: Vec<u8>) -> Vec<u8> {
    // Build to validate input, then return the raw text.
    // FmIndex doesn't implement Serialize, so we store the raw text and
    // rebuild the index lazily on each query.
    let _index = cyanea_seq::FmIndex::build(&text);
    text
}

#[rustler::nif]
pub fn fm_index_count(index_data: Vec<u8>, pattern: Vec<u8>) -> usize {
    let index = cyanea_seq::FmIndex::build(&index_data);
    index.count(&pattern)
}

#[rustler::nif]
pub fn find_orfs(seq: Vec<u8>, min_length: usize) -> Vec<OrfResultNif> {
    let results = cyanea_seq::find_orfs_both_strands(&seq, min_length);
    results
        .into_iter()
        .map(|orf| OrfResultNif {
            start: orf.start,
            end: orf.end,
            frame: orf.frame,
            strand: match orf.strand {
                cyanea_seq::Strand::Reverse => "-".into(),
                _ => "+".into(),
            },
            sequence: orf.sequence.clone(),
        })
        .collect()
}

#[rustler::nif]
pub fn minhash_sketch(seq: Vec<u8>, k: usize, sketch_size: usize) -> Result<Vec<u64>, String> {
    let mut mh = cyanea_seq::MinHash::new(k, sketch_size).map_err(to_nif_error)?;
    mh.add_sequence(&seq);
    Ok(mh.hashes().to_vec())
}
