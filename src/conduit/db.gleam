import gleam/pgo
import gleam/atom
import gleam/io
import gleam/string
import gleam/map
import gleam/list
import gleam/dynamic.{Dynamic}
import gleam/os
import gleam/result
import gleam/int
import gleam/otp/supervisor

pub fn query(sql, arguments) {
  pgo.query(atom_("default"), sql, arguments)
}

pub fn reset(name) {
  run_management_pool()
  drop(name)
  create(name)
  run_pool(name)
  migrate()
  Nil
}

pub fn run_management_pool() {
  io.println("Running the database management connection pool")
  let db_credentials = get_db_credentials()
  pgo.start_link(
    atom_("db_management_pool"),
    [pgo.Database("postgres"), ..db_credentials],
  )
}

pub fn drop(name) {
  io.println("Dropping the database")
  erl_query(
    string.concat(["DROP DATABASE \"", name, "\""]),
    [],
    db_management_query_options(),
  )
}

pub fn create(name) {
  io.println("Creating the database")
  erl_query(
    string.concat(["CREATE DATABASE \"", name, "\" ENCODING 'UTF8'"]),
    [],
    db_management_query_options(),
  )
}

pub fn run_pool(name) {
  io.println("Running counduit database connection pool")
  let db_credentials = get_db_credentials()
  supervisor.from_erlang_start_result(pgo.start_link(
    atom_("default"),
    [pgo.Database(name), ..db_credentials],
  ))
}

pub fn migrate() {
  io.println("Migrating the database")
  erl_query(
    "CREATE TABLE IF NOT EXISTS schema_migrations (id text PRIMARY KEY)",
    [],
    conduit_db_query_options(),
  )

  assert Ok(tuple(_, _, rows)) = query("SELECT id FROM schema_migrations", [])
  let already_ran_migrations =
    rows
    |> list.map(fn(row) {
      assert Ok(id_dynamic) = dynamic.element(row, 0)
      assert Ok(id) = dynamic.string(id_dynamic)
      id
    })
  migrations()
  |> list.map(fn(migration) {
    assert Migration(migration_id, migration_function) = migration
    case list.contains(already_ran_migrations, migration_id) {
      True -> Nil
      False -> {
        assert Ok(_) =
          query(
            "INSERT INTO schema_migrations(id) VALUES ($1)",
            [pgo.text(migration_id)],
          )
        migration_function()
      }
    }
  })
}

fn get_db_credentials() {
  let env = os.get_env()
  let host =
    map.get(env, "POSTGRES_HOST")
    |> result.unwrap("localhost")
  let port_string =
    map.get(env, "POSTGRES_PORT")
    |> result.unwrap("5432")
  let port =
    int.parse(port_string)
    |> result.unwrap(5432)
  let user =
    map.get(env, "POSTGRES_USER")
    |> result.unwrap("postgres")
  let password =
    map.get(env, "POSTGRES_PASSWORD")
    |> result.unwrap("postgres")
  [pgo.Host(host), pgo.Port(port), pgo.User(user), pgo.Password(password)]
}

fn atom_(atom_name) {
  atom.create_from_string(atom_name)
}

external fn erl_query(
  String,
  List(pgo.PgType),
  map.Map(atom.Atom, atom.Atom),
) -> Dynamic =
  "pgo" "query"

fn db_management_query_options() {
  map.new()
  |> map.insert(atom_("pool"), atom_("db_management_pool"))
}

fn conduit_db_query_options() {
  map.new()
  |> map.insert(atom_("pool"), atom_("default"))
}

type Migration {
  Migration(id: String, function: fn() -> Nil)
}

fn migrations() {
  [
    Migration(
      "create users table",
      fn() {
        erl_query(
          "CREATE TABLE users (
              id bigint NOT NULL PRIMARY KEY,
              email text NOT NULL,
              username text NOT NULL
            )",
          [],
          conduit_db_query_options(),
        )
        erl_query(
          "CREATE SEQUENCE users_id_seq OWNED BY users.id",
          [],
          conduit_db_query_options(),
        )
        erl_query(
          "ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass)",
          [],
          conduit_db_query_options(),
        )
        Nil
      },
    ),
  ]
}
