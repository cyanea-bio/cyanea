//! cyanea-omics NIFs — Variant classification, genomic intervals, expression matrices.

use crate::bridge::*;
use crate::to_nif_error;

#[rustler::nif]
pub fn classify_variant(
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
pub fn merge_genomic_intervals(
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
pub fn genomic_coverage(
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
pub fn expression_summary(
    data: Vec<Vec<f64>>,
    feature_names: Vec<String>,
    sample_names: Vec<String>,
) -> Result<ExpressionSummaryNif, String> {
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
pub fn log_transform_matrix(
    data: Vec<Vec<f64>>,
    pseudocount: f64,
) -> Vec<Vec<f64>> {
    data.iter()
        .map(|row| row.iter().map(|&x| (x + pseudocount).log2()).collect())
        .collect()
}
