-module( model_schema ).
-author( "Warren Kenny <warren.kenny@gmail.com>" ).
-export( [init/1, delete/1] ).

%%
%%  @doc Initialize the mnesia table schema
%%
-spec init( [node()] ) -> ok | { error, term() }.
init( Nodes ) ->
    case mnesia:system_info( tables ) of
        [schema] ->
            application:stop( mnesia ),
            case mnesia:create_schema( Nodes ) of
                ok ->
                    application:start( mnesia ),
                    init( Nodes );

                { error, { _Node, { already_exists, _TableName } } } ->
                    ok;

                { error, Reason } -> 
                    { error, Reason }
            end;
        
        _Tables ->
            ok
    end.

%%
%%	@doc Delete the database schema from the given nodes
%%
-spec delete( [node()] ) -> ok | { error, term() }.
delete( Nodes ) ->
	mnesia:delete_schema( Nodes ).