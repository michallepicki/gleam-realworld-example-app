import gleam/result
import gleam/otp/supervisor
import gleam/otp/actor
import gleam/otp/process
import gleam/dynamic.{Dynamic}
import gleam/http/elli
import conduit/db
import conduit/web

fn init(children) {
  children
  |> supervisor.add(supervisor.supervisor(fn(_args) {
    supervisor.wrap_erlang_start_result(db.run_pool("conduit_dev"))
  }))
  |> supervisor.add(supervisor.supervisor(fn(_args) {
    elli.start(web.service, on_port: 3000)
  }))
}

pub fn start(
  _mode: supervisor.ApplicationStartMode,
  _args: List(Dynamic),
) -> Result(process.Pid, actor.StartError) {
  init
  |> supervisor.start
  |> result.map(process.pid)
}

pub fn stop(_state: Dynamic) -> supervisor.ApplicationStop {
  supervisor.application_stopped()
}
