//! Bridge structs — Rustler NifStruct types that map to Elixir structs.
//!
//! Each struct here has a `From` impl to convert from the corresponding
//! Cyanea Labs type.  All `#[module = "..."]` values must match the Elixir
//! `defstruct` module in `native.ex`.

use rustler::NifStruct;

// ── Traits needed for conversions ──────────────────────────────────────────

use cyanea_core::{Annotated, Sequence};

// ===========================================================================
// cyanea-seq
// ===========================================================================

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

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.OrfResult"]
pub struct OrfResultNif {
    pub start: usize,
    pub end: usize,
    pub frame: usize,
    pub strand: String,
    pub sequence: Vec<u8>,
}

// ===========================================================================
// cyanea-io
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

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.VcfRecord"]
pub struct VcfRecordNif {
    pub chrom: String,
    pub position: u64,
    pub ref_allele: String,
    pub alt_alleles: Vec<String>,
    pub quality: Option<f64>,
    pub filter: String,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.BedRecord"]
pub struct BedRecordNif {
    pub chrom: String,
    pub start: u64,
    pub end: u64,
    pub name: Option<String>,
    pub score: Option<f64>,
    pub strand: String,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.GffGene"]
pub struct GffGeneNif {
    pub id: String,
    pub symbol: String,
    pub chrom: String,
    pub start: u64,
    pub end: u64,
    pub strand: String,
    pub gene_type: String,
    pub transcript_count: usize,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.SamRecord"]
pub struct SamRecordNif {
    pub qname: String,
    pub flag: u16,
    pub rname: String,
    pub pos: u64,
    pub mapq: u8,
    pub cigar: String,
    pub sequence: String,
    pub quality: String,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.SamStats"]
pub struct SamStatsNif {
    pub total_reads: usize,
    pub mapped: usize,
    pub unmapped: usize,
    pub avg_mapq: f64,
    pub avg_length: f64,
}

// ===========================================================================
// cyanea-align
// ===========================================================================

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

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.CigarStats"]
pub struct CigarStatsNif {
    pub cigar_string: String,
    pub reference_consumed: usize,
    pub query_consumed: usize,
    pub alignment_columns: usize,
    pub identity: f64,
    pub gap_count: usize,
    pub gap_bases: usize,
    pub soft_clipped: usize,
    pub hard_clipped: usize,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.MsaResult"]
pub struct MsaResultNif {
    pub aligned: Vec<Vec<u8>>,
    pub n_sequences: usize,
    pub n_columns: usize,
    pub conservation: f64,
}

// ===========================================================================
// cyanea-stats
// ===========================================================================

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

// ===========================================================================
// cyanea-omics
// ===========================================================================

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

// ===========================================================================
// cyanea-ml
// ===========================================================================

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

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.UmapResult"]
pub struct UmapResultNif {
    pub embedding: Vec<f64>,
    pub n_samples: usize,
    pub n_components: usize,
    pub n_epochs: usize,
}

impl From<cyanea_ml::UmapResult> for UmapResultNif {
    fn from(r: cyanea_ml::UmapResult) -> Self {
        Self {
            embedding: r.embedding,
            n_samples: r.n_samples,
            n_components: r.n_components,
            n_epochs: r.n_epochs,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.HierarchicalResult"]
pub struct HierarchicalResultNif {
    pub labels: Vec<usize>,
    pub merge_distances: Vec<f64>,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.LinearRegressionResult"]
pub struct LinearRegressionResultNif {
    pub weights: Vec<f64>,
    pub bias: f64,
    pub r_squared: f64,
}

// ===========================================================================
// cyanea-chem
// ===========================================================================

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

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.SdfMolecule"]
pub struct SdfMoleculeNif {
    pub name: String,
    pub atom_count: usize,
    pub bond_count: usize,
    pub formula: String,
    pub weight: f64,
}

// ===========================================================================
// cyanea-struct
// ===========================================================================

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

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.ContactMapResult"]
pub struct ContactMapResultNif {
    pub contacts: Vec<(usize, usize, f64)>,
    pub n_residues: usize,
    pub contact_density: f64,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.SuperpositionResult"]
pub struct SuperpositionResultNif {
    pub rmsd: f64,
    pub rotation: Vec<f64>,
    pub translation: Vec<f64>,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.RamachandranEntry"]
pub struct RamachandranEntryNif {
    pub residue_num: usize,
    pub residue_name: String,
    pub phi: f64,
    pub psi: f64,
    pub region: String,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.BfactorResult"]
pub struct BfactorResultNif {
    pub mean: f64,
    pub std_dev: f64,
    pub min: f64,
    pub max: f64,
    pub per_chain: Vec<(String, f64)>,
}

// ===========================================================================
// cyanea-phylo
// ===========================================================================

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.NewickInfo"]
pub struct NewickInfoNif {
    pub leaf_count: usize,
    pub leaf_names: Vec<String>,
    pub newick: String,
}

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.NexusFile"]
pub struct NexusFileNif {
    pub taxa: Vec<String>,
    pub tree_names: Vec<String>,
    pub tree_newicks: Vec<String>,
}

// ===========================================================================
// cyanea-gpu
// ===========================================================================

#[derive(Debug, NifStruct)]
#[module = "Cyanea.Native.GpuInfo"]
pub struct GpuInfoNif {
    pub available: bool,
    pub backend: String,
}

// ===========================================================================
// Helper: structure_to_pdb_info
// ===========================================================================

pub fn structure_to_pdb_info(s: &cyanea_struct::Structure) -> PdbInfoNif {
    PdbInfoNif {
        id: s.id.clone(),
        chain_count: s.chain_count(),
        residue_count: s.residue_count(),
        atom_count: s.atom_count(),
        chains: s.chains.iter().map(|c| c.id.to_string()).collect(),
    }
}

/// Convert a Fingerprint to a byte vector (Fingerprint.bits is private).
pub fn fingerprint_to_bytes(fp: &cyanea_chem::Fingerprint) -> Vec<u8> {
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
