-module(mod_prometheus).
%%%-------------------------------------------------------------------
%%% @author Skythet
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Sep 2017 3:37 PM
%%%-------------------------------------------------------------------
-author("Skythet").

%% API
-export([start/2,
  stop/1,
  process/2
]).

-define(_ENABLED_STATS, [
  total_run_queue_lengths,
  total_active_tasks,
  context_switches,
  garbage_collection,
  io,
  reductions,
  runtime,
  allocated_areas,
  port_count,
  port_limit,
  process_count,
  process_limit
]).

start(_Host, _Opts) ->
  ok.

stop(_Host) ->
  ok.

process(_, _) ->
  Node = erlang:node(),
  Metrics = memory_metrics(erlang:memory(), Node) ++
    statistics(?_ENABLED_STATS, Node),
  {200, [{<<"Content-Type">>, <<"text/plain">>}], list_to_bitstring(Metrics)}.


memory_metrics([], _) ->
  [];
memory_metrics([{Type, Value} | MemoryInfoTail], Node) ->
  Metric = io_lib:format("ejabberd_memory_~s_bytes{node=\"~w\"} ~w~n", [Type, Node, Value]),
  [Metric, memory_metrics(MemoryInfoTail, Node)].


metric_format(MetricName, Node, Value) ->
  io_lib:format("ejabberd_~s{node=\"~w\"} ~w~n", [MetricName, Node, Value]).


statistics([], _) ->
  [];
statistics([StatName | StatsTail], Node) ->
  [statistic(StatName, Node), statistics(StatsTail, Node)].


statistic(reductions, Node) ->
  {TotalReductions, ReductionsSinceLastCall} = erlang:statistics(reductions),
  [
    metric_format("reductions_total", Node, TotalReductions),
    metric_format("reductions_since_last_call", Node, ReductionsSinceLastCall)
  ];

statistic(schedulers_count, Node) ->
  SchedulersCount = erlang:system_info(schedulers_count),
  metric_format("schedulers_count", Node, SchedulersCount);

statistic(runtime, Node) ->
  {TotalRuntime, _} = erlang:statistics(runtime),
  metric_format("run_time_total_seconds", Node, TotalRuntime / 1000);

statistic(io, Node) ->
  {{input, InputBytes}, {output, OutputBytes}} = erlang:statistics(io),
  [metric_format("io_input_bytes", Node, InputBytes), metric_format("io_output_bytes", Node, OutputBytes)];

statistic(garbage_collection, Node) ->
  {GcsCount, WordsReclaimed, _} = erlang:statistics(garbage_collection),
  [metric_format("gc_number", Node, GcsCount), metric_format("gc_words_reclaimed_total", Node, WordsReclaimed)];

statistic(context_switches, Node) ->
  {ContextSwitches, 0} = erlang:statistics(context_switches),
  metric_format(context_switches, Node, ContextSwitches);

statistic(Metric, Node) when
    Metric == port_count;
    Metric == port_limit;
    Metric == process_count;
    Metric == process_limit
  ->
  metric_format(Metric, Node, erlang:system_info(Metric));

statistic(allocated_areas, Node) ->
  allocated_areas_metrics(erlang:system_info(allocated_areas), Node);

statistic(StatName, Node) ->
  metric_format(StatName, Node, erlang:statistics(StatName)).


allocated_areas_metrics([], _) ->
  [];
allocated_areas_metrics([{Area, AllocatedBytes, UsedBytes} | MetricTail], Node) ->
  [
    metric_format(["allocated_areas_", atom_to_list(Area), "_bytes"], Node, AllocatedBytes),
    metric_format(["allocated_areas_", atom_to_list(Area), "_used_bytes"], Node, UsedBytes),
    allocated_areas_metrics(MetricTail, Node)
  ];
allocated_areas_metrics([{Area, AllocatedBytes} | MetricTail], Node) ->
  [
    metric_format(["allocated_areas_", atom_to_list(Area), "_bytes"], Node, AllocatedBytes),
    allocated_areas_metrics(MetricTail, Node)
  ].