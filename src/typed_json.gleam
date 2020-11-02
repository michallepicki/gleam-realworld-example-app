import gleam/json
import gleam/atom
import gleam/list
import gleam/map
import gleam/string
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}

pub type TypedJson {
  JsonNull
  JsonBool(v: Bool)
  JsonInt(v: Int)
  JsonFloat(v: Float)
  JsonString(v: String)
  JsonArray(v: List(TypedJson))
  JsonObject(v: List(tuple(String, TypedJson)))
}

pub fn decode(data: String) -> Result(TypedJson, Dynamic) {
  try json_data = json.decode(data)
  Ok(from_json(json_data))
}

pub fn from_json(json_data) {
  type_json_data(dynamic.from(json_data))
}

pub fn object_fetch(json_object: TypedJson, key: String) -> Option(TypedJson) {
  case filter_object(json_object, [key]) {
    JsonObject([tuple(_, value)]) -> Some(value)
    _ -> None
  }
}

fn filter_object(json_object: TypedJson, keys: List(String)) -> TypedJson {
  case json_object {
    JsonObject(tuple_list) ->
      tuple_list
      |> list.filter(fn(entry) {
        let tuple(key, _value) = entry
        list.contains(keys, key)
      })
      |> JsonObject()
    _ -> json_object
  }
}

fn type_json_data(data: Dynamic) -> TypedJson {
  case dynamic.atom(data) {
    Ok(an_atom) ->
      case atom.to_string(an_atom) {
        "true" -> JsonBool(True)
        "false" -> JsonBool(False)
        "null" -> JsonNull
      }
    Error(_) ->
      case dynamic.int(data) {
        Ok(an_int) -> JsonInt(an_int)
        Error(_) ->
          case dynamic.float(data) {
            Ok(a_float) -> JsonFloat(a_float)
            Error(_) ->
              case dynamic.string(data) {
                Ok(a_string) -> JsonString(a_string)
                Error(_) ->
                  case dynamic.list(data) {
                    Ok(a_list) -> JsonArray(list.map(a_list, type_json_data))
                    Error(_) ->
                      case dynamic.map(data) {
                        Ok(a_map) ->
                          JsonObject(
                            a_map
                            |> map.to_list()
                            |> list.map(fn(field) {
                              let tuple(key, value) = field
                              assert Ok(string_key) = dynamic.string(key)
                              tuple(string_key, type_json_data(value))
                            })
                            |> list.sort(fn(left, right) {
                              let tuple(string_key_left, _value_left) = left
                              let tuple(string_key_right, _value_right) = right
                              string.compare(string_key_left, string_key_right)
                            }),
                          )
                      }
                  }
              }
          }
      }
  }
}
