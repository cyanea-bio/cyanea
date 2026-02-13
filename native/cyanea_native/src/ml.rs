//! cyanea-ml NIFs — Clustering, PCA, t-SNE, UMAP, embeddings, distances, KNN, regression, HMM.

use crate::bridge::*;
use crate::to_nif_error;

// ===========================================================================
// Helpers
// ===========================================================================

pub(crate) fn parse_distance_metric(s: &str) -> Result<cyanea_ml::DistanceMetric, String> {
    match s {
        "euclidean" => Ok(cyanea_ml::DistanceMetric::Euclidean),
        "manhattan" => Ok(cyanea_ml::DistanceMetric::Manhattan),
        "cosine" => Ok(cyanea_ml::DistanceMetric::Cosine),
        _ => Err(format!(
            "unknown distance metric: {s} (expected euclidean, manhattan, or cosine)"
        )),
    }
}

pub(crate) fn parse_alphabet(s: &str) -> Result<cyanea_ml::Alphabet, String> {
    match s {
        "dna" => Ok(cyanea_ml::Alphabet::Dna),
        "rna" => Ok(cyanea_ml::Alphabet::Rna),
        "protein" => Ok(cyanea_ml::Alphabet::Protein),
        _ => Err(format!(
            "unknown alphabet: {s} (expected dna, rna, or protein)"
        )),
    }
}

pub(crate) fn flat_to_slices(data: &[f64], n_features: usize) -> Result<Vec<&[f64]>, String> {
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

fn parse_linkage(s: &str) -> Result<cyanea_ml::Linkage, String> {
    match s {
        "single" => Ok(cyanea_ml::Linkage::Single),
        "complete" => Ok(cyanea_ml::Linkage::Complete),
        "average" => Ok(cyanea_ml::Linkage::Average),
        "ward" => Ok(cyanea_ml::Linkage::Ward),
        _ => Err(format!(
            "unknown linkage: {s} (expected single, complete, average, or ward)"
        )),
    }
}

// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif(schedule = "DirtyCpu")]
pub fn kmeans(
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
pub fn dbscan(
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
pub fn pca(
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
pub fn tsne(
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

#[rustler::nif(schedule = "DirtyCpu")]
pub fn umap(
    data: Vec<f64>,
    n_features: usize,
    n_components: usize,
    n_neighbors: usize,
    min_dist: f64,
    n_epochs: usize,
    metric: String,
    seed: u64,
) -> Result<UmapResultNif, String> {
    let metric = parse_distance_metric(&metric)?;
    let config = cyanea_ml::UmapConfig {
        n_components,
        n_neighbors,
        min_dist,
        n_epochs,
        metric,
        seed,
        ..Default::default()
    };
    cyanea_ml::umap(&data, n_features, &config)
        .map(UmapResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn kmer_embedding(sequence: Vec<u8>, k: usize, alphabet: String) -> Result<Vec<f64>, String> {
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
pub fn batch_embed(
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
pub fn pairwise_distances(
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
// New NIFs
// ===========================================================================

#[rustler::nif(schedule = "DirtyCpu")]
pub fn hierarchical_cluster(
    data: Vec<f64>,
    n_features: usize,
    n_clusters: usize,
    linkage: String,
    metric: String,
) -> Result<HierarchicalResultNif, String> {
    let slices = flat_to_slices(&data, n_features)?;
    let linkage = parse_linkage(&linkage)?;
    let metric = parse_distance_metric(&metric)?;
    let dm = cyanea_ml::pairwise_distances(&slices, metric).map_err(to_nif_error)?;
    let config = cyanea_ml::HierarchicalConfig {
        n_clusters,
        linkage,
    };
    let result = cyanea_ml::hierarchical(&dm, &config).map_err(to_nif_error)?;
    Ok(HierarchicalResultNif {
        labels: result.labels,
        merge_distances: result.merge_history.iter().map(|step| step.distance).collect(),
    })
}

#[rustler::nif]
pub fn knn_classify(
    data: Vec<f64>,
    n_features: usize,
    k: usize,
    metric: String,
    labels: Vec<i32>,
    query: Vec<f64>,
) -> Result<i32, String> {
    let metric = parse_distance_metric(&metric)?;
    let config = cyanea_ml::KnnConfig { k, metric };
    let knn = cyanea_ml::KnnModel::fit(&data, n_features, config).map_err(to_nif_error)?;
    knn.classify(&query, &labels).map_err(to_nif_error)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn linear_regression_fit(
    data: Vec<f64>,
    n_features: usize,
    targets: Vec<f64>,
) -> Result<LinearRegressionResultNif, String> {
    let model = cyanea_ml::LinearRegression::fit(&data, n_features, &targets).map_err(to_nif_error)?;
    Ok(LinearRegressionResultNif {
        weights: model.weights.clone(),
        bias: model.bias,
        r_squared: model.r_squared,
    })
}

#[rustler::nif]
pub fn linear_regression_predict(
    weights: Vec<f64>,
    bias: f64,
    queries: Vec<f64>,
    n_features: usize,
) -> Result<Vec<f64>, String> {
    let query_slices = flat_to_slices(&queries, n_features)?;
    let predictions: Vec<f64> = query_slices
        .iter()
        .map(|q| {
            q.iter().zip(weights.iter()).map(|(x, w)| x * w).sum::<f64>() + bias
        })
        .collect();
    Ok(predictions)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn random_forest_fit(
    data: Vec<f64>,
    n_features: usize,
    labels: Vec<usize>,
    n_trees: usize,
    max_depth: usize,
    seed: u64,
) -> Result<Vec<u8>, String> {
    let config = cyanea_ml::RandomForestConfig {
        n_trees,
        max_depth,
        seed,
        ..Default::default()
    };
    let _model = cyanea_ml::RandomForest::fit(&data, n_features, &labels, &config).map_err(to_nif_error)?;
    // RandomForest doesn't implement Serialize. Serialize the training state
    // so predict can re-train (not ideal but avoids needing serde on the model).
    let state = (data, n_features, labels, n_trees, max_depth, seed);
    bincode::serialize(&state).map_err(|e| e.to_string())
}

#[rustler::nif]
pub fn random_forest_predict(
    model_data: Vec<u8>,
    sample: Vec<f64>,
    _n_features: usize,
) -> Result<usize, String> {
    let (data, n_features, labels, n_trees, max_depth, seed): (Vec<f64>, usize, Vec<usize>, usize, usize, u64) =
        bincode::deserialize(&model_data).map_err(|e| e.to_string())?;
    let config = cyanea_ml::RandomForestConfig {
        n_trees,
        max_depth,
        seed,
        ..Default::default()
    };
    let model = cyanea_ml::RandomForest::fit(&data, n_features, &labels, &config)
        .map_err(to_nif_error)?;
    Ok(model.predict(&sample))
}

#[rustler::nif]
pub fn hmm_viterbi(
    n_states: usize,
    n_symbols: usize,
    initial: Vec<f64>,
    transition: Vec<f64>,
    emission: Vec<f64>,
    observations: Vec<usize>,
) -> Result<(Vec<usize>, f64), String> {
    let hmm = cyanea_ml::HmmModel::new(
        n_states,
        n_symbols,
        initial,
        transition,
        emission,
    )
    .map_err(to_nif_error)?;
    hmm.viterbi(&observations).map_err(to_nif_error)
}

#[rustler::nif]
pub fn hmm_forward(
    n_states: usize,
    n_symbols: usize,
    initial: Vec<f64>,
    transition: Vec<f64>,
    emission: Vec<f64>,
    observations: Vec<usize>,
) -> Result<f64, String> {
    let hmm = cyanea_ml::HmmModel::new(
        n_states,
        n_symbols,
        initial,
        transition,
        emission,
    )
    .map_err(to_nif_error)?;
    let (_, log_prob) = hmm.forward(&observations).map_err(to_nif_error)?;
    Ok(log_prob)
}

#[rustler::nif]
pub fn normalize_min_max(data: Vec<f64>) -> Result<Vec<f64>, String> {
    if data.is_empty() {
        return Err("data must not be empty".into());
    }
    let min = data.iter().cloned().fold(f64::INFINITY, f64::min);
    let max = data.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let range = max - min;
    if range == 0.0 {
        return Ok(vec![0.0; data.len()]);
    }
    Ok(data.iter().map(|&x| (x - min) / range).collect())
}

#[rustler::nif]
pub fn normalize_z_score(data: Vec<f64>) -> Result<Vec<f64>, String> {
    if data.is_empty() {
        return Err("data must not be empty".into());
    }
    let n = data.len() as f64;
    let mean = data.iter().sum::<f64>() / n;
    let variance = data.iter().map(|&x| (x - mean).powi(2)).sum::<f64>() / n;
    let std_dev = variance.sqrt();
    if std_dev == 0.0 {
        return Ok(vec![0.0; data.len()]);
    }
    Ok(data.iter().map(|&x| (x - mean) / std_dev).collect())
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn silhouette_score(
    data: Vec<f64>,
    n_features: usize,
    labels: Vec<i32>,
    metric: String,
) -> Result<f64, String> {
    let slices = flat_to_slices(&data, n_features)?;
    let _metric = parse_distance_metric(&metric)?;
    cyanea_ml::silhouette_score(&slices, &labels).map_err(to_nif_error)
}

#[rustler::nif]
pub fn minhash_jaccard(sketch_a: Vec<u64>, sketch_b: Vec<u64>) -> Result<f64, String> {
    if sketch_a.len() != sketch_b.len() {
        return Err("sketches must have equal length".into());
    }
    if sketch_a.is_empty() {
        return Err("sketches must not be empty".into());
    }
    let matches = sketch_a
        .iter()
        .zip(sketch_b.iter())
        .filter(|(a, b)| a == b)
        .count();
    Ok(matches as f64 / sketch_a.len() as f64)
}
