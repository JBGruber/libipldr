// R bindings for DAG-CBOR, CID and CAR decoding, built on ipld-core and
// serde_ipld_dagcbor (the successors of the deprecated libipld crate).
// Originally adapted from https://github.com/MarshalX/python-libipld

use anyhow::{anyhow, Error, Result};
use extendr_api::prelude::*;
use ipld_core::cid::Cid;
use ipld_core::ipld::Ipld;
use std::io::Cursor;

// Convert IPLD to R objects
fn ipld_to_robj(ipld: &Ipld) -> Robj {
    match ipld {
        Ipld::Null => r!(NULL),
        Ipld::Bool(b) => r!(*b),
        Ipld::Integer(i) => {
            if *i > i32::MIN as i128 && *i <= i32::MAX as i128 {
                // i32::MIN is NA_integer_ in R, so it is excluded above
                r!(*i as i32)
            } else {
                // R has no 64-bit integer type; doubles are exact up to 2^53
                r!(*i as f64)
            }
        }
        Ipld::Float(f) => r!(*f),
        Ipld::String(s) => r!(s.as_str()),
        Ipld::Bytes(b) => Robj::from(b.as_slice()),
        Ipld::List(l) => List::from_values(l.iter().map(ipld_to_robj)).into(),
        Ipld::Map(m) => {
            let names: Vec<&str> = m.keys().map(|k| k.as_str()).collect();
            let values: Vec<Robj> = m.values().map(ipld_to_robj).collect();
            let mut r_list = List::from_values(values);
            r_list.set_names(names).unwrap();
            r_list.into()
        }
        Ipld::Link(cid) => r!(cid.to_string()),
    }
}

fn named_list(names: Vec<&str>, values: Vec<Robj>) -> Robj {
    let mut result = List::from_values(values);
    result.set_names(names).unwrap();
    result.into()
}

fn cid_to_robj(cid: &Cid) -> Robj {
    let hash = cid.hash();
    let hash_list = named_list(
        vec!["code", "size", "digest"],
        vec![
            r!(hash.code() as i32),
            r!(hash.size() as i32),
            Robj::from(hash.digest()),
        ],
    );
    named_list(
        vec!["version", "codec", "hash"],
        vec![
            r!(u64::from(cid.version()) as i32),
            r!(cid.codec() as i32),
            hash_list,
        ],
    )
}

// Read an unsigned LEB128 varint (as used for CAR section lengths)
fn read_varint(data: &[u8], pos: &mut usize) -> Result<u64> {
    let mut value: u64 = 0;
    for shift in (0..64).step_by(7) {
        let byte = *data
            .get(*pos)
            .ok_or_else(|| anyhow!("unexpected end of data while reading varint"))?;
        *pos += 1;
        value |= ((byte & 0x7f) as u64) << shift;
        if byte & 0x80 == 0 {
            return Ok(value);
        }
    }
    Err(anyhow!("varint too long"))
}

// Read one length-prefixed CAR section and advance `pos` past it
fn read_car_section<'a>(data: &'a [u8], pos: &mut usize) -> Result<&'a [u8]> {
    let len = read_varint(data, pos)? as usize;
    let end = pos
        .checked_add(len)
        .filter(|end| *end <= data.len())
        .ok_or_else(|| anyhow!("CAR section length exceeds data"))?;
    let section = &data[*pos..end];
    *pos = end;
    Ok(section)
}

fn car_header_to_robj(header: &Ipld) -> Result<Robj> {
    let version = match header.get("version") {
        Ok(Some(Ipld::Integer(v))) => *v as i32,
        _ => return Err(anyhow!("CAR header is missing a valid 'version'")),
    };
    let roots: Vec<String> = match header.get("roots") {
        Ok(Some(Ipld::List(l))) => l
            .iter()
            .map(|root| match root {
                Ipld::Link(cid) => Ok(cid.to_string()),
                _ => Err(anyhow!("CAR header root is not a CID")),
            })
            .collect::<Result<_>>()?,
        _ => Vec::new(),
    };
    Ok(named_list(vec!["version", "roots"], vec![r!(version), r!(roots)]))
}

// R-exposed functions

/// Decode a DAG-CBOR encoded byte vector to an R object
/// @param data A raw vector containing DAG-CBOR encoded data
/// @export
#[extendr]
fn decode_dag_cbor(data: &[u8]) -> Result<Robj, Error> {
    let ipld: Ipld = serde_ipld_dagcbor::from_slice(data)
        .map_err(|e| anyhow!("Failed to decode DAG-CBOR: {}", e))?;
    Ok(ipld_to_robj(&ipld))
}

/// Decode multiple DAG-CBOR objects from a byte vector
/// @param data A raw vector containing multiple DAG-CBOR encoded objects
/// @export
#[extendr]
fn decode_dag_cbor_multi(data: &[u8]) -> Robj {
    let mut reader = Cursor::new(data);
    let mut parts = Vec::new();
    let mut bytes_consumed: u64 = 0;

    while (reader.position() as usize) < data.len() {
        match serde_ipld_dagcbor::de::from_reader_once::<Ipld, _>(&mut reader) {
            Ok(ipld) => {
                parts.push(ipld_to_robj(&ipld));
                bytes_consumed = reader.position();
            }
            Err(_) => break,
        }
    }

    let mut result_list = List::from_values(parts);
    result_list
        .set_attrib("bytes_consumed", r!(bytes_consumed as f64))
        .unwrap();
    result_list.into()
}

/// Decode a CID string to its components
/// @param cid_str A string containing a CID
/// @export
#[extendr]
fn decode_cid(cid_str: &str) -> Result<Robj, Error> {
    let cid = Cid::try_from(cid_str).map_err(|e| anyhow!("Failed to decode CID: {}", e))?;
    Ok(cid_to_robj(&cid))
}

/// Decode a CAR file byte vector
/// @param data A raw vector containing a CAR file
/// @export
#[extendr]
fn decode_car(data: &[u8]) -> Result<Robj, Error> {
    let mut pos = 0;

    let header_bytes = read_car_section(data, &mut pos)
        .map_err(|e| anyhow!("Failed to decode CAR file: {}", e))?;
    let header: Ipld = serde_ipld_dagcbor::from_slice(header_bytes)
        .map_err(|e| anyhow!("Failed to decode CAR file header: {}", e))?;
    let header = car_header_to_robj(&header)?;

    let mut names: Vec<String> = Vec::new();
    let mut values: Vec<Robj> = Vec::new();

    while pos < data.len() {
        let section = read_car_section(data, &mut pos)
            .map_err(|e| anyhow!("Failed to decode CAR file: {}", e))?;
        let mut block = Cursor::new(section);
        let cid = Cid::read_bytes(&mut block)
            .map_err(|e| anyhow!("Failed to decode CAR block CID: {}", e))?;
        let body = &section[block.position() as usize..];
        // Blocks that are not valid DAG-CBOR (e.g. raw or dag-pb) are skipped
        if let Ok(ipld) = serde_ipld_dagcbor::from_slice::<Ipld>(body) {
            names.push(cid.to_string());
            values.push(ipld_to_robj(&ipld));
        }
    }

    let mut blocks = List::from_values(values);
    blocks.set_names(names).unwrap();

    Ok(named_list(vec!["header", "blocks"], vec![header, blocks.into()]))
}

// Macro to generate exports
extendr_module! {
    mod libipldr;
    fn decode_dag_cbor;
    fn decode_dag_cbor_multi;
    fn decode_cid;
    fn decode_car;
}
