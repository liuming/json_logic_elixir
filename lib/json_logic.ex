defmodule JsonLogic do
  @moduledoc """
  An Elixir implementation of [JsonLogic](http://jsonlogic.com/).

  ## Examples
      iex> JsonLogic.apply(nil)
      nil

      iex> JsonLogic.apply(%{})
      %{}

      iex> JsonLogic.apply(%{"var" => "key"}, %{"key" => "value"})
      "value"

      iex> JsonLogic.apply(%{"var" => "nested.key"}, %{"nested" => %{"key" => "value"}})
      "value"

      iex> JsonLogic.apply(%{"var" => ["none", "default"]}, %{"key" => "value"})
      "default"

      iex> JsonLogic.apply(%{"var" => 0}, ~w{a b})
      "a"

      iex> JsonLogic.apply(%{"==" => [1, 1]})
      true

      iex> JsonLogic.apply(%{"==" => [0, 1]})
      false

      iex> JsonLogic.apply(%{"!=" => [1, 1]})
      false

      iex> JsonLogic.apply(%{"!=" => [0, 1]})
      true

      iex> JsonLogic.apply(%{"===" => [1, 1]})
      true

      iex> JsonLogic.apply(%{"===" => [1, 1.0]})
      false

      iex> JsonLogic.apply(%{"===" => [1, %{"var" => "key"}]}, %{"key" => 1})
      true

      iex> JsonLogic.apply(%{"!==" => [1, 1.0]})
      true

      iex> JsonLogic.apply(%{"!==" => [1, 1]})
      false

      iex> JsonLogic.apply(%{"!" => true})
      false

      iex> JsonLogic.apply(%{"!" => false})
      true

      iex> JsonLogic.apply(%{"if" => [true, "yes", "no" ]})
      "yes"

      iex> JsonLogic.apply(%{"if" => [false, "yes", "no" ]})
      "no"

      iex> JsonLogic.apply(%{"if" => [false, "unexpected", false, "unexpected", "default" ]})
      "default"

      iex> JsonLogic.apply(%{"or" => [false, nil, "truthy"]})
      "truthy"

      iex> JsonLogic.apply(%{"or" => ["first", "truthy"]})
      "first"

      iex> JsonLogic.apply(%{"and" => [false, "falsy"]})
      false

      iex> JsonLogic.apply(%{"and" => [true, 1, "truthy"]})
      "truthy"

      iex> JsonLogic.apply(%{"max" => [1,2,3]})
      3

      iex> JsonLogic.apply(%{"min" => [1,2,3]})
      1

      iex> JsonLogic.apply(%{"<" => [0, 1]})
      true

      iex> JsonLogic.apply(%{"<" => [1, 0]})
      false

      iex> JsonLogic.apply(%{"<" => [0, 1, 2]})
      true

      iex> JsonLogic.apply(%{"<" => [0, 2, 1]})
      false

      iex> JsonLogic.apply(%{">" => [1, 0]})
      true

      iex> JsonLogic.apply(%{">" => [0, 1]})
      false

      iex> JsonLogic.apply(%{">" => [2, 1, 0]})
      true

      iex> JsonLogic.apply(%{">" => [2, 0, 1]})
      false

      iex> JsonLogic.apply(%{"<=" => [1, 1]})
      true

      iex> JsonLogic.apply(%{"<=" => [1, 0]})
      false

      iex> JsonLogic.apply(%{"<=" => [1, 1, 2]})
      true

      iex> JsonLogic.apply(%{"<=" => [1, 0, 2]})
      false

      iex> JsonLogic.apply(%{">=" => [1, 1]})
      true

      iex> JsonLogic.apply(%{">=" => [0, 1]})
      false

      iex> JsonLogic.apply(%{">=" => [1, 1, 0]})
      true

      iex> JsonLogic.apply(%{">=" => [0, 1, 2]})
      false

      iex> JsonLogic.apply(%{"+" => [1,2,3]})
      6

      iex> JsonLogic.apply(%{"+" => [2]})
      2

      iex> JsonLogic.apply(%{"-" => [7,4]})
      3

      iex> JsonLogic.apply(%{"-" => [2]})
      -2

      iex> JsonLogic.apply(%{"*" => [2,3,4]})
      24

      iex> JsonLogic.apply(%{"/" => [5,2]})
      2.5

      iex> JsonLogic.apply(%{"%" => [7, 3]})
      1

      iex> JsonLogic.apply(%{"map" => [ [1,2,3,4,5], %{"*" => [%{"var" => ""}, 2]} ]})
      [2,4,6,8,10]

      iex> JsonLogic.apply(%{"filter" => [ [1,2,3,4,5], %{">" => [%{"var" => ""}, 2]} ]})
      [3,4,5]

      iex> JsonLogic.apply(%{"reduce" => [ [1,2,3,4,5], %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]}, 0]})
      15

      iex> JsonLogic.apply(%{"all" => [ [1,2,3], %{">" => [ %{"var" => ""}, 0 ]} ]})
      true

      iex> JsonLogic.apply(%{"all" => [ [-1,2,3], %{">" => [ %{"var" => ""}, 0 ]} ]})
      false

      iex> JsonLogic.apply(%{"none" => [ [1,2,3], %{"<" => [ %{"var" => ""}, 0 ]} ]})
      true

      iex> JsonLogic.apply(%{"none" => [ [-1,2,3], %{"<" => [ %{"var" => ""}, 0 ]} ]})
      false

      iex> JsonLogic.apply(%{"some" => [ [-1,2,3], %{"<" => [ %{"var" => ""}, 0 ]} ]})
      true

      iex> JsonLogic.apply(%{"some" => [ [1,2,3], %{"<" => [ %{"var" => ""}, 0 ]} ]})
      false

      iex> JsonLogic.apply(%{"in" => ["sub", "substring"]})
      true

      iex> JsonLogic.apply(%{"in" => ["na", "substring"]})
      false

      iex> JsonLogic.apply(%{"in" => ["a", ["a", "b", "c"]]})
      true

      iex> JsonLogic.apply(%{"in" => ["z", ["a", "b", "c"]]})
      false

      iex> JsonLogic.apply(%{"cat" => ["a", "b", "c"]})
      "abc"

      iex> JsonLogic.apply(%{"log" => "string"})
      "string"
  """

  @falsey [0, "", [], nil, false]

  @base_operations %{
    "var" => :operation_var,
    "missing" => :operation_missing,
    "missing_some" => :operation_missing_some,
    "if" => :operation_if,
    "?:" => :operation_if,
    "==" => :operation_similar,
    "!=" => :operation_not_similar,
    "===" => :operation_equal,
    "!==" => :operation_not_equal,
    "!" => :operation_not,
    "!!" => :operation_not_not,
    "or" => :operation_or,
    "and" => :operation_and,
    "<" => :operation_less_than,
    ">" => :operation_greater_than,
    "<=" => :operation_less_than_or_equal,
    ">=" => :operation_greater_than_or_equal,
    "max" => :operation_max,
    "min" => :operation_min,
    "+" => :operation_addition,
    "-" => :operation_subtraction,
    "*" => :operation_multiplication,
    "/" => :operation_division,
    "%" => :operation_remainder,
    "map" => :operation_map,
    "filter" => :operation_filter,
    "reduce" => :operation_reduce,
    "all" => :operation_all,
    "none" => :operation_none,
    "some" => :operation_some,
    "merge" => :operation_merge,
    "in" => :operation_in,
    "cat" => :operation_cat,
    "substr" => :operation_substr,
    "log" => :operation_log
  }

  @typedoc """
  JsonLogic operations definition.
  Should be declared as `Map.t` with values format:

   - `"operation_name" => function_name`
   - `"operation_name" => {module, function_name}`

  """
  @type operations_definition :: %{binary => atom} | %{binary => {module, atom}}

  @doc false
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :operations, accumulate: true)

      # Prebuilding default list of operations
      unquote(__MODULE__).operations()
      |> Enum.each(fn {op, func_name} ->
        @operations {op, {unquote(__MODULE__), func_name}}
      end)

      def apply(logic, data \\ nil) do
        __MODULE__.operations()
        |> JsonLogic.apply_custom(logic, data)
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    ops =
      env.module
      |> Module.get_attribute(:operations)
      |> Enum.into(%{})

    quote do
      @doc false
      def operations(), do: unquote(Macro.escape(ops))
    end
  end

  @doc """
  Adds new custom JsonLogic operation.

  By default new operation will be added to list of default `JsonLogic` operations, so
  all existing operations will be available in your module.

  Note: you have to add `use JsonLogic` in your module before using `add_operation/3`

  ## Example:

      defmodule CustomJsonLogic do
        use JsonLogic

        JsonLogic.add_operation("plus", __MODULE__, :plus)

        def plus([a, b], _), do: a + b
      end

      CustomJsonLogic.apply(%{"plus" => [2, 3]}) # => 5
      CustomJsonLogic.apply(%{"+" => [2, 3]}) # default operation => 5

  Another function that will be exposed in your module is `operations/1` that will have list of
  custom operations defined for your module.
  """
  defmacro add_operation(operation_name, module, function_name) do
    quote do
      @operations {unquote(operation_name), {unquote(module), unquote(function_name)}}
    end
  end

  @doc """
  Gets list of predefined JsonLogic operations.
  """
  @spec operations() :: operations_definition()
  def operations(), do: @base_operations

  @doc """
  Apply JsonLogic.
  Accepts logic and data arguments as Map
  Returns resolved result as Map
  """
  @spec apply(Map.t(), Map.t()) :: Map.t()
  def apply(logic, data \\ nil)

  # operations selector branch of apply
  def apply(logic, data) when is_map(logic) and logic != %{},
    do: apply_custom(@base_operations, logic, data)

  # conclusive branch of apply
  def apply(logic, _),
    do: logic

  @doc """
  Apply JsonLogic with custom list of operations.

  Accepts logic and data arguments as Map.
  Returns resolved result as Map.

  For example:

      defmodule CustomJsonLogic do

        def plus([a, b], data \\ nil), do: a + b

      end

      %{
        "plus" => {CustomJsonLogic, :plus}
      }
      |> JsonLogic.apply_custom(%{"plus" => [2, 3]}) # will return 5


  Extending default operations is possible using `JsonLogic.operations()` function.
  Note: if might override default operation by passing exising `operation_name`.

  For example:

      defmodule CustomJsonLogic do

        @custom_operations %{
          "plus" => {__MODULE__, :plus}
        }

        def operations(),
          do: Map.marge(JsonLogic.operations(), @custom_operations)

        def plus([a, b], _), do: a + b

      end

      CustomJsonLogic.operations()
      |> JsonLogic.apply_custom([2, 3]) # Will return 5

  """
  @spec apply_custom(operations_definition(), Map.t(), Map.t() | nil) :: Map.t()
  def apply_custom(operations, logic, data \\ nil)

  def apply_custom(operations, logic, data) when is_map(operations) and operations != %{} do
    operation_name = logic |> Map.keys() |> List.first()
    values = logic |> Map.values() |> List.first()

    case Map.fetch(operations, operation_name) do
      {:ok, {module, value}} -> Kernel.apply(module, value, [values, data])
      {:ok, value} -> Kernel.apply(__MODULE__, value, [values, data])
      :error -> raise "Unrecognized operation `#{operation_name}`"
    end
  end

  def apply_custom(_, logic, _),
    do: logic

  @doc false
  def operation_var("", data) do
    data
  end

  @doc false
  def operation_var([path, default_key], data) do
    operation_var(path, data) || JsonLogic.apply(default_key, data)
  end

  @doc false
  def operation_var([path], data) do
    operation_var(path, data)
  end

  @doc false
  # TODO: may need refactoring
  def operation_var(path, data) when not is_number(path) do
    case JsonLogic.apply(path, data) do
      string when is_binary(string) ->
        string
        |> String.split(".")
        |> Enum.reduce(data, fn key, acc ->
          cond do
            is_nil(acc) ->
              nil

            is_list(acc) ->
              {index, _} = Integer.parse(key)
              Enum.at(acc, index)

            is_map(acc) ->
              Map.get(acc, key)

            true ->
              nil
          end
        end)

      _ ->
        data
    end
  end

  @doc false
  def operation_var(index, data) when is_number(index) do
    Enum.at(data, index)
  end

  @doc false
  def operation_missing(keys, data) when is_list(keys) and is_map(data) do
    Enum.filter(keys, fn key ->
      operation_var([key, :missing], data) == :missing
    end)
  end

  def operation_missing(keys, _data) when is_list(keys) do
    keys
  end

  def operation_missing(keys, data) do
    case JsonLogic.apply(keys, data) do
      list when is_list(list) ->
        operation_missing(list, data)

      elem ->
        operation_missing([elem], data)
    end
  end

  def operation_missing_some([min, keys], data) do
    case operation_missing(keys, data) do
      list when length(keys) - length(list) < min ->
        list

      _ ->
        []
    end
  end

  @doc false
  def operation_similar([left, right], data \\ nil) do
    {op1, op2} =
      cast_comparison_operator(JsonLogic.apply(left, data), JsonLogic.apply(right, data))

    op1 == op2
  end

  @doc false
  def operation_not_similar([left, right], data \\ nil) do
    {op1, op2} =
      cast_comparison_operator(JsonLogic.apply(left, data), JsonLogic.apply(right, data))

    op1 != op2
  end

  @doc false
  def operation_equal([left, right], data \\ nil) do
    JsonLogic.apply(left, data) === JsonLogic.apply(right, data)
  end

  @doc false
  def operation_not_equal([left, right], data \\ nil) do
    JsonLogic.apply(left, data) !== JsonLogic.apply(right, data)
  end

  @doc false
  def operation_not_not([condition], data) do
    case JsonLogic.apply(condition, data) do
      value when value in @falsey -> false
      _truthy -> true
    end
  end

  def operation_not_not(condition, data) do
    operation_not_not([condition], data)
  end

  @doc false
  def operation_not(condition, data) do
    !operation_not_not(condition, data)
  end

  @doc false
  def operation_if([], _data) do
    nil
  end

  def operation_if([last], data) do
    JsonLogic.apply(last, data)
  end

  @doc false
  def operation_if([condition, yes], data) do
    case JsonLogic.apply(condition, data) do
      value when value in @falsey -> nil
      _ -> JsonLogic.apply(yes, data)
    end
  end

  @doc false
  def operation_if([condition, yes, no], data) do
    case JsonLogic.apply(condition, data) do
      value when value in @falsey -> JsonLogic.apply(no, data)
      _ -> JsonLogic.apply(yes, data)
    end
  end

  @doc false
  def operation_if([condition, yes | others], data) do
    case JsonLogic.apply(condition, data) do
      value when value in @falsey -> operation_if(others, data)
      _ -> JsonLogic.apply(yes, data)
    end
  end

  @doc false
  def operation_or([first], data) do
    JsonLogic.apply(first, data)
  end

  def operation_or([first | others], data) do
    case JsonLogic.apply(first, data) do
      value when value in @falsey -> operation_or(others, data)
      other -> other
    end
  end

  @doc false
  def operation_and([first], data) do
    JsonLogic.apply(first, data)
  end

  def operation_and([first | others], data) do
    case JsonLogic.apply(first, data) do
      value when value in @falsey -> value
      _truthy -> operation_and(others, data)
    end
  end

  @doc false
  def operation_max(list, data) do
    list |> Enum.map(fn x -> JsonLogic.apply(x, data) end) |> Enum.max()
  end

  @doc false
  def operation_min(list, data) do
    list |> Enum.map(fn x -> JsonLogic.apply(x, data) end) |> Enum.min()
  end

  @doc false
  def operation_less_than([left, right], data) do
    {op1, op2} =
      cast_comparison_operator(JsonLogic.apply(left, data), JsonLogic.apply(right, data))

    op1 < op2
  end

  @doc false
  def operation_less_than([left, middle, right | _], data) do
    operation_less_than([left, middle], data) &&
      operation_less_than([middle, right], data)
  end

  @doc false
  def operation_greater_than([left, right], data) do
    !operation_less_than_or_equal([left, right], data)
  end

  @doc false
  def operation_greater_than([left, middle, right | _], data) do
    operation_greater_than([left, middle], data) &&
      operation_greater_than([middle, right], data)
  end

  @doc false
  def operation_less_than_or_equal([left, right], data) do
    {op1, op2} =
      cast_comparison_operator(JsonLogic.apply(left, data), JsonLogic.apply(right, data))

    op1 <= op2
  end

  @doc false
  def operation_less_than_or_equal([left, middle, right | _], data) do
    operation_less_than_or_equal([left, middle], data) &&
      operation_less_than_or_equal([middle, right], data)
  end

  @doc false
  def operation_greater_than_or_equal([left, right], data) do
    !operation_less_than([left, right], data)
  end

  @doc false
  def operation_greater_than_or_equal([left, middle, right | _], data) do
    operation_greater_than_or_equal([left, middle], data) &&
      operation_greater_than_or_equal([middle, right], data)
  end

  @doc false
  def operation_addition(numbers, data) when is_list(numbers) do
    numbers
    |> Enum.map(&JsonLogic.apply(&1, data))
    |> Enum.reduce(0, fn
      str, total when is_binary(str) ->
        if String.match?(str, ~r/\./) do
          {num, _} = Float.parse(str)
          total + num
        else
          {num, _} = Integer.parse(str)
          total + num
        end

      num, total ->
        total + num
    end)
  end

  def operation_addition(numbers, data) do
    operation_addition([numbers], data)
  end

  @doc false
  def operation_subtraction([first, last], data) do
    {op1, op2} =
      cast_comparison_operator(JsonLogic.apply(first, data), JsonLogic.apply(last, data))

    op1 - op2
  end

  @doc false
  def operation_subtraction([first], data) do
    -JsonLogic.apply(first, data)
  end

  @doc false
  def operation_multiplication(numbers, data) do
    numbers
    |> Enum.map(&JsonLogic.apply(&1, data))
    |> Enum.reduce(1, fn
      str, total when is_binary(str) ->
        if String.match?(str, ~r/\./) do
          {num, _} = Float.parse(str)
          total * num
        else
          {num, _} = Integer.parse(str)
          total * num
        end

      num, total ->
        total * num
    end)
  end

  @doc false
  def operation_division([first, last], data) do
    {op1, op2} =
      cast_comparison_operator(JsonLogic.apply(first, data), JsonLogic.apply(last, data))

    op1 / op2
  end

  @doc false
  def operation_remainder([first, last], data) do
    Kernel.rem(JsonLogic.apply(first, data), JsonLogic.apply(last, data))
  end

  @doc false
  def operation_map([list, map_action], data) do
    case JsonLogic.apply(list, data) do
      list when is_list(list) ->
        Enum.map(list, fn item -> JsonLogic.apply(map_action, item) end)

      _ ->
        []
    end
  end

  @doc false
  def operation_filter([list, filter_action], data) do
    JsonLogic.apply(list, data)
    |> Enum.filter(fn item ->
      operation_not_not(filter_action, item)
    end)
  end

  @doc false
  def operation_reduce([list, reduce_action], data) do
    operation_reduce([list, reduce_action, nil], data)
  end

  def operation_reduce([list, reduce_action, first], data) do
    eval_first = JsonLogic.apply(first, data)

    case JsonLogic.apply(list, data) do
      list when is_list(list) ->
        Enum.reduce(list, eval_first, fn item, accumulator ->
          JsonLogic.apply(reduce_action, %{"current" => item, "accumulator" => accumulator})
        end)

      _ ->
        first
    end
  end

  @doc false
  def operation_all([list, test], data) do
    case JsonLogic.apply(list, data) do
      [] -> false
      list when is_list(list) -> Enum.all?(list, fn item -> JsonLogic.apply(test, item) end)
      _ -> false
    end
  end

  @doc false
  def operation_none([list, test], data) do
    JsonLogic.apply(list, data)
    |> Enum.all?(fn item -> Kernel.if(JsonLogic.apply(test, item), do: false, else: true) end)
  end

  @doc false
  def operation_some([list, test], data) do
    JsonLogic.apply(list, data)
    |> Enum.any?(fn item -> JsonLogic.apply(test, item) end)
  end

  def operation_merge([], _data), do: []

  def operation_merge([elem | rest], data) do
    case JsonLogic.apply(elem, data) do
      list when is_list(list) ->
        list ++ operation_merge(rest, data)

      elem ->
        [elem | operation_merge(rest, data)]
    end
  end

  def operation_merge(elem, data) do
    [JsonLogic.apply(elem, data)]
  end

  @doc false
  def operation_in([member, list], data) when is_list(list) do
    members = list |> Enum.map(fn m -> JsonLogic.apply(m, data) end)
    Enum.member?(members, JsonLogic.apply(member, data))
  end

  @doc false
  def operation_in([substring, string], data) when is_binary(string) do
    String.contains?(string, JsonLogic.apply(substring, data))
  end

  @doc false
  def operation_in([_, from], _) when is_nil(from) do
    false
  end

  @doc false
  def operation_in([find, from], data) do
    operation_in([JsonLogic.apply(find, data), JsonLogic.apply(from, data)], data)
  end

  @doc false
  def operation_cat(strings, data) when is_list(strings) do
    strings |> Enum.map(fn s -> JsonLogic.apply(s, data) end) |> Enum.join()
  end

  def operation_cat(string, data) do
    JsonLogic.apply(string, data) |> to_string
  end

  @doc false
  def operation_substr([string, offset], data) do
    string
    |> JsonLogic.apply(data)
    |> String.slice(offset..-1)
  end

  def operation_substr([string, offset, length], data) when length >= 0 do
    string
    |> JsonLogic.apply(data)
    |> String.slice(offset, length)
  end

  def operation_substr([string, offset, length], data) do
    string
    |> JsonLogic.apply(data)
    |> String.slice(offset..(length - 1))
  end

  @doc false
  def operation_log(logic, data) do
    JsonLogic.apply(logic, data)
  end

  defp cast_comparison_operator(op1, op2) when is_number(op1) and is_binary(op2) do
    {num_op2, _} = Float.parse(op2)
    {op1, num_op2}
  end

  defp cast_comparison_operator(op1, op2) when is_binary(op1) and is_number(op2) do
    {num_op1, _} = Float.parse(op1)
    {num_op1, op2}
  end

  defp cast_comparison_operator(op1, op2), do: {op1, op2}
end
