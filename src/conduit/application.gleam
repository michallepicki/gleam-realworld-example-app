import gleam/otp/supervisor
import gleam/otp/actor
import gleam/otp/process
import gleam/dynamic.{Dynamic}
import gleam/http/elli
import conduit/db/setup as db_setup
import conduit

fn init(children) {
  children
  |> supervisor.add(supervisor.worker(fn(_args) {
    case db_setup.run_conduit_db_pool("conduit_dev") {
      Ok(pid) -> Ok(process.null_sender(pid))
      Error(reason) -> Error(actor.InitCrashed(reason))
    }
  }))
  |> supervisor.add(supervisor.worker(fn(_args) {
    case elli.start(conduit.service, on_port: 3000) {
      Ok(pid) -> Ok(process.null_sender(pid))
      Error(reason) -> Error(actor.InitCrashed(reason))
    }
  }))
}

pub fn start(
  _mode: supervisor.ApplicationStartMode,
  _args: List(Dynamic),
) -> supervisor.ErlangStartResult {
  init
  |> supervisor.start
  |> supervisor.to_erlang_start_result
}

pub fn stop(_state: Dynamic) {
  supervisor.application_stopped()
}
