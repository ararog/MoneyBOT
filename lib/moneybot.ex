defmodule MoneyBOT do

  def start(_type, _args) do

    # Compile takes as argument a list of tuples that represent hosts to
    # match against.So, for example if your DNS routed two different
    # hostnames to the same server, you could handle requests for those
    # names with different sets of routes. See "Compilation" in:
    #      http://ninenines.eu/docs/en/cowboy/HEAD/guide/routing/
    dispatch = :cowboy_router.compile([

      # :_ causes a match on all hostnames.  So, in this example we are treating
      # all hostnames the same. You'll probably only be accessing this
      # example with localhost:8080.
      { :_,

        # The following list specifies all the routes for hosts matching the
        # previous specification.  The list takes the form of tuples, each one
        # being { PathMatch, Handler, Options}
        [

          # Serve a dynamic page with a custom handler
          # When a request is sent to "/", pass the request to the custom handler
          # defined in module QuoteHandler.
          {"/", QuoteHandler, []},
      ]}
    ])
    { :ok, _ } = :cowboy.start_http(:http,
                                    100,
                                   [{:port, 8080}],
                                   [{ :env, [{:dispatch, dispatch}]}]
                                   )
  end
end
