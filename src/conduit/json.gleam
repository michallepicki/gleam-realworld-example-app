import gleam/atom
import gleam/list
import gleam/map
import gleam/string
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import conduit/json/jsone_wrapper

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

pub fn encode(value: Json) -> String {
  assert Ok(encoded) = jsone_wrapper.encode(remove_type_tags(value))
  encoded
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
}

fn remove_type_tags(json_value: Json) -> Dynamic {
  case json_value {
    Null -> dynamic.unsafe_coerce(dynamic.from(Null))
    Bool(v) -> dynamic.unsafe_coerce(dynamic.from(v))
    Int(v) -> dynamic.unsafe_coerce(dynamic.from(v))
    Float(v) -> dynamic.unsafe_coerce(dynamic.from(v))
    String(v) -> dynamic.unsafe_coerce(dynamic.from(v))
    Array(v) -> dynamic.unsafe_coerce(dynamic.from(v))
    Object(v) ->
      v
      |> list.map(fn(field) {
        let Field(key, value) = field
        tuple(key, remove_type_tags(value))
      })
      |> dynamic.from()
      |> dynamic.unsafe_coerce()
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
