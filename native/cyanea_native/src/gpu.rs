//! cyanea-gpu NIFs — GPU backend detection and compute operations.

use crate::bridge::*;
use crate::to_nif_error;

// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif]
pub fn gpu_info() -> GpuInfoNif {
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

// ===========================================================================
// New NIFs
// ===========================================================================

fn parse_gpu_metric(s: &str) -> Result<cyanea_gpu::DistanceMetricGpu, String> {
    match s {
        "euclidean" => Ok(cyanea_gpu::DistanceMetricGpu::Euclidean),
        "manhattan" => Ok(cyanea_gpu::DistanceMetricGpu::Manhattan),
        "cosine" => Ok(cyanea_gpu::DistanceMetricGpu::Cosine),
        _ => Err(format!(
            "unknown distance metric: {s} (expected euclidean, manhattan, or cosine)"
        )),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn gpu_pairwise_distances(
    data: Vec<f64>,
    n: usize,
    dim: usize,
    metric: String,
) -> Result<Vec<f64>, String> {
    let backend = cyanea_gpu::auto_backend();
    let metric = parse_gpu_metric(&metric)?;
    let buf = backend.buffer_from_slice(&data).map_err(to_nif_error)?;
    let result = cyanea_gpu::ops::pairwise_distance_matrix(backend.as_ref(), &buf, n, dim, metric)
        .map_err(to_nif_error)?;
    backend.read_buffer(&result).map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn gpu_matrix_multiply(
    a: Vec<f64>,
    b: Vec<f64>,
    m: usize,
    k: usize,
    n: usize,
) -> Result<Vec<f64>, String> {
    let backend = cyanea_gpu::auto_backend();
    let buf_a = backend.buffer_from_slice(&a).map_err(to_nif_error)?;
    let buf_b = backend.buffer_from_slice(&b).map_err(to_nif_error)?;
    let result = cyanea_gpu::ops::matrix_multiply(backend.as_ref(), &buf_a, &buf_b, m, k, n)
        .map_err(to_nif_error)?;
    backend.read_buffer(&result).map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn gpu_reduce_sum(data: Vec<f64>) -> Result<f64, String> {
    let backend = cyanea_gpu::auto_backend();
    let buf = backend.buffer_from_slice(&data).map_err(to_nif_error)?;
    cyanea_gpu::ops::reduce_sum(backend.as_ref(), &buf).map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn gpu_batch_z_score(
    data: Vec<f64>,
    n_rows: usize,
    n_cols: usize,
) -> Result<Vec<f64>, String> {
    let backend = cyanea_gpu::auto_backend();
    let buf = backend.buffer_from_slice(&data).map_err(to_nif_error)?;
    let result = cyanea_gpu::ops::batch_z_score(backend.as_ref(), &buf, n_rows, n_cols)
        .map_err(to_nif_error)?;
    backend.read_buffer(&result).map_err(to_nif_error)
}
