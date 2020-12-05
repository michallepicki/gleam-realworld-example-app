import gleam/atom
import gleam/list
import gleam/map
import gleam/int
import gleam/float
import gleam/string
import gleam/bit_builder.{BitBuilder}
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import conduit/json/jsone_wrapper

pub type Json {
  Null
  Bool(v: Bool)
  Number(v: Float)
  String(v: String)
  Array(v: List(Json))
  Object(v: List(Field))
}

pub type Field {
  Field(k: String, v: Json)
}

pub fn encode(value: Json) -> BitBuilder {
  case value {
    Null -> bit_builder.from_string("null")
    Bool(True) -> bit_builder.from_string("true")
    Bool(False) -> bit_builder.from_string("false")
    Number(v) -> bit_builder.from_string(float.to_string(v))
    String(v) -> encode_string(v)
    Array([]) -> bit_builder.from_string("[]")
    Array([first, ..rest]) -> {
      let right =
        list.fold(
          list.reverse(rest),
          [bit_builder.from_string("]")],
          fn(next, acc) { [bit_builder.from_string(","), encode(next), ..acc] },
        )
      [bit_builder.from_string("["), encode(first), ..right]
      |> bit_builder.concat
    }
    Object([]) -> bit_builder.from_string("{}")
    Object([first, ..rest]) -> {
      let right =
        list.fold(
          list.reverse(rest),
          [bit_builder.from_string("}")],
          fn(next, acc) {
            [bit_builder.from_string(","), encode_field(next), ..acc]
          },
        )
      [bit_builder.from_string("{"), encode_field(first), ..right]
      |> bit_builder.concat
    }
  }
}

fn encode_field(field: Field) -> BitBuilder {
  let Field(key, value) = field
  [encode_string(key), bit_builder.from_string(":"), encode(value)]
  |> bit_builder.concat
}

fn encode_string(val: String) -> BitBuilder {
  assert Ok(encoded) = jsone_wrapper.encode(dynamic.from(val))
  bit_builder.from_string(encoded)
}

pub fn decode(data: String) -> Result(Json, Dynamic) {
  case jsone_wrapper.decode(data) {
    jsone_wrapper.Ok(value, _rest) -> Ok(add_type_tags(value))
    jsone_wrapper.Error(error) -> Error(error)
  }
}

pub fn fetch(json_object: Json, key: String) -> Option(Json) {
  case filter_object(json_object, [key]) {
    Object([Field(_, value)]) -> Some(value)
    _ -> None
  }
}

fn filter_object(json_object: Json, keys: List(String)) -> Json {
  case json_object {
    Object(tuple_list) ->
      tuple_list
      |> list.filter(fn(entry) {
        let Field(key, _value) = entry
        list.contains(keys, key)
      })
      |> Object()
    _ -> json_object
  }
}

fn add_type_tags(data: Dynamic) -> Json {
  case dynamic.atom(data) {
    Ok(an_atom) ->
      case atom.to_string(an_atom) {
        "true" -> Bool(True)
        "false" -> Bool(False)
        "null" -> Null
      }
    Error(_) ->
      case dynamic.float(data) {
        Ok(a_float) -> Number(a_float)
        Error(_) ->
          case dynamic.string(data) {
            Ok(a_string) -> String(a_string)
            Error(_) ->
              case dynamic.list(data) {
                Ok(a_list) -> Array(list.map(a_list, add_type_tags))
                Error(_) ->
                  case dynamic.map(data) {
                    Ok(a_map) ->
                      Object(
                        a_map
                        |> map.to_list()
                        |> list.map(fn(field) {
                          let tuple(key, value) = field
                          assert Ok(string_key) = dynamic.string(key)
                          Field(string_key, add_type_tags(value))
                        })
                        |> ensure_keys_sorted,
                      )
                  }
              }
          }
      }
  }
}

fn ensure_keys_sorted(object_fields: List(Field)) -> List(Field) {
  object_fields
  |> list.sort(fn(left, right) {
    let Field(string_key_left, _value_left) = left
    let Field(string_key_right, _value_right) = right
    string.compare(string_key_left, string_key_right)
  })
}
