%%%-------------------------------------------------------------------
%%% @author Chen Slepher <slepheric@gmail.com>
%%% @copyright (C) 2018, Chen Slepher
%%% @doc
%%%
%%% @end
%%% Created : 17 May 2018 by Chen Slepher <slepheric@gmail.com>
%%%-------------------------------------------------------------------
-module(type_expansion).

%% API
-export([core/1, exported_types/1, expand/3, expand/6, preload_types/6]).

%%%===================================================================
%%% API
%%%===================================================================
%%%===================================================================
%%% API
%%%===================================================================
core(Module) ->
    DialyzerUtils = dialyzer_utils(),
    case code:get_object_code(Module) of
        {Module, _, Beam} ->
            DialyzerUtils:get_core_from_beam(Beam);
        error -> 
            error
    end.

%% from unexported function dialyzer_analysis_callgraph:exported_types_from_core/1
exported_types(Core) ->
    Attrs = cerl:module_attrs(Core),
    ExpTypes1 = [cerl:concrete(L2) || {L1, L2} <- Attrs, cerl:is_literal(L1),
                                      cerl:is_literal(L2),
                                      cerl:concrete(L1) =:= 'export_type'],
    ExpTypes2 = lists:flatten(ExpTypes1),
    M = cerl:atom_val(cerl:module_name(Core)),
    sets:from_list([{M, F, A} || {F, A} <- ExpTypes2]).

expand(Module, Type, Arity) ->
    ModulesLoaded = maps:new(),
    Types = sets:new(),
    RecTable = ets:new(rec_table, [protected]),
    case expand(Module, Type, Arity, ModulesLoaded, Types, RecTable) of
        {ok, {Type, _ModulesLoaded, _TypesVisited}} ->
            {ok, Type};
        error ->
            error
    end.

expand(Module, Type, Arity, ModulesLoaded, Types, RecTable) ->
    case preload_types(Module, Type, Arity, ModulesLoaded, Types, RecTable) of
        {ok, {NModulesLoaded, NTypes}} ->
            case table_find_form(Module, Type, Arity, RecTable) of
                {ok, Form} ->
                    ExpandedForm = t_from_form(Form, Module, Type, Arity, NTypes, RecTable),
                    {ok, {ExpandedForm, NModulesLoaded, NTypes}};
                _ ->
                    error
            end;
        error ->
            error
    end.

preload_types(Module, Type, Arity, ModulesLoaded, Types, RecTable) ->
    case types_visited(Module, ModulesLoaded, Types, RecTable) of
        {ok, {TypesVisited, NModulesLoaded, NTypes}} ->
            case ordsets:is_element({Type, Arity}, TypesVisited) of
                false ->
                    case table_find_rec_and_form(Module, Type, Arity, RecTable) of
                        {ok, {RecMap, Form}} ->
                            NTypesVisited = ordsets:add_element({Module, Type, Arity}, TypesVisited),
                            NNModulesLoaded = maps:put(Module, NTypesVisited, NModulesLoaded),
                            {ok, preload_form_types(Form, Module, RecMap, NNModulesLoaded, NTypes, RecTable)};
                        error ->
                            error
                    end;
                true ->
                    {ok, {ModulesLoaded, NTypes}}
            end;
        error ->
            error
    end.

preload_form_types(Form, Module, RecMap, ModulesLoaded, Types, RecTable) ->
    ast_traverse:reduce(
      fun(pre, Node, {ModulesLoadedAcc, TypesAcc}) ->
              preload_node_types(Node, Module, RecMap, ModulesLoadedAcc, TypesAcc, RecTable);
         (_, _, Acc) ->
              Acc
      end, {ModulesLoaded, Types}, Form).

preload_node_types(
  {remote_type, Line, [{atom, _, RemoteModule}, {atom, _, Type}, Args]},
  Module, _RecMap, ModulesLoaded, Types, RecTable) ->
    Arity = length(Args),
    case preload_types(RemoteModule, Type, Arity, ModulesLoaded, Types, RecTable) of
        {ok, Val} ->
            Val;
        error ->
            exit({RemoteModule, Type, Args, Module, Line})
    end;

preload_node_types(
  {user_type, Line, Type, Args}, Module, RecMap, ModulesLoaded, Types, RecTable) ->
    Arity = length(Args),
    case map_find_form(Type, Arity, RecMap) of
        {ok, Form} ->
            preload_form_types(Form, Module, RecMap, ModulesLoaded, Types, RecTable);
        error ->
            exit({Module, Type, Args, Module, Line})
    end;

preload_node_types(_Form, _Module, _RecMap, ModulesLoaded, Types, _RecTable) ->
    {ModulesLoaded, Types}.

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------

%%%===================================================================
%%% Internal functions
%%%===================================================================
types_visited(Module, ModulesLoaded, Types, RecTable) ->
    case maps:find(Module, ModulesLoaded) of
        error ->
            TypesVisited = ordsets:new(),
            NModulesLoaded = maps:put(Module, TypesVisited, ModulesLoaded),
            case types_and_rec_map(Module) of
                {ok, {ModuleTypes, RecMap}} ->
                    NTypes = sets:union(Types, ModuleTypes),
                    ets:insert(RecTable, {Module, RecMap}),
                    {ok, {TypesVisited, NModulesLoaded, NTypes}};
                error ->
                    error
            end;
        {ok, TypesVisited} ->
            {ok, {TypesVisited, ModulesLoaded, Types}}
    end.

table_find_form(Module, Type, Arity, RecTable) ->
    case table_find_rec_and_form(Module, Type, Arity, RecTable) of
        {ok, {_RecMap, Form}} ->
            {ok, Form};
        error ->
            error
    end.

table_find_rec_and_form(Module, Type, Arity, RecTable) ->
    case ets:lookup(RecTable, Module) of
        [{Module, RecMap}] ->
            case map_find_form(Type, Arity, RecMap) of
                {ok, Form} ->
                    {ok, {RecMap, Form}};
                error ->
                    error
            end;
        [] ->
            error
  end.

map_find_form(Type, Arity, RecMap) ->
    case maps:find({type, Type, Arity}, RecMap) of
        {ok, {{_Module, _Line, Form, _Args}, _}} ->
            {ok, Form};
        _ ->
            error
    end.

types_and_rec_map(Module) ->
    DialyzerUtils = dialyzer_utils(),
    case core(Module) of
        {ok, Core} ->
            Types = exported_types(Core),
            case DialyzerUtils:get_record_and_type_info(Core) of
                {ok, RecMap} ->
                    {ok, {Types, RecMap}};
                _ ->
                    error
            end;
        _ ->
            error
    end.

t_from_form(Form, Module, Type, Arity, Types, RecTable) ->
    Cache = erl_types:cache__new(),
    VarTable = erl_types:var_table__new(),
    TypeKey = {type, {Module, Type, Arity}},
    {ExpandedForm, _Cache} =
        erl_types:t_from_form(Form, Types, TypeKey, RecTable, VarTable, Cache),
    ExpandedForm.

dialyzer_utils() ->
    case lists:member({get_core_from_beam, 1}, dialyzer_utils:module_info(exports)) of
        true ->
            dialyzer_utils;
        false ->
            dialyzer_utils_R20
    end.
