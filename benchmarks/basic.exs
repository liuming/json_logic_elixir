defmodule Benchmarking do
  def resolving_value do
    JsonLogic.resolve(%{"var" => "key"}, %{"key" => "value"})
  end

  def resolving_nested_value do
    JsonLogic.resolve(%{"var" => "nested.key"}, %{"nested" => %{"key" => "value"}})
  end

  def simple_equals_not_equal do
    JsonLogic.resolve(%{"==" => [1, %{"var" => "key"}]}, %{"key" => 2})
  end

  def simple_equals_equal do
    JsonLogic.resolve(%{"==" => [1, %{"var" => "key"}]}, %{"key" => 1})
  end

  def map_multiplcation do
    JsonLogic.resolve(%{"map" => [[1,2,3,4,5], %{"*" => [%{"var" => ""}, 2]}]})
  end

  def nested_filter_comparison do
    JsonLogic.resolve(%{"filter" => [[1,2,3,4,5], %{">" => [%{"var" => ""}, 2]}]})
  end

  def reduce_list_and_accumulate do
    JsonLogic.resolve(%{
      "reduce" => [
        [1,2,3,4,5],
        %{
          "+" => [
            %{"var" => "current"},
            %{"var" => "accumulator"}
          ]
        },
        0
      ]
    })
  end
end

Benchee.run(
  %{
    "map_multiplcation" => &Benchmarking.map_multiplcation/0,
    "nested_filter_comparison" => &Benchmarking.nested_filter_comparison/0,
    "reduce_list_and_accumulate" => &Benchmarking.reduce_list_and_accumulate/0,
    "resolving_nested_value" => &Benchmarking.resolving_nested_value/0,
    "resolving_value" => &Benchmarking.resolving_value/0,
    "simple_equals_equal" => &Benchmarking.simple_equals_equal/0,
    "simple_equals_not_equal" => &Benchmarking.simple_equals_not_equal/0,
  },
  warmup: 1,
  time: 5,
  memory_time: 2,
  reduction_time: 2
)
