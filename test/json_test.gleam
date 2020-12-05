import conduit/json
import gleam/dynamic
import gleam/should
import gleam/bit_builder

pub fn decode_simple_types_test() {
  json.decode("null")
  |> should.equal(Ok(json.Null))
  json.decode("true")
  |> should.equal(Ok(json.Bool(True)))
  json.decode("false")
  |> should.equal(Ok(json.Bool(False)))
  json.decode("1337.0")
  |> should.equal(Ok(json.Number(1337.0)))
  json.decode("\"Yup\"")
  |> should.equal(Ok(json.String("Yup")))
}

pub fn decode_array_test() {
  json.decode("[[], 1337.0, null]")
  |> should.equal(Ok(json.Array([json.Array([]), json.Number(1337.0), json.Null])))
}

pub fn encode_array_test() {
  json.encode(json.Array([json.Array([]), json.Number(1337.0), json.Null]))
  |> bit_builder.to_bit_string
  |> should.equal(<<"[[],1337.0,null]":utf8>>)
}

pub fn decode_object_test() {
  json.decode("{\"key2\":{},\"key1\":1337.0,\"key3\":null}")
  |> should.equal(Ok(json.Object([
    json.Field("key1", json.Number(1337.0)),
    json.Field("key2", json.Object([])),
    json.Field("key3", json.Null),
  ])))
}

pub fn encode_object_test() {
  json.encode(json.Object([
    json.Field("key1", json.Number(1337.0)),
    json.Field("key2", json.Object([])),
    json.Field("key3", json.Null),
  ]))
  |> bit_builder.to_bit_string
  |> should.equal(<<"{\"key1\":1337.0,\"key2\":{},\"key3\":null}":utf8>>)
}
