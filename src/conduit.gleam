import gleam/http.{Request, Response}
import gleam/bit_string
import gleam/bit_builder.{BitBuilder}
import gleam/json
import gleam/string
import typed_json
import conduit/user

pub fn service(request: Request(BitString)) -> Response(BitBuilder) {
  let response = case router(request) {
    Ok(response) -> response
    Error(response) -> response
  }

  response
  |> http.map_resp_body(bit_builder.from_string)
}

fn router(
  request: Request(BitString),
) -> Result(Response(String), Response(String)) {
  let path_segments = http.path_segments(request)
  case request.method, path_segments {
    http.Post, ["api", "users"] -> {
      try string_request = check_utf8_encoding(request)
      try json_request = parse_json(string_request)
      user.registration(json_request)
    }
    _, _ -> not_found()
  }
}

fn not_found() -> Result(Response(String), Response(String)) {
  http.response(404)
  |> http.set_resp_body("Not found")
  |> Error()
}

fn check_utf8_encoding(
  request: Request(BitString),
) -> Result(Request(String), Response(String)) {
  case bit_string.to_string(request.body) {
    Ok(body) ->
      request
      |> http.set_req_body(body)
      |> Ok()
    Error(_) ->
      http.response(400)
      |> http.set_resp_body(
        "Could not read the request body: make sure the body of your request is a valid UTF-8 string",
      )
      |> Error()
  }
}

fn parse_json(
  request: Request(String),
) -> Result(Request(typed_json.TypedJson), Response(String)) {
  case json.decode(request.body) {
    Ok(json_data) ->
      request
      |> http.set_req_body(typed_json.from_json(json_data))
      |> Ok()
    Error(_) ->
      http.response(400)
      |> http.set_resp_body("Could not parse the json body")
      |> Error()
  }
}
