//! cyanea-stats NIFs — Descriptive statistics, correlation, hypothesis testing, distributions.

use crate::bridge::*;
use crate::to_nif_error;
use cyanea_stats::Distribution;

// ===========================================================================
// Existing NIFs
// ===========================================================================

#[rustler::nif]
pub fn descriptive_stats(data: Vec<f64>) -> Result<DescriptiveStatsNif, String> {
    cyanea_stats::descriptive::describe(&data)
        .map(DescriptiveStatsNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn pearson_correlation(x: Vec<f64>, y: Vec<f64>) -> Result<f64, String> {
    cyanea_stats::correlation::pearson(&x, &y).map_err(to_nif_error)
}

#[rustler::nif]
pub fn spearman_correlation(x: Vec<f64>, y: Vec<f64>) -> Result<f64, String> {
    cyanea_stats::correlation::spearman(&x, &y).map_err(to_nif_error)
}

#[rustler::nif]
pub fn t_test_one_sample(data: Vec<f64>, mu: f64) -> Result<TestResultNif, String> {
    cyanea_stats::testing::t_test_one_sample(&data, mu)
        .map(TestResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn t_test_two_sample(x: Vec<f64>, y: Vec<f64>, equal_var: bool) -> Result<TestResultNif, String> {
    cyanea_stats::testing::t_test_two_sample(&x, &y, equal_var)
        .map(TestResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn mann_whitney_u(x: Vec<f64>, y: Vec<f64>) -> Result<TestResultNif, String> {
    cyanea_stats::testing::mann_whitney_u(&x, &y)
        .map(TestResultNif::from)
        .map_err(to_nif_error)
}

#[rustler::nif]
pub fn p_adjust_bonferroni(p_values: Vec<f64>) -> Result<Vec<f64>, String> {
    cyanea_stats::correction::bonferroni(&p_values).map_err(to_nif_error)
}

#[rustler::nif]
pub fn p_adjust_bh(p_values: Vec<f64>) -> Result<Vec<f64>, String> {
    cyanea_stats::correction::benjamini_hochberg(&p_values).map_err(to_nif_error)
}

// ===========================================================================
// New NIFs
// ===========================================================================

#[rustler::nif]
pub fn cohens_d(group1: Vec<f64>, group2: Vec<f64>) -> Result<f64, String> {
    cyanea_stats::effect_size::cohens_d(&group1, &group2).map_err(to_nif_error)
}

#[rustler::nif]
pub fn odds_ratio(a: u64, b: u64, c: u64, d: u64) -> Result<f64, String> {
    let table = [[a as usize, b as usize], [c as usize, d as usize]];
    cyanea_stats::effect_size::odds_ratio(&table).map_err(to_nif_error)
}

#[rustler::nif]
pub fn normal_cdf(x: f64, mu: f64, sigma: f64) -> Result<f64, String> {
    if sigma <= 0.0 {
        return Err("sigma must be positive".into());
    }
    let z = (x - mu) / sigma;
    let normal = cyanea_stats::distribution::Normal::standard();
    Ok(normal.cdf(z))
}

#[rustler::nif]
pub fn normal_pdf(x: f64, mu: f64, sigma: f64) -> Result<f64, String> {
    if sigma <= 0.0 {
        return Err("sigma must be positive".into());
    }
    let z = (x - mu) / sigma;
    let normal = cyanea_stats::distribution::Normal::standard();
    Ok(normal.pdf(z) / sigma)
}

#[rustler::nif]
pub fn chi_squared_cdf(x: f64, df: f64) -> Result<f64, String> {
    if df <= 0.0 {
        return Err("df must be positive".into());
    }
    let chi2 = cyanea_stats::distribution::ChiSquared::new(df)
        .map_err(to_nif_error)?;
    Ok(chi2.cdf(x))
}

#[rustler::nif]
pub fn bayesian_beta_update(
    alpha: f64,
    beta: f64,
    successes: u64,
    trials: u64,
) -> (f64, f64) {
    // Beta-Binomial conjugate update: alpha' = alpha + successes, beta' = beta + failures
    (alpha + successes as f64, beta + (trials - successes) as f64)
}
