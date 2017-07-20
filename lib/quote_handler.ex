
# A cowboy handler for serving a single dynamic wepbage. No templates are used; the
# HTML is all generated within the handler.
defmodule QuoteHandler do

  # We are using the plain HTTP handler.  See the documentation here:
  #     http://ninenines.eu/docs/en/cowboy/HEAD/manual/cowboy_http_handler/
  #
  # All cowboy HTTP handlers require an init() function, identifies which
  # type of handler this is and returns an initial state (if the handler
  # maintains state).  In a plain http handler, you just return a
  # 3-tuple with :ok.  We don't need to track a  state in this handler, so
  # we're returning the atom :no_state.
  def init(_type, req, []) do
    {:ok, req, :no_state}
  end


  # In a cowboy handler, the handle/2 function does the work. It should return
  # a 3-tuple with :ok, a request object (containing the reply), and the current
  # state.
  def handle(request, state) do

    {:ok, post_vals, req} = :cowboy_req.body_qs(request)
    user_name = :proplists.get_value("user_name", post_vals)
    response_url = :proplists.get_value("response_url", post_vals)
    text = :proplists.get_value("text", post_vals)
    value = cond do
      String.length(text) == 0 ->
        1.0
      true ->
        {val, _} = Float.parse(text)
        Float.round(val, 2)
    end	

    # construct a reply, using the cowboy_req:reply/4 function.
    #
    # reply/4 takes three arguments:
    #   * The HTTP response status (200, 404, etc.)
    #   * A list of 2-tuples representing headers
    #   * The body of the response
    #   * The original request
    { :ok, reply } = :cowboy_req.reply(

      # status code
      200,

      # headers
      [ {"content-type", "text/plain"} ],

      # body of reply.
      build_body(request, response_url, user_name, value),

      # original request
      request
    )

    # handle/2 returns a tuple starting containing :ok, the reply, and the
    # current state of the handler.
    {:ok, reply, state}
  end

  # Termination handler.  Usually you don't do much with this.  If things are breaking,
  # try uncommenting the output lines here to get some more info on what's happening.
  def terminate(reason, request, state) do
    :ok
  end

  def build_body(request, response_url, user_name, value) do

    handler = spawn(__MODULE__, :query_results, [[], response_url, user_name, value])

    response = HTTPotion.get "query.yahooapis.com/v1/public/yql?q=select%20*%20from%20htmlstring%20where%20url%3D%27www.google.com%2Ffinance%2Fconverter%3Fa%3D1%26from%3DUSD%26to%3DBRL%27%20and%20xpath%3D%27%2F%2F*%5B%40id%3D\"currency_converter_result\"%5D%2Fspan%2Ftext()%27&format=json&callback=&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys",
      [stream_to: handler]

    ""
  end

  def process(json, response_url, user_name, value) do

    data = json |> JSX.decode

    query = elem(data, 1)

    result = query["query"]["results"]["result"]
 
    {price, _} = Float.parse(result)

    result = price * value

    response_text = cond do
       value == 1.0 ->
         "#{user_name}: #{result}"
       true ->
         "#{Float.to_string(value, [decimals: 2])} USD is #{Float.to_string(result, [decimals: 2])} BRL"
    end

    payload = """
      {
         "text": "#{response_text}",
         "icon_emoji": ":heavy_dollar_sign:",
         "username": "USD-to-BRL"
      }
    """

    reply_command payload, response_url, value
  end

  def reply_command(payload, response_url, 1.0) do
    HTTPotion.post "https://hooks.slack.com/services/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",
      [body: "payload=#{payload}", headers: ["Content-Type": "application/x-www-form-urlencoded"]]
  end

  def reply_command(payload, response_url, value) do
    HTTPotion.post response_url,
      [body: "payload=#{payload}", headers: ["Content-Type": "application/x-www-form-urlencoded"]]
  end

  def query_results(json, response_url, user_name, value) do

    receive do

      %HTTPotion.AsyncChunk{ id: _id, chunk: _chunk } ->
        data = _chunk |> to_string
        json = json ++ data
        query_results json, response_url, user_name, value

      %HTTPotion.AsyncEnd{ id: _id } ->
        process json, response_url, user_name, value

    end

  end

end
