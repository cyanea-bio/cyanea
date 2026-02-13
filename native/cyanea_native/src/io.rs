//! cyanea-io NIFs — File format parsing (CSV, VCF, BED, GFF3, SAM, BAM).

use crate::bridge::*;
use crate::to_nif_error;

// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif(schedule = "DirtyCpu")]
pub fn csv_info(path: String) -> Result<CsvInfoNif, String> {
    cyanea_io::parse_csv_info(&path)
        .map(CsvInfoNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn csv_preview(path: String, limit: usize) -> Result<String, String> {
    cyanea_io::csv_preview(&path, limit).map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn vcf_stats(path: String) -> Result<VcfStatsNif, String> {
    cyanea_io::vcf_stats(&path)
        .map(VcfStatsNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn bed_stats(path: String) -> Result<BedStatsNif, String> {
    cyanea_io::bed_stats(&path)
        .map(BedStatsNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn gff3_stats(path: String) -> Result<GffStatsNif, String> {
    cyanea_io::gff3_stats(&path)
        .map(GffStatsNif::from)
        .map_err(to_nif_error)
}

// ===========================================================================
// New NIFs
// ===========================================================================

#[rustler::nif(schedule = "DirtyCpu")]
pub fn parse_vcf(path: String) -> Result<Vec<VcfRecordNif>, String> {
    let variants = cyanea_io::parse_vcf(&path).map_err(to_nif_error)?;
    Ok(variants
        .into_iter()
        .map(|v| VcfRecordNif {
            chrom: v.chrom.clone(),
            position: v.position,
            ref_allele: String::from_utf8_lossy(&v.ref_allele).to_string(),
            alt_alleles: v.alt_alleles.iter().map(|a| String::from_utf8_lossy(a).to_string()).collect(),
            quality: v.quality,
            filter: format!("{:?}", v.filter),
        })
        .collect())
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn parse_bed(path: String) -> Result<Vec<BedRecordNif>, String> {
    let records = cyanea_io::parse_bed(&path).map_err(to_nif_error)?;
    Ok(records
        .into_iter()
        .map(|r| BedRecordNif {
            chrom: r.interval.chrom.clone(),
            start: r.interval.start,
            end: r.interval.end,
            name: r.name.clone(),
            score: r.score.map(|s| s as f64),
            strand: format!("{:?}", r.interval.strand),
        })
        .collect())
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn parse_gff3(path: String) -> Result<Vec<GffGeneNif>, String> {
    let genes = cyanea_io::parse_gff3(&path).map_err(to_nif_error)?;
    Ok(genes
        .into_iter()
        .map(|g| GffGeneNif {
            id: g.gene_id.clone(),
            symbol: g.gene_name.clone(),
            chrom: g.chrom.clone(),
            start: g.start,
            end: g.end,
            strand: format!("{:?}", g.strand),
            gene_type: format!("{:?}", g.gene_type),
            transcript_count: g.transcripts.len(),
        })
        .collect())
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn sam_stats(path: String) -> Result<SamStatsNif, String> {
    let records = cyanea_io::parse_sam(&path).map_err(to_nif_error)?;
    let stats = cyanea_io::sam_stats(&records);
    Ok(SamStatsNif {
        total_reads: stats.total_reads,
        mapped: stats.mapped,
        unmapped: stats.unmapped,
        avg_mapq: stats.avg_mapq,
        avg_length: stats.avg_length,
    })
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn bam_stats(path: String) -> Result<SamStatsNif, String> {
    let records = cyanea_io::parse_bam(&path).map_err(to_nif_error)?;
    let stats = cyanea_io::sam_stats(&records);
    Ok(SamStatsNif {
        total_reads: stats.total_reads,
        mapped: stats.mapped,
        unmapped: stats.unmapped,
        avg_mapq: stats.avg_mapq,
        avg_length: stats.avg_length,
    })
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn parse_sam(path: String) -> Result<Vec<SamRecordNif>, String> {
    let records = cyanea_io::parse_sam(&path).map_err(to_nif_error)?;
    Ok(records
        .into_iter()
        .map(|r| SamRecordNif {
            qname: r.qname.clone(),
            flag: r.flag,
            rname: r.rname.clone(),
            pos: r.pos,
            mapq: r.mapq,
            cigar: r.cigar.clone(),
            sequence: r.sequence.clone(),
            quality: r.quality.clone(),
        })
        .collect())
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn parse_bam(path: String) -> Result<Vec<SamRecordNif>, String> {
    let records = cyanea_io::parse_bam(&path).map_err(to_nif_error)?;
    Ok(records
        .into_iter()
        .map(|r| SamRecordNif {
            qname: r.qname.clone(),
            flag: r.flag,
            rname: r.rname.clone(),
            pos: r.pos,
            mapq: r.mapq,
            cigar: r.cigar.clone(),
            sequence: r.sequence.clone(),
            quality: r.quality.clone(),
        })
        .collect())
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn parse_bed_intervals(path: String) -> Result<Vec<GenomicIntervalNif>, String> {
    let records = cyanea_io::parse_bed(&path).map_err(to_nif_error)?;
    Ok(records
        .into_iter()
        .map(|r| GenomicIntervalNif {
            chrom: r.interval.chrom.clone(),
            start: r.interval.start,
            end: r.interval.end,
            strand: format!("{:?}", r.interval.strand),
        })
        .collect())
}
