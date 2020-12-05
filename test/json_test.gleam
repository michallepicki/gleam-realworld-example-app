import conduit/json
import gleam/dynamic
import gleam/should

pub fn decode_simple_types_test() {
  json.decode("null")
  |> should.equal(Ok(json.Null))
  json.decode("true")
  |> should.equal(Ok(json.Bool(True)))
  json.decode("false")
  |> should.equal(Ok(json.Bool(False)))
  json.decode("1337.0")
  |> should.equal(Ok(json.Float(1337.0)))
  json.decode("\"Yup\"")
  |> should.equal(Ok(json.String("Yup")))
}

pub fn decode_array_test() {
  json.decode("[[], 1337.0, null]")
  |> should.equal(Ok(json.Array([json.Array([]), json.Float(1337.0), json.Null])))
}

pub fn decode_object_test() {
  json.decode("{\"key2\":{},\"key1\":1337.0,\"key3\":null}")
  |> should.equal(Ok(json.Object([
    json.Field("key1", json.Float(1337.0)),
    json.Field("key2", json.Object([])),
    json.Field("key3", json.Null),
  ])))
}
