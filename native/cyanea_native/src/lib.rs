//! Cyanea Native — Thin NIF bridge to Cyanea Labs.
//!
//! This crate exposes Elixir NIFs that delegate to the standalone
//! libraries in `labs/`. No business logic lives here — only type
//! conversions between Rustler NIF types and Cyanea Labs types.

use rustler::NifStruct;

// Import traits needed for FastqRecord field access.
use cyanea_core::{Annotated, Sequence};

rustler::init!("Elixir.Cyanea.Native");

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Convert a `cyanea_core::CyaneaError` into a NIF-friendly `String`.
fn to_nif_error(e: cyanea_core::CyaneaError) -> String {
    e.to_string()
}

fn parse_distance_metric(s: &str) -> Result<cyanea_ml::DistanceMetric, String> {
    match s {
        "euclidean" => Ok(cyanea_ml::DistanceMetric::Euclidean),
        "manhattan" => Ok(cyanea_ml::DistanceMetric::Manhattan),
        "cosine" => Ok(cyanea_ml::DistanceMetric::Cosine),
        _ => Err(format!(
            "unknown distance metric: {s} (expected euclidean, manhattan, or cosine)"
        )),
    }
}

fn parse_alphabet(s: &str) -> Result<cyanea_ml::Alphabet, String> {
    match s {
        "dna" => Ok(cyanea_ml::Alphabet::Dna),
        "rna" => Ok(cyanea_ml::Alphabet::Rna),
        "protein" => Ok(cyanea_ml::Alphabet::Protein),
        _ => Err(format!(
            "unknown alphabet: {s} (expected dna, rna, or protein)"
        )),
    }
}

fn flat_to_slices(data: &[f64], n_features: usize) -> Result<Vec<&[f64]>, String> {
    if n_features == 0 {
        return Err("n_features must be > 0".into());
    }
    if data.len() % n_features != 0 {
        return Err(format!(
            "data length {} is not divisible by n_features {}",
            data.len(),
            n_features
        ));
    }
    Ok(data.chunks(n_features).collect())
}

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

/// Convert a Fingerprint to a byte vector (Fingerprint.bits is private).
fn fingerprint_to_bytes(fp: &cyanea_chem::Fingerprint) -> Vec<u8> {
    let nbits = fp.nbits();
    let nbytes = (nbits + 7) / 8;
    let mut bytes = vec![0u8; nbytes];
    for i in 0..nbits {
        if fp.get_bit(i) {
            bytes[i / 8] |= 1 << (i % 8);
        }
    }
    bytes
}

// ===========================================================================
// cyanea-core — Hashing & Compression
// ===========================================================================

#[rustler::nif]
fn sha256(data: Vec<u8>) -> String {
    cyanea_core::hash::sha256(&data)
}

#[rustler::nif]
fn sha256_file(path: String) -> Result<String, String> {
    cyanea_core::hash::sha256_file(&path).map_err(to_nif_error)
}

#[rustler::nif]
fn zstd_compress(data: Vec<u8>, level: i32) -> Result<Vec<u8>, String> {
    cyanea_core::compress::zstd_compress(&data, level).map_err(to_nif_error)
}

#[rustler::nif]
fn zstd_decompress(data: Vec<u8>) -> Result<Vec<u8>, String> {
    cyanea_core::compress::zstd_decompress(&data).map_err(to_nif_error)
}

// ===========================================================================
// cyanea-seq — Sequence I/O
// ===========================================================================

// --- Bridge structs --------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.FastaStats"]
pub struct FastaStatsNif {
    pub sequence_count: u64,
    pub total_bases: u64,
    pub gc_content: f64,
    pub avg_length: f64,
}

impl From<cyanea_seq::FastaStats> for FastaStatsNif {
    fn from(s: cyanea_seq::FastaStats) -> Self {
        Self {
            sequence_count: s.sequence_count,
            total_bases: s.total_bases,
            gc_content: s.gc_content,
            avg_length: s.avg_length,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.FastqRecord"]
pub struct FastqRecordNif {
    pub name: String,
    pub description: String,
    pub sequence: Vec<u8>,
    pub quality: Vec<u8>,
}

impl From<cyanea_seq::FastqRecord> for FastqRecordNif {
    fn from(r: cyanea_seq::FastqRecord) -> Self {
        let name = r.name().to_string();
        let description = r.description().unwrap_or("").to_string();
        let quality = r.quality().as_slice().to_vec();
        let sequence = r.sequence().as_bytes().to_vec();
        Self {
            name,
            description,
            sequence,
            quality,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.FastqStats"]
pub struct FastqStatsNif {
    pub sequence_count: u64,
    pub total_bases: u64,
    pub gc_content: f64,
    pub avg_length: f64,
    pub mean_quality: f64,
    pub q20_fraction: f64,
    pub q30_fraction: f64,
}

impl From<cyanea_seq::FastqStats> for FastqStatsNif {
    fn from(s: cyanea_seq::FastqStats) -> Self {
        Self {
            sequence_count: s.sequence_count,
            total_bases: s.total_bases,
            gc_content: s.gc_content,
            avg_length: s.avg_length,
            mean_quality: s.mean_quality,
            q20_fraction: s.q20_fraction,
            q30_fraction: s.q30_fraction,
        }
    }
}

// --- FASTA -----------------------------------------------------------------

#[rustler::nif(schedule = "DirtyCpu")]
fn fasta_stats(path: String) -> Result<FastaStatsNif, String> {
    cyanea_seq::parse_fasta_stats(&path)
        .map(FastaStatsNif::from)
        .map_err(to_nif_error)
}

// --- Sequence validation ---------------------------------------------------

#[rustler::nif]
fn validate_dna(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.into_bytes())
}

#[rustler::nif]
fn validate_rna(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::RnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.into_bytes())
}

#[rustler::nif]
fn validate_protein(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::ProteinSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.into_bytes())
}

// --- DNA operations --------------------------------------------------------

#[rustler::nif]
fn dna_reverse_complement(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.reverse_complement().into_bytes())
}

#[rustler::nif]
fn dna_transcribe(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.transcribe().into_bytes())
}

#[rustler::nif]
fn dna_gc_content(data: Vec<u8>) -> Result<f64, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.gc_content())
}

// --- RNA operations --------------------------------------------------------

#[rustler::nif]
fn rna_translate(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let seq = cyanea_seq::RnaSequence::new(&data).map_err(to_nif_error)?;
    seq.translate()
        .map(|p| p.into_bytes())
        .map_err(to_nif_error)
}

// --- K-mers ----------------------------------------------------------------

#[rustler::nif]
fn sequence_kmers(data: Vec<u8>, k: usize) -> Result<Vec<Vec<u8>>, String> {
    let seq = cyanea_seq::DnaSequence::new(&data).map_err(to_nif_error)?;
    let kmers = seq
        .kmers(k)
        .map_err(to_nif_error)?
        .map(|kmer| kmer.to_vec())
        .collect();
    Ok(kmers)
}

// --- FASTQ -----------------------------------------------------------------

#[rustler::nif(schedule = "DirtyCpu")]
fn parse_fastq(path: String) -> Result<Vec<FastqRecordNif>, String> {
    cyanea_seq::parse_fastq_file(&path)
        .map(|records| records.into_iter().map(FastqRecordNif::from).collect())
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn fastq_stats(path: String) -> Result<FastqStatsNif, String> {
    cyanea_seq::parse_fastq_stats(&path)
        .map(FastqStatsNif::from)
        .map_err(to_nif_error)
}

// --- Protein ---------------------------------------------------------------

#[rustler::nif]
fn protein_molecular_weight(data: Vec<u8>) -> Result<f64, String> {
    let seq = cyanea_seq::ProteinSequence::new(&data).map_err(to_nif_error)?;
    Ok(seq.molecular_weight())
}

// ===========================================================================
// cyanea-io — File Format Parsing
// ===========================================================================

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.CsvInfo"]
pub struct CsvInfoNif {
    pub row_count: u64,
    pub column_count: usize,
    pub columns: Vec<String>,
    pub has_headers: bool,
}

impl From<cyanea_io::CsvInfo> for CsvInfoNif {
    fn from(c: cyanea_io::CsvInfo) -> Self {
        Self {
            row_count: c.row_count,
            column_count: c.column_count,
            columns: c.columns,
            has_headers: c.has_headers,
        }
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn csv_info(path: String) -> Result<CsvInfoNif, String> {
    cyanea_io::parse_csv_info(&path)
        .map(CsvInfoNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn csv_preview(path: String, limit: usize) -> Result<String, String> {
    cyanea_io::csv_preview(&path, limit).map_err(to_nif_error)
}

// --- VCF -------------------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.VcfStats"]
pub struct VcfStatsNif {
    pub variant_count: u64,
    pub snv_count: u64,
    pub indel_count: u64,
    pub pass_count: u64,
    pub chromosomes: Vec<String>,
}

impl From<cyanea_io::VcfStats> for VcfStatsNif {
    fn from(s: cyanea_io::VcfStats) -> Self {
        Self {
            variant_count: s.variant_count,
            snv_count: s.snv_count,
            indel_count: s.indel_count,
            pass_count: s.pass_count,
            chromosomes: s.chromosomes,
        }
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn vcf_stats(path: String) -> Result<VcfStatsNif, String> {
    cyanea_io::vcf_stats(&path)
        .map(VcfStatsNif::from)
        .map_err(to_nif_error)
}

// --- BED -------------------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.BedStats"]
pub struct BedStatsNif {
    pub record_count: u64,
    pub total_bases: u64,
    pub chromosomes: Vec<String>,
}

impl From<cyanea_io::BedStats> for BedStatsNif {
    fn from(s: cyanea_io::BedStats) -> Self {
        Self {
            record_count: s.record_count,
            total_bases: s.total_bases,
            chromosomes: s.chromosomes,
        }
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn bed_stats(path: String) -> Result<BedStatsNif, String> {
    cyanea_io::bed_stats(&path)
        .map(BedStatsNif::from)
        .map_err(to_nif_error)
}

// --- GFF3 ------------------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.GffStats"]
pub struct GffStatsNif {
    pub gene_count: u64,
    pub transcript_count: u64,
    pub exon_count: u64,
    pub protein_coding_count: u64,
    pub chromosomes: Vec<String>,
}

impl From<cyanea_io::GffStats> for GffStatsNif {
    fn from(s: cyanea_io::GffStats) -> Self {
        Self {
            gene_count: s.gene_count,
            transcript_count: s.transcript_count,
            exon_count: s.exon_count,
            protein_coding_count: s.protein_coding_count,
            chromosomes: s.chromosomes,
        }
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn gff3_stats(path: String) -> Result<GffStatsNif, String> {
    cyanea_io::gff3_stats(&path)
        .map(GffStatsNif::from)
        .map_err(to_nif_error)
}

// ===========================================================================
// cyanea-align — Sequence Alignment
// ===========================================================================

// --- Bridge structs --------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.AlignmentResult"]
pub struct AlignmentResultNif {
    pub score: i32,
    pub aligned_query: Vec<u8>,
    pub aligned_target: Vec<u8>,
    pub query_start: usize,
    pub query_end: usize,
    pub target_start: usize,
    pub target_end: usize,
    pub cigar: String,
    pub identity: f64,
    pub num_matches: usize,
    pub num_mismatches: usize,
    pub num_gaps: usize,
    pub alignment_length: usize,
}

impl From<cyanea_align::AlignmentResult> for AlignmentResultNif {
    fn from(r: cyanea_align::AlignmentResult) -> Self {
        Self {
            score: r.score,
            aligned_query: r.aligned_query.clone(),
            aligned_target: r.aligned_target.clone(),
            query_start: r.query_start,
            query_end: r.query_end,
            target_start: r.target_start,
            target_end: r.target_end,
            cigar: r.cigar_string(),
            identity: r.identity(),
            num_matches: r.matches(),
            num_mismatches: r.mismatches(),
            num_gaps: r.gaps(),
            alignment_length: r.length(),
        }
    }
}

// --- Helpers ---------------------------------------------------------------

fn parse_alignment_mode(mode: &str) -> Result<cyanea_align::AlignmentMode, String> {
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

// --- NIFs ------------------------------------------------------------------

#[rustler::nif]
fn align_dna(query: Vec<u8>, target: Vec<u8>, mode: String) -> Result<AlignmentResultNif, String> {
    let mode = parse_alignment_mode(&mode)?;
    let scoring = cyanea_align::ScoringScheme::Simple(cyanea_align::ScoringMatrix::dna_default());
    cyanea_align::align(&query, &target, mode, &scoring)
        .map(AlignmentResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
fn align_dna_custom(
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
fn align_protein(
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
fn align_batch_dna(
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

// --- MSA -------------------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.MsaResult"]
pub struct MsaResultNif {
    pub aligned: Vec<Vec<u8>>,
    pub n_sequences: usize,
    pub n_columns: usize,
    pub conservation: f64,
}

#[rustler::nif(schedule = "DirtyCpu")]
fn progressive_msa(sequences: Vec<Vec<u8>>, mode: String) -> Result<MsaResultNif, String> {
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
// cyanea-stats — Statistical Methods
// ===========================================================================

// --- Bridge structs --------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.DescriptiveStats"]
pub struct DescriptiveStatsNif {
    pub count: usize,
    pub mean: f64,
    pub median: f64,
    pub variance: f64,
    pub sample_variance: f64,
    pub std_dev: f64,
    pub sample_std_dev: f64,
    pub min: f64,
    pub max: f64,
    pub range: f64,
    pub q1: f64,
    pub q3: f64,
    pub iqr: f64,
    pub skewness: f64,
    pub kurtosis: f64,
}

impl From<cyanea_stats::DescriptiveStats> for DescriptiveStatsNif {
    fn from(s: cyanea_stats::DescriptiveStats) -> Self {
        Self {
            count: s.count,
            mean: s.mean,
            median: s.median,
            variance: s.variance,
            sample_variance: s.sample_variance,
            std_dev: s.std_dev,
            sample_std_dev: s.sample_std_dev,
            min: s.min,
            max: s.max,
            range: s.range,
            q1: s.q1,
            q3: s.q3,
            iqr: s.iqr,
            skewness: s.skewness,
            kurtosis: s.kurtosis,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.TestResult"]
pub struct TestResultNif {
    pub statistic: f64,
    pub p_value: f64,
    pub degrees_of_freedom: Option<f64>,
    pub method: String,
}

impl From<cyanea_stats::TestResult> for TestResultNif {
    fn from(r: cyanea_stats::TestResult) -> Self {
        Self {
            statistic: r.statistic,
            p_value: r.p_value,
            degrees_of_freedom: r.degrees_of_freedom,
            method: r.method,
        }
    }
}

// --- NIFs ------------------------------------------------------------------

#[rustler::nif]
fn descriptive_stats(data: Vec<f64>) -> Result<DescriptiveStatsNif, String> {
    cyanea_stats::descriptive::describe(&data)
        .map(DescriptiveStatsNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
fn pearson_correlation(x: Vec<f64>, y: Vec<f64>) -> Result<f64, String> {
    cyanea_stats::correlation::pearson(&x, &y).map_err(to_nif_error)
}

#[rustler::nif]
fn spearman_correlation(x: Vec<f64>, y: Vec<f64>) -> Result<f64, String> {
    cyanea_stats::correlation::spearman(&x, &y).map_err(to_nif_error)
}

#[rustler::nif]
fn t_test_one_sample(data: Vec<f64>, mu: f64) -> Result<TestResultNif, String> {
    cyanea_stats::testing::t_test_one_sample(&data, mu)
        .map(TestResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
fn t_test_two_sample(x: Vec<f64>, y: Vec<f64>, equal_var: bool) -> Result<TestResultNif, String> {
    cyanea_stats::testing::t_test_two_sample(&x, &y, equal_var)
        .map(TestResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
fn mann_whitney_u(x: Vec<f64>, y: Vec<f64>) -> Result<TestResultNif, String> {
    cyanea_stats::testing::mann_whitney_u(&x, &y)
        .map(TestResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
fn p_adjust_bonferroni(p_values: Vec<f64>) -> Result<Vec<f64>, String> {
    cyanea_stats::correction::bonferroni(&p_values).map_err(to_nif_error)
}

#[rustler::nif]
fn p_adjust_bh(p_values: Vec<f64>) -> Result<Vec<f64>, String> {
    cyanea_stats::correction::benjamini_hochberg(&p_values).map_err(to_nif_error)
}

// ===========================================================================
// cyanea-omics — Omics Data Structures
// ===========================================================================

// --- Bridge structs --------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.VariantClassification"]
pub struct VariantClassificationNif {
    pub chrom: String,
    pub position: u64,
    pub variant_type: String,
    pub is_snv: bool,
    pub is_indel: bool,
    pub is_transition: bool,
    pub is_transversion: bool,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.GenomicInterval"]
pub struct GenomicIntervalNif {
    pub chrom: String,
    pub start: u64,
    pub end: u64,
    pub strand: String,
}

impl From<cyanea_omics::GenomicInterval> for GenomicIntervalNif {
    fn from(iv: cyanea_omics::GenomicInterval) -> Self {
        Self {
            chrom: iv.chrom.clone(),
            start: iv.start,
            end: iv.end,
            strand: iv.strand.to_string(),
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.ExpressionSummary"]
pub struct ExpressionSummaryNif {
    pub n_features: usize,
    pub n_samples: usize,
    pub feature_names: Vec<String>,
    pub sample_names: Vec<String>,
    pub feature_means: Vec<f64>,
    pub sample_means: Vec<f64>,
}

// --- NIFs ------------------------------------------------------------------

#[rustler::nif]
fn classify_variant(
    chrom: String,
    position: u64,
    ref_allele: Vec<u8>,
    alt_alleles: Vec<Vec<u8>>,
) -> Result<VariantClassificationNif, String> {
    let variant = cyanea_omics::Variant::new(chrom, position, ref_allele, alt_alleles)
        .map_err(to_nif_error)?;
    let vtype = variant.variant_type();
    Ok(VariantClassificationNif {
        chrom: variant.chrom.clone(),
        position: variant.position,
        variant_type: format!("{:?}", vtype),
        is_snv: variant.is_snv(),
        is_indel: variant.is_indel(),
        is_transition: variant.is_transition(),
        is_transversion: variant.is_transversion(),
    })
}

#[rustler::nif]
fn merge_genomic_intervals(
    chroms: Vec<String>,
    starts: Vec<u64>,
    ends: Vec<u64>,
) -> Result<Vec<GenomicIntervalNif>, String> {
    if chroms.len() != starts.len() || chroms.len() != ends.len() {
        return Err("chroms, starts, and ends must have equal length".into());
    }
    let mut intervals = Vec::with_capacity(chroms.len());
    for i in 0..chroms.len() {
        let iv = cyanea_omics::GenomicInterval::new(&chroms[i], starts[i], ends[i])
            .map_err(to_nif_error)?;
        intervals.push(iv);
    }
    let set = cyanea_omics::IntervalSet::from_intervals(intervals);
    let merged = set.merge_overlapping();
    Ok(merged.into_intervals().into_iter().map(GenomicIntervalNif::from).collect())
}

#[rustler::nif]
fn genomic_coverage(
    chroms: Vec<String>,
    starts: Vec<u64>,
    ends: Vec<u64>,
    query_chrom: String,
) -> Result<u64, String> {
    if chroms.len() != starts.len() || chroms.len() != ends.len() {
        return Err("chroms, starts, and ends must have equal length".into());
    }
    let mut intervals = Vec::with_capacity(chroms.len());
    for i in 0..chroms.len() {
        let iv = cyanea_omics::GenomicInterval::new(&chroms[i], starts[i], ends[i])
            .map_err(to_nif_error)?;
        intervals.push(iv);
    }
    let set = cyanea_omics::IntervalSet::from_intervals(intervals);
    Ok(set.coverage(&query_chrom))
}

#[rustler::nif]
fn expression_summary(
    data: Vec<Vec<f64>>,
    feature_names: Vec<String>,
    sample_names: Vec<String>,
) -> Result<ExpressionSummaryNif, String> {
    // Capture names before they're moved into the matrix constructor.
    let feat_names = feature_names.clone();
    let samp_names = sample_names.clone();
    let matrix = cyanea_omics::ExpressionMatrix::new(data, feature_names, sample_names)
        .map_err(to_nif_error)?;
    let (n_features, n_samples) = matrix.shape();
    let feature_means: Vec<f64> = (0..n_features)
        .map(|i| matrix.row_mean(i).unwrap_or(0.0))
        .collect();
    let sample_means: Vec<f64> = (0..n_samples)
        .map(|i| matrix.column_mean(i).unwrap_or(0.0))
        .collect();
    Ok(ExpressionSummaryNif {
        n_features,
        n_samples,
        feature_names: feat_names,
        sample_names: samp_names,
        feature_means,
        sample_means,
    })
}

#[rustler::nif]
fn log_transform_matrix(
    data: Vec<Vec<f64>>,
    pseudocount: f64,
) -> Result<Vec<Vec<f64>>, String> {
    Ok(data
        .iter()
        .map(|row| row.iter().map(|&x| (x + pseudocount).log2()).collect())
        .collect())
}

// ===========================================================================
// cyanea-ml — ML Primitives
// ===========================================================================

// --- Bridge structs --------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.KMeansResult"]
pub struct KMeansResultNif {
    pub labels: Vec<usize>,
    pub centroids: Vec<f64>,
    pub n_features: usize,
    pub inertia: f64,
    pub n_iter: usize,
}

impl From<cyanea_ml::KMeansResult> for KMeansResultNif {
    fn from(r: cyanea_ml::KMeansResult) -> Self {
        Self {
            labels: r.labels,
            centroids: r.centroids,
            n_features: r.n_features,
            inertia: r.inertia,
            n_iter: r.n_iter,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.DbscanResult"]
pub struct DbscanResultNif {
    pub labels: Vec<i32>,
    pub n_clusters: usize,
}

impl From<cyanea_ml::DbscanResult> for DbscanResultNif {
    fn from(r: cyanea_ml::DbscanResult) -> Self {
        Self {
            labels: r.labels,
            n_clusters: r.n_clusters,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.PcaResult"]
pub struct PcaResultNif {
    pub transformed: Vec<f64>,
    pub explained_variance: Vec<f64>,
    pub explained_variance_ratio: Vec<f64>,
    pub components: Vec<f64>,
    pub n_components: usize,
    pub n_features: usize,
}

impl From<cyanea_ml::PcaResult> for PcaResultNif {
    fn from(r: cyanea_ml::PcaResult) -> Self {
        Self {
            transformed: r.transformed,
            explained_variance: r.explained_variance,
            explained_variance_ratio: r.explained_variance_ratio,
            components: r.components,
            n_components: r.n_components,
            n_features: r.n_features,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.TsneResult"]
pub struct TsneResultNif {
    pub embedding: Vec<f64>,
    pub n_samples: usize,
    pub n_components: usize,
    pub kl_divergence: f64,
}

impl From<cyanea_ml::TsneResult> for TsneResultNif {
    fn from(r: cyanea_ml::TsneResult) -> Self {
        Self {
            embedding: r.embedding,
            n_samples: r.n_samples,
            n_components: r.n_components,
            kl_divergence: r.kl_divergence,
        }
    }
}

// --- NIFs ------------------------------------------------------------------

#[rustler::nif(schedule = "DirtyCpu")]
fn kmeans(
    data: Vec<f64>,
    n_features: usize,
    k: usize,
    max_iter: usize,
    seed: u64,
) -> Result<KMeansResultNif, String> {
    let slices = flat_to_slices(&data, n_features)?;
    let config = cyanea_ml::KMeansConfig {
        n_clusters: k,
        max_iter,
        tolerance: 1e-4,
        seed,
    };
    cyanea_ml::kmeans(&slices, &config)
        .map(KMeansResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn dbscan(
    data: Vec<f64>,
    n_features: usize,
    eps: f64,
    min_samples: usize,
    metric: String,
) -> Result<DbscanResultNif, String> {
    let slices = flat_to_slices(&data, n_features)?;
    let metric = parse_distance_metric(&metric)?;
    let config = cyanea_ml::DbscanConfig {
        eps,
        min_samples,
        metric,
    };
    cyanea_ml::dbscan(&slices, &config)
        .map(DbscanResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn pca(
    data: Vec<f64>,
    n_features: usize,
    n_components: usize,
) -> Result<PcaResultNif, String> {
    let config = cyanea_ml::PcaConfig {
        n_components,
        max_iter: 100,
        tolerance: 1e-6,
    };
    cyanea_ml::pca(&data, n_features, &config)
        .map(PcaResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn tsne(
    data: Vec<f64>,
    n_features: usize,
    n_components: usize,
    perplexity: f64,
    n_iter: usize,
) -> Result<TsneResultNif, String> {
    let config = cyanea_ml::TsneConfig {
        n_components,
        perplexity,
        learning_rate: 200.0,
        n_iter,
        seed: 42,
    };
    cyanea_ml::tsne(&data, n_features, &config)
        .map(TsneResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
fn kmer_embedding(sequence: Vec<u8>, k: usize, alphabet: String) -> Result<Vec<f64>, String> {
    let alphabet = parse_alphabet(&alphabet)?;
    let config = cyanea_ml::embedding::EmbeddingConfig {
        k,
        alphabet,
        normalize: true,
    };
    cyanea_ml::embedding::kmer_embedding(&sequence, &config)
        .map(|e| e.vector)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn batch_embed(
    sequences: Vec<Vec<u8>>,
    k: usize,
    alphabet: String,
) -> Result<Vec<Vec<f64>>, String> {
    let alphabet = parse_alphabet(&alphabet)?;
    let config = cyanea_ml::embedding::EmbeddingConfig {
        k,
        alphabet,
        normalize: true,
    };
    let refs: Vec<&[u8]> = sequences.iter().map(|s| s.as_slice()).collect();
    cyanea_ml::embedding::batch_embed(&refs, &config)
        .map(|embeddings| embeddings.into_iter().map(|e| e.vector).collect())
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn pairwise_distances(
    data: Vec<f64>,
    n_features: usize,
    metric: String,
) -> Result<Vec<f64>, String> {
    let slices = flat_to_slices(&data, n_features)?;
    let metric = parse_distance_metric(&metric)?;
    cyanea_ml::pairwise_distances(&slices, metric)
        .map(|dm| dm.condensed().to_vec())
        .map_err(to_nif_error)
}

// ===========================================================================
// cyanea-chem — Chemistry / Small Molecules
// ===========================================================================

// --- Bridge structs --------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.MolecularProperties"]
pub struct MolecularPropertiesNif {
    pub formula: String,
    pub weight: f64,
    pub exact_mass: f64,
    pub hbd: usize,
    pub hba: usize,
    pub rotatable_bonds: usize,
    pub ring_count: usize,
    pub aromatic_ring_count: usize,
    pub atom_count: usize,
    pub bond_count: usize,
}

// --- NIFs ------------------------------------------------------------------

#[rustler::nif]
fn smiles_properties(smiles: String) -> Result<MolecularPropertiesNif, String> {
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
fn smiles_fingerprint(
    smiles: String,
    radius: usize,
    nbits: usize,
) -> Result<Vec<u8>, String> {
    let mol = cyanea_chem::parse_smiles(&smiles).map_err(to_nif_error)?;
    let fp = cyanea_chem::morgan_fingerprint(&mol, radius, nbits);
    Ok(fingerprint_to_bytes(&fp))
}

#[rustler::nif]
fn tanimoto(
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
fn smiles_substructure(target: String, pattern: String) -> Result<bool, String> {
    let target_mol = cyanea_chem::parse_smiles(&target).map_err(to_nif_error)?;
    let pattern_mol = cyanea_chem::parse_smiles(&pattern).map_err(to_nif_error)?;
    Ok(cyanea_chem::has_substructure(&target_mol, &pattern_mol))
}

// ===========================================================================
// cyanea-struct — 3D Structures
// ===========================================================================

// --- Bridge structs --------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.PdbInfo"]
pub struct PdbInfoNif {
    pub id: String,
    pub chain_count: usize,
    pub residue_count: usize,
    pub atom_count: usize,
    pub chains: Vec<String>,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.SecondaryStructure"]
pub struct SecondaryStructureNif {
    pub assignments: Vec<String>,
    pub helix_fraction: f64,
    pub sheet_fraction: f64,
    pub coil_fraction: f64,
}

fn structure_to_pdb_info(s: &cyanea_struct::Structure) -> PdbInfoNif {
    PdbInfoNif {
        id: s.id.clone(),
        chain_count: s.chain_count(),
        residue_count: s.residue_count(),
        atom_count: s.atom_count(),
        chains: s.chains.iter().map(|c| c.id.to_string()).collect(),
    }
}

// --- NIFs ------------------------------------------------------------------

#[rustler::nif]
fn pdb_info(pdb_text: String) -> Result<PdbInfoNif, String> {
    let structure = cyanea_struct::parse_pdb(&pdb_text).map_err(to_nif_error)?;
    Ok(structure_to_pdb_info(&structure))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn pdb_file_info(path: String) -> Result<PdbInfoNif, String> {
    let contents = std::fs::read_to_string(&path).map_err(|e| e.to_string())?;
    let structure = cyanea_struct::parse_pdb(&contents).map_err(to_nif_error)?;
    Ok(structure_to_pdb_info(&structure))
}

#[rustler::nif]
fn pdb_secondary_structure(
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
fn pdb_rmsd(
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
// cyanea-phylo — Phylogenetics
// ===========================================================================

// --- Bridge structs --------------------------------------------------------

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.NewickInfo"]
pub struct NewickInfoNif {
    pub leaf_count: usize,
    pub leaf_names: Vec<String>,
    pub newick: String,
}

// --- NIFs ------------------------------------------------------------------

#[rustler::nif]
fn newick_info(newick: String) -> Result<NewickInfoNif, String> {
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
fn newick_robinson_foulds(newick_a: String, newick_b: String) -> Result<usize, String> {
    let tree_a = cyanea_phylo::parse_newick(&newick_a).map_err(to_nif_error)?;
    let tree_b = cyanea_phylo::parse_newick(&newick_b).map_err(to_nif_error)?;
    cyanea_phylo::robinson_foulds(&tree_a, &tree_b).map_err(to_nif_error)
}

#[rustler::nif]
fn evolutionary_distance(
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
fn build_upgma(
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
fn build_nj(
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
// cyanea-gpu — GPU Compute
// ===========================================================================

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.GpuInfo"]
pub struct GpuInfoNif {
    pub available: bool,
    pub backend: String,
}

#[rustler::nif]
fn gpu_info() -> GpuInfoNif {
    let backend = cyanea_gpu::auto_backend();
    let info = backend.device_info();
    GpuInfoNif {
        available: !matches!(info.kind, cyanea_gpu::BackendKind::Cpu),
        backend: match info.kind {
            cyanea_gpu::BackendKind::Cpu => "cpu".to_string(),
            cyanea_gpu::BackendKind::Cuda => "cuda".to_string(),
            cyanea_gpu::BackendKind::Metal => "metal".to_string(),
        },
    }
}
