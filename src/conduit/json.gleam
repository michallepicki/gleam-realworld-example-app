import gleam/json as gleam_json
import gleam/atom
import gleam/list
import gleam/map
import gleam/string
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}

pub type Json {
  Null
  Bool(v: Bool)
  Int(v: Int)
  Float(v: Float)
  String(v: String)
  Array(v: List(Json))
  Object(v: List(Field))
}

pub type Field {
  Field(k: String, v: Json)
}

pub fn encode(json_value: Json) -> String {
  json_value
  |> untype_json_value
  |> gleam_json.encode
}

pub fn decode(data: String) -> Result(Json, Dynamic) {
  try json_data = gleam_json.decode(data)
  Ok(type_json_data(dynamic.from(json_data)))
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

fn type_json_data(data: Dynamic) -> Json {
  case dynamic.atom(data) {
    Ok(an_atom) ->
      case atom.to_string(an_atom) {
        "true" -> Bool(True)
        "false" -> Bool(False)
        "null" -> Null
      }
    Error(_) ->
      case dynamic.int(data) {
        Ok(an_int) -> Int(an_int)
        Error(_) ->
          case dynamic.float(data) {
            Ok(a_float) -> Float(a_float)
            Error(_) ->
              case dynamic.string(data) {
                Ok(a_string) -> String(a_string)
                Error(_) ->
                  case dynamic.list(data) {
                    Ok(a_list) -> Array(list.map(a_list, type_json_data))
                    Error(_) ->
                      case dynamic.map(data) {
                        Ok(a_map) ->
                          Object(
                            a_map
                            |> map.to_list()
                            |> list.map(fn(field) {
                              let tuple(key, value) = field
                              assert Ok(string_key) = dynamic.string(key)
                              Field(string_key, type_json_data(value))
                            })
                            |> ensure_keys_sorted,
                          )
                      }
                  }
              }
          }
      }
  }
}

fn untype_json_value(json_value: Json) -> gleam_json.Json {
  case json_value {
    Null -> gleam_json.null()
    Bool(v) -> gleam_json.bool(v)
    Int(v) -> gleam_json.int(v)
    Float(v) ->
      v
      |> dynamic.from()
      |> dynamic.unsafe_coerce()
    String(v) -> gleam_json.string(v)
    Array(v) -> gleam_json.list(list.map(v, untype_json_value))
    Object(v) ->
      gleam_json.object(list.map(
        v,
        fn(field) {
          let Field(key, value) = field
          tuple(key, untype_json_value(value))
        },
      ))
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