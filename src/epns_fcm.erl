-module(epns_fcm).

-export([push/1]).

%% -------------------------------------------------------------------
%% @doc
%% Send FCM push notification
%% @end
%% -------------------------------------------------------------------
-spec push(Data :: maps:map()) -> Result :: tuple().

push(#{playload := P, key := K, url := U}) ->
    httpc:set_options([{keep_alive_timeout, 0}]),
    {_, Resp} = httpc:request(post, {U, [{"Authorization", "key=" ++ K}], "application/json", jsx:encode(P)}, [], []),
    handle_status(get_http_resp_code(Resp), get_http_resp_body(Resp)).

%% -------------------------------------------------------------------
%% @private
%% @doc
%% Handler status code
%% @end
%% -------------------------------------------------------------------
-spec handle_status(StatusCode :: integer(), RespBody :: maps:map()) -> Result :: tuple().

handle_status(200, RespBody) ->
    jsx:decode(list_to_binary(RespBody), [return_maps]);

handle_status(201, _) ->
    {ok, #{multicast_id=> <<>>, success => 1, failure => 0, canonical_ids => 0, results => []}};

handle_status(400, RespBody) ->
    {error, RespBody};

handle_status(401, _) ->
    {error, auth_error};

handle_status(500, _) ->
    {error, server_error};

handle_status(_, Reason) ->
    {error, Reason}.

%% -------------------------------------------------------------------
%% @private
%% @doc
%% Returns HTTP response code
%% @end
%% -------------------------------------------------------------------
-spec get_http_resp_code(HttpcResult :: tuple()) -> Code :: pos_integer().

get_http_resp_code({{_, Code, _}, _, _}) ->
    Code;

get_http_resp_code({Code, _}) ->
    Code;

get_http_resp_code(_) ->
    0.

%% -------------------------------------------------------------------
%% @private
%% @doc
%% Returns HTTP response body
%% @end
%% -------------------------------------------------------------------
-spec get_http_resp_body(HttpcResult :: tuple()) -> Body :: list().

get_http_resp_body({_, _, Body}) ->
    Body;

get_http_resp_body({_, Body}) ->
    Body;

get_http_resp_body(_) ->
    "Not Implemented".
