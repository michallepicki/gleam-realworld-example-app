-module(conduit_app).

-behaviour(application).
-behaviour(supervisor).

-export([start/2, stop/1, init/1]).

start(_StartType, _StartArgs) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

stop(_State) ->
    ok.

init([]) ->
    PostgresHost = os:getenv("POSTGRES_HOST","localhost"),
    PostgresPortString = os:getenv("POSTGRES_PORT","5432"),
    PostgresPort = list_to_integer(PostgresPortString),
    PostgresUser = os:getenv("POSTGRES_USER","postgres"),
    PostgresPassword = os:getenv("POSTGRES_PASSWORD","postgres"),
    SupFlags = #{strategy => one_for_all},
    ChildSpecs = [
        #{
            id => conduit_elli_service,
            start => {gleam@http@elli, start, [fun conduit:service/1, 3000]},
            modules => [elli]
        },
        #{
           id => conduit_pgo_pool,
           start => {pgo_pool, start_link, [default, #{
               host => PostgresHost,
               port => PostgresPort,
               user => PostgresUser,
               password => PostgresPassword,
               database => "conduit_dev"
            }]},
           shutdown => 1000
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.
