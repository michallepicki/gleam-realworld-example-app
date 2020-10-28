import gleam/list
import gleam/string
import gleam/json

pub type Errors =
  List(tuple(String, List(String)))

pub fn apply(
  builder: Result(fn(a) -> b, Errors),
  result: Result(a, Errors),
) -> Result(b, Errors) {
  apply_result(builder, result, errors_joiner)
}

pub fn errors_json(errors: Errors) -> String {
  json.object([
    tuple(
      "errors",
      json.object(
        errors
        |> list.map(fn(field_errors) {
          let tuple(field, errors_list) = field_errors
          tuple(
            field,
            json.list(list.map(
              errors_list,
              fn(error_string) { json.string(error_string) },
            )),
          )
        }),
      ),
    ),
  ])
  |> json.encode()
}

fn apply_result(
  builder: Result(fn(a) -> b, e),
  result: Result(a, e),
  errors_joiner: fn(e, e) -> e,
) -> Result(b, e) {
  case builder, result {
    Ok(f), Ok(x) -> Ok(f(x))
    Ok(_), Error(errors) -> Error(errors)
    Error(errors), Ok(_) -> Error(errors)
    Error(errors1), Error(errors2) -> Error(errors_joiner(errors1, errors2))
  }
}

fn errors_joiner(errors1: Errors, errors2: Errors) -> Errors {
  list.append(errors1, errors2)
  |> list.sort(fn(left, right) {
    let tuple(string_key_left, _value_left) = left
    let tuple(string_key_right, _value_right) = right
    string.compare(string_key_left, string_key_right)
  })
  |> list.fold(
    [],
    fn(error, acc) {
      case error, acc {
        tuple(key, key_errors), [tuple(acc_key, acc_key_errors), ..rest] if key == acc_key -> [
          tuple(key, list.append(acc_key_errors, key_errors)),
          ..rest
        ]
        error, acc -> [error, ..acc]
      }
    },
  )
  |> list.reverse()
}
