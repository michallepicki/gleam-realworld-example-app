import gleam/string
import gleam/pgo
import gleam/option.{None, Option, Some}
import gleam/regex
import gleam/http.{Request, Response}
import conduit/json
import conduit/validation
import conduit/db

type User {
  User(
    email: String,
    token: String,
    username: String,
    bio: Option(String),
    image: Option(String),
  )
}

pub fn registration(
  request: Request(json.Json),
) -> Result(Response(String), Response(String)) {
  try RegistrationParams(user_email, _user_password, user_username) =
    read_registration_params(request.body)

  let user =
    User(
      email: user_email,
      token: "some_token",
      username: user_username,
      bio: None,
      image: None,
    )

  assert Ok(_) =
    db.query(
      "insert into users (email, username) values ($1 , $2)",
      [pgo.text(user.email), pgo.text(user.username)],
    )

  let user_response =
    json.Object([
      json.Field(
        "user",
        json.Object([
          json.Field("email", json.String(user.email)),
          json.Field("token", json.String(user.token)),
          json.Field("username", json.String(user.username)),
          json.Field("bio", json.Null),
          json.Field("image", json.Null),
        ]),
      ),
    ])
    |> json.encode()

  http.response(200)
  |> http.set_resp_body(user_response)
  |> Ok()
}

fn read_registration_params(
  registration_json: json.Json,
) -> Result(RegistrationParams, Response(String)) {
  // What errors should be returned, exactly? This is not well-defined in the in realworld API spec
  let validated_params = case json.fetch(registration_json, "user") {
    Some(user_json) -> validate_registration_fields(user_json)
    None -> validate_registration_fields(json.Object([]))
  }
  case validated_params {
    Ok(registration_params) -> Ok(registration_params)
    Error(errors) -> {
      let errors_response = validation.errors_json(errors)
      http.response(422)
      |> http.set_resp_body(errors_response)
      |> Error()
    }
  }
}

fn validate_registration_fields(
  user_json: json.Json,
) -> Result(RegistrationParams, validation.Errors) {
  registration_params_builder()
  |> validation.apply(validate_registration_email(user_json))
  |> validation.apply(validate_registration_password(user_json))
  |> validation.apply(validate_registration_username(user_json))
}

type RegistrationParams {
  RegistrationParams(email: String, password: String, username: String)
}

fn registration_params_builder() {
  fn(email) {
    fn(password) {
      fn(username) {
        RegistrationParams(email: email, password: password, username: username)
      }
    }
  }
  |> Ok()
}

fn validate_registration_email(
  user_json: json.Json,
) -> Result(String, validation.Errors) {
  case json.fetch(user_json, "email") {
    Some(json.String(email)) -> {
      assert Ok(email_regex) = regex.from_string("^[^@]+@[^@]+$")
      case regex.check(email_regex, email) {
        True -> Ok(email)
        False -> Error([tuple("email", ["is not valid"])])
      }
    }
    Some(_) -> Error([tuple("email", ["must be a string"])])
    None -> Error([tuple("email", ["must be present"])])
  }
}

fn validate_registration_password(
  user_json: json.Json,
) -> Result(String, validation.Errors) {
  case json.fetch(user_json, "password") {
    Some(json.String(password)) ->
      case string.length(password) {
        length if length >= 8 -> Ok(password)
        _ -> Error([tuple("password", ["must be at least 8 characters long"])])
      }
    Some(_) -> Error([tuple("password", ["must be a string"])])
    None -> Error([tuple("password", ["must be present"])])
  }
}

fn validate_registration_username(
  user_json: json.Json,
) -> Result(String, validation.Errors) {
  case json.fetch(user_json, "username") {
    Some(json.String(username)) ->
      // assert Ok(username_regex) = regex.from_string("^\S{1,20}$")
      // case regex.check(username_regex, username) {
      //   True -> Ok(username)
      //   False -> Error([tuple("username", ["is not valid"])])
      // }
      Ok(username)
    Some(_) -> Error([tuple("username", ["must be a string"])])
    _ -> Error([tuple("username", ["must be present"])])
  }
}
