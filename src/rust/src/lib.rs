// copied and adapted from https://raw.githubusercontent.com/MarshalX/python-libipld/main/src/lib.rs

use extendr_api::prelude::*;
use std::collections::HashMap;
use std::io::{BufReader, Cursor, Read, Seek, SeekFrom};
use anyhow::{Result, Error};
use iroh_car::{CarHeader, CarReader};
use futures::{executor, stream::StreamExt};
use ::libipld::cbor::cbor::MajorKind;
use ::libipld::cbor::decode;
use ::libipld::{cid::Cid, Ipld};

// Convert IPLD to R objects
fn ipld_to_robj(ipld: &Ipld) -> Robj {
    match ipld {
        Ipld::Null => r!(NULL),
        Ipld::Bool(b) => r!(*b),
        Ipld::Integer(i) => {
            // Handle potential integer overflow
            if *i >= i32::MIN as i128 && *i <= i32::MAX as i128 {
                r!(*i as i32)
            } else if *i >= i64::MIN as i128 && *i <= i64::MAX as i128 {
                r!(*i as i64)
            } else {
                // Fall back to float for extremely large integers
                r!(*i as f64)
            }
        },
        Ipld::Float(f) => r!(*f),
        Ipld::String(s) => r!(s.clone()),
        Ipld::Bytes(b) => {
            let bytes_vec: Vec<u8> = b.to_vec();
            Robj::from(bytes_vec)
        },
        Ipld::List(l) => {
            let vec: Vec<Robj> = l.iter().map(|item| ipld_to_robj(item)).collect();
            List::from_values(vec).into()
        },
        Ipld::Map(m) => {
            let mut names: Vec<String> = Vec::with_capacity(m.len());
            let mut values: Vec<Robj> = Vec::with_capacity(m.len());

            for (k, v) in m {
                names.push(k.clone());
                values.push(ipld_to_robj(v));
            }

            let mut r_list = List::from_values(values);
            r_list.set_names(names).unwrap();
            r_list.into()
        },
        Ipld::Link(cid) => r!(cid.to_string()),
    }
}

fn parse_dag_cbor_object<R: Read + Seek>(mut reader: &mut BufReader<R>) -> Result<Ipld> {
    let major = decode::read_major(&mut reader)?;
    Ok(match major.kind() {
        MajorKind::UnsignedInt | MajorKind::NegativeInt => Ipld::Integer(major.info() as i128),
        MajorKind::ByteString => Ipld::Bytes(decode::read_bytes(&mut reader, major.info() as u64)?),
        MajorKind::TextString => Ipld::String(decode::read_str(&mut reader, major.info() as u64)?),
        MajorKind::Array => Ipld::List(decode::read_list(&mut reader, major.info() as u64)?),
        MajorKind::Map => Ipld::Map(decode::read_map(&mut reader, major.info() as u64)?),
        MajorKind::Tag => {
            if major.info() != 42 {
                return Err(anyhow::anyhow!("non-42 tags are not supported"));
            }
            parse_dag_cbor_object(reader)?
        }
        MajorKind::Other => Ipld::Null,
    })
}

fn decode_dag_cbor_internal(data: &[u8]) -> Result<Ipld> {
    let mut reader = BufReader::new(Cursor::new(data));
    parse_dag_cbor_object(&mut reader)
}

fn car_header_to_robj(header: &CarHeader) -> Robj {
    let version = header.version() as i32;
    let roots: Vec<String> = header.roots().iter().map(|cid| cid.to_string()).collect();

    let values = vec![r!(version), r!(roots)];
    let names = vec!["version", "roots"];

    let mut result = List::from_values(values);
    result.set_names(names).unwrap();

    let r_result = result.into_robj();
    r_result
}

fn cid_hash_to_robj(cid: &Cid) -> Robj {
    let hash = cid.hash();

    let values = vec![
        r!(hash.code() as i32),
        r!(hash.size() as i32),
        r!(hash.digest().to_vec())
    ];
    let names = vec!["code", "size", "digest"];

    let mut result = List::from_values(values);

    result.into()
}

fn cid_to_robj(cid: &Cid) -> Robj {
    let values = vec![
        r!(cid.version() as i32),
        r!(cid.codec() as i32),
        cid_hash_to_robj(cid)
    ];
    let names = vec!["version", "codec", "hash"];

    let mut result = List::from_values(values);

    let r_result = result.into_robj();
    r_result
}

// R-exposed functions

/// Decode a DAG-CBOR encoded byte vector to an R object
/// @param data A raw vector containing DAG-CBOR encoded data
/// @export
#[extendr]
fn decode_dag_cbor(data: &[u8]) -> Result<Robj, Error> {
    match decode_dag_cbor_internal(data) {
        Ok(ipld) => Ok(ipld_to_robj(&ipld)),
        Err(e) => Err(e),
    }
}

/// Decode multiple DAG-CBOR objects from a byte vector
/// @param data A raw vector containing multiple DAG-CBOR encoded objects
/// @export
#[extendr]
fn decode_dag_cbor_multi(data: &[u8]) -> Robj {
    let mut reader = BufReader::new(Cursor::new(data));
    let mut parts = Vec::new();
    let mut last_successful_position: u64 = 0;

    loop {
        // Get current position before attempting to parse
        let current_position = match reader.stream_position() {
            Ok(pos) => pos,
            Err(_) => break,
        };

        let cbor = parse_dag_cbor_object(&mut reader);
        match cbor {
            Ok(ipld) => {
                parts.push(ipld_to_robj(&ipld));
                // Update last successful position after successful parse
                last_successful_position = match reader.stream_position() {
                    Ok(pos) => pos,
                    Err(_) => current_position, // fallback to current if we can't get position
                };
            },
            Err(_) => {
                // Reset to last successful position and break
                let _ = reader.seek(SeekFrom::Start(last_successful_position));
                break;
            }
        }
    }

    // Create the list of decoded objects
    let mut result_list = List::from_values(parts);

    // Add the bytes_consumed attribute
    result_list.set_attrib("bytes_consumed", r!(last_successful_position as i32)).unwrap();

    result_list.into()
}

/// Decode a CID string to its components
/// @param cid_str A string containing a CID
/// @export
#[extendr]
fn decode_cid(cid_str: &str) -> Result<Robj, Error> {
    match Cid::try_from(cid_str) {
        Ok(cid) => Ok(cid_to_robj(&cid)),
        Err(e) => Err(anyhow::anyhow!("Failed to decode CID: {}", e)),
    }
}

/// Decode a CAR file byte vector
/// @param data A raw vector containing a CAR file
/// @export
#[extendr]
fn decode_car(data: &[u8]) -> Result<Robj, Error> {
    let car_res = executor::block_on(CarReader::new(data));

    match car_res {
        Ok(car) => {
            let header = car_header_to_robj(car.header());

            let blocks_res = executor::block_on(car
                .stream()
                .filter_map(|block| async {
                    match block {
                        Ok((cid, bytes)) => {
                            let mut reader = BufReader::new(Cursor::new(bytes));
                            match parse_dag_cbor_object(&mut reader) {
                                Ok(ipld) => Some((cid.to_string(), ipld)),
                                Err(_) => None,
                            }
                        },
                        Err(_) => None,
                    }
                })
                .collect::<HashMap<String, Ipld>>());

            let mut names: Vec<String> = Vec::with_capacity(blocks_res.len());
            let mut values: Vec<Robj> = Vec::with_capacity(blocks_res.len());

            for (cid, ipld) in blocks_res {
                names.push(cid);
                values.push(ipld_to_robj(&ipld));
            }

            let mut blocks_list = List::from_values(values);
            blocks_list.set_names(names).unwrap();

            let values = vec![header, blocks_list.into_robj()];
            let names = vec!["header", "blocks"];

            let mut result = List::from_values(values);
            result.set_names(names).unwrap();

            let r_result = result.into_robj();
            Ok(r_result)
        },
        Err(e) => Err(anyhow::anyhow!("Failed to decode CAR file: {}", e)),
    }
}

// Macro to generate exports
extendr_module! {
    mod libipldr;
    fn decode_dag_cbor;
    fn decode_dag_cbor_multi;
    fn decode_cid;
    fn decode_car;
}
