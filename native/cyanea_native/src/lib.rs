//! Cyanea Native — Thin NIF bridge to Cyanea Labs.
//!
//! This crate exposes Elixir NIFs that delegate to the standalone
//! libraries in `labs/`. No business logic lives here — only type
//! conversions between Rustler NIF types and Cyanea Labs types.

pub mod bridge;

mod core;
mod seq;
mod io;
mod align;
mod stats;
mod omics;
mod ml;
mod chem;
mod structs;
mod phylo;
mod gpu;

/// Convert a `cyanea_core::CyaneaError` into a NIF-friendly `String`.
pub(crate) fn to_nif_error(e: cyanea_core::CyaneaError) -> String {
    e.to_string()
}

rustler::init!("Elixir.Cyanea.Native");
