defmodule QuoteHandler do

  def init(_type, req, []) do
    {:ok, req, :no_state}
  end

  def handle(request, state) do

    {:ok, post_vals, _} = :cowboy_req.body_qs(request)
    user_name = :proplists.get_value("user_name", post_vals)
    response_url = :proplists.get_value("response_url", post_vals)
    text = :proplists.get_value("text", post_vals)

    {cmd_name, _} = :cowboy_req.qs_val("cmd_name", request, "USD-to-BRL")
    {from, _} = :cowboy_req.qs_val("from", request, "USD")
    {to, _} = :cowboy_req.qs_val("to", request, "BRL")

    p_value = cond do
      String.length(text) == 0 ->
        1.0
      true ->
        {val, _} = Float.parse(text)
        Float.round(val, 2)
    end

    { :ok, reply } = :cowboy_req.reply(

      # status code
      200,

      # headers
      [ {"content-type", "text/plain"} ],

      # body of reply.
      build_body(request, cmd_name, response_url, from, to, user_name, p_value),

      # original request
      request
    )

    {:ok, reply, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end

  def build_body(_request, cmd_name, response_url, from, to, user_name, value) do

    IO.puts "https://transferwise.com/br/currency-converter/#{from}-to-#{to}-rate"

    {:ok, response} = Tesla.get "https://transferwise.com/br/currency-converter/#{from}-to-#{to}-rate"

    process response.body, cmd_name, response_url, from, to, user_name, value

    ""
  end

  def process(response, cmd_name, response_url, from, to, user_name, value) do
    matches = Regex.named_captures(~r/id="rate"\svalue="(?<value>[.0-9]*)"/, response)

    {price, _} = Float.parse(matches["value"])

    result = price * value

    response_text = cond do
       value == 1.0 ->
         "#{user_name}: #{result}"
       true ->
         "#{:erlang.float_to_binary(value, [decimals: 2])} #{from} is #{:erlang.float_to_binary(result, [decimals: 2])} #{to}"
    end

    response_type = cond do
        value == 1.0 ->
          "in_channel"
        true ->
          "ephemeral"
    end

    payload = """
      {
         "response_type": "#{response_type}",
         "text": "#{response_text}",
         "icon_emoji": ":heavy_dollar_sign:",
         "username": "#{cmd_name}"
      }
    """

    reply_command payload, response_url, value
  end

  def reply_command(payload, response_url, 1.0) do
    # "https://hooks.slack.com/services/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"
    Tesla.post response_url, "payload=#{payload}", headers: ["Content-Type": "application/x-www-form-urlencoded"]
  end

  def reply_command(payload, response_url, _value) do
    Tesla.post response_url, "payload=#{payload}", headers: ["Content-Type": "application/x-www-form-urlencoded"]
  end

end
