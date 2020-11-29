import gleam/http.{Request, Response}
import gleam/bit_string
import gleam/bit_builder.{BitBuilder}
import conduit/json
import conduit/user

pub fn service(request: Request(BitString)) -> Response(BitBuilder) {
  let response = case router(request) {
    Ok(response) -> response
    Error(response) -> response
  }

  response
}

fn router(
  request: Request(BitString),
) -> Result(Response(BitBuilder), Response(BitBuilder)) {
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

fn not_found() -> Result(Response(BitBuilder), Response(BitBuilder)) {
  http.response(404)
  |> http.set_resp_body(bit_builder.from_string("Not found"))
  |> Error()
}

fn check_utf8_encoding(
  request: Request(BitString),
) -> Result(Request(String), Response(BitBuilder)) {
  case bit_string.to_string(request.body) {
    Ok(body) ->
      request
      |> http.set_req_body(body)
      |> Ok()
    Error(_) ->
      http.response(400)
      |> http.set_resp_body(bit_builder.from_string(
        "Could not read the request body: make sure the body of your request is a valid UTF-8 string",
      ))
      |> Error()
  }
}

fn parse_json(
  request: Request(String),
) -> Result(Request(json.Json), Response(BitBuilder)) {
  case json.decode(request.body) {
    Ok(json) ->
      request
      |> http.set_req_body(json)
      |> Ok()
    Error(_) ->
      http.response(400)
      |> http.set_resp_body(bit_builder.from_string(
        "Could not parse the json body",
      ))
      |> Error()
  }
}
