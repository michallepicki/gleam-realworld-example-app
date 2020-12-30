import gleam/http.{Request, Response}
import gleam/bit_string
import gleam/bit_builder.{BitBuilder}
import gleam/io
import gleam/list
import gleam/string
import conduit/json
import conduit/user

pub fn service(request: Request(BitString)) -> Response(BitBuilder) {
  case router(request) {
    Ok(response) | Error(response) -> http.prepend_resp_header(response, "access-control-allow-origin", "*")
  }
}

fn router(
  request: Request(BitString),
) -> Result(Response(BitBuilder), Response(BitBuilder)) {
  let path_segments = http.path_segments(request) |> io.debug |> drop_query()
  case request.method, path_segments {
    http.Options, _ -> {
      http.response(200)
      |> http.set_resp_body(bit_builder.from_string(""))
      |> http.prepend_resp_header("access-control-allow-methods", "OPTIONS, GET, POST")
      |> Ok
    }
    http.Get, ["api", "user"] -> {
      http.response(200)
      |> http.set_resp_body(bit_builder.from_string("{\"user\":{\"email\":\"user@example.com\",\"username\":\"username\",\"bio\":\"bio\",\"image\":\"image\",\"token\":\"token\"}}"))
      |> Ok
    }
    http.Get, ["api", "articles"] -> {
      http.response(200)
      |> http.set_resp_body(bit_builder.from_string("{\"articles\":[],\"articlesCount\":0}"))
      |> Ok
    }
    http.Get, ["api", "tags"] -> {
      http.response(200)
      |> http.set_resp_body(bit_builder.from_string("{\"tags\":[]}"))
      |> Ok
    }
    http.Post, ["api", "users"] -> {
      try string_request = check_utf8_encoding(request)
      try json_request = parse_json(string_request)
      user.registration(json_request)
    }
    _, _ -> not_found()
  }
}

fn drop_query(path_segments: List(String)) -> List(String) {
  let tuple(last_segment_list, other_segments) =
    path_segments
    |> list.reverse
    |> list.split(1)
  case last_segment_list {
    [] -> []
    [last_segment] -> {
      case string.split_once(last_segment, "?") {
        Ok(tuple(last_segment_without_query, _query)) -> list.reverse([last_segment_without_query, ..other_segments])
        Error(Nil) -> path_segments
      }
    }
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
