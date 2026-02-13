//! cyanea-core NIFs — Hashing & Compression.

use crate::to_nif_error;

#[rustler::nif]
pub fn sha256(data: Vec<u8>) -> String {
    cyanea_core::hash::sha256(&data)
}

#[rustler::nif]
pub fn sha256_file(path: String) -> Result<String, String> {
    cyanea_core::hash::sha256_file(&path).map_err(to_nif_error)
}

#[rustler::nif]
pub fn zstd_compress(data: Vec<u8>, level: i32) -> Result<Vec<u8>, String> {
    cyanea_core::compress::zstd_compress(&data, level).map_err(to_nif_error)
}

#[rustler::nif]
pub fn zstd_decompress(data: Vec<u8>) -> Result<Vec<u8>, String> {
    cyanea_core::compress::zstd_decompress(&data).map_err(to_nif_error)
}

#[rustler::nif]
pub fn gzip_compress(data: Vec<u8>, level: u32) -> Result<Vec<u8>, String> {
    cyanea_core::compress::gzip_compress(&data, level).map_err(to_nif_error)
}

#[rustler::nif]
pub fn gzip_decompress(data: Vec<u8>) -> Result<Vec<u8>, String> {
    cyanea_core::compress::gzip_decompress(&data).map_err(to_nif_error)
}
