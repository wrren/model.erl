%%
%%  @author Warren Kenny
%%  @doc Provides a behaviour and convenience functions for interacting with
%%  models stored in mnesia tables.
%%
-module( model ).
-author( "Warren Kenny <warren.kenny@gmail.com>" ).

%% Initialization and Installation
-export( [init/2, init/3] ).
%% Querying
-export( [save/1, upsert/2, list/1, find/2, find/3, next_id/1] ).
%% Table Management
-export( [truncate/1, drop/1] ).

%%
%%	Number of milliseconds to wait until tables are available
%%
-define( WAIT_TIME, 5000 ).

-type model()   :: module().

%%
%%	All models should have a table installation function
%%
-callback install( Nodes :: list( node() ) ) -> { atomic, ok } | { error, term() }.

%%
%%  @doc Initialize the database schema, storing mnesia files in the given directory. The
%%  provided list of models will be installed once the schema has been initialized.
%%
-spec init( [node()], [model()], [filename:name_all()] ) -> ok | { error, term() }.
init( Nodes, Models, Directory ) ->
	application:set_env( mnesia, dir, Directory ),
	init( Nodes, Models ).

%%
%%  @doc Initialize the database schema. The provided list of models will be installed 
%%  once the schema has been initialized.
%%
-spec init( [node()], [model()] ) -> ok | { error, term() }.
init( Nodes, Models ) ->
    case model_schema:init( Nodes ) of
        ok                  -> install_models( Nodes, Models );
        { error, Reason }   -> { error, Reason }
    end.

%%
%%	Wait for installed tables to become available
%%
-spec wait_for_tables( [model()] ) -> ok.
wait_for_tables( Models ) ->
	mnesia:wait_for_tables(	Models, ?WAIT_TIME ),
	ok.

%%
%%	@doc Install the given list of models on the specified nodes
%%
-spec install_models( [node()], [module()] ) -> { error, term() } | ok.
install_models( Nodes, Models ) ->
    case lists:filtermap( fun( Model ) ->
        case Model:install( Nodes ) of
            { atomic, ok }	-> 
                false;
            { aborted, { already_exists, _Table } } ->
                false;
            { aborted, Reason } ->
                { true, { error, Reason } }
        end end, Models ) of
        [{ error, Reason } | _] -> { error, Reason };
        _                       -> wait_for_tables( Models )
    end.