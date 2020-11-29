import gleam/dynamic.{Dynamic}

pub external fn encode(Dynamic) -> Result(String, Dynamic) =
  "jsone_encode" "encode"

pub type DecodeResult {
  Ok(Dynamic, String)
  Error(Dynamic)
}

pub external fn decode(String) -> DecodeResult =
  "jsone_decode" "decode"
