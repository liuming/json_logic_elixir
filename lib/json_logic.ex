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

      iex> JsonLogic.apply(%{"map" => [ %{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]} ]}, %{"integers" => [1,2,3,4,5]})
      [2,4,6,8,10]

      iex> JsonLogic.apply(%{"filter" => [ %{"var" => "integers"}, %{">" => [%{"var" => ""}, 2]} ]}, %{"integers" => [1,2,3,4,5]})
      [3,4,5]

      iex> JsonLogic.apply(%{"reduce" => [ %{"var" => "integers"}, %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]} ]}, %{"integers" => [1,2,3,4,5]})
      15

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

  @operations %{
    "var" => :operation_var,
    "if" => :operation_if,
    "==" => :operation_similar,
    "!=" => :operation_not_similar,
    "===" => :operation_equal,
    "!==" => :operation_not_equal,
    "!" => :operation_not,
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
    "in" => :operation_in,
    "cat" => :operation_cat,
    "log" => :operation_log,
  }

  @doc """
  Apply JsonLogic.
  Accepts logic and data arguments as Map
  Returns resolved result as Map
  """
  @spec apply(Map.t, Map.t) :: Map.t
  def apply(logic, data \\ nil)

  # operations selector branch of apply
  def apply(logic, data) when is_map(logic) and logic != %{} do
    operation_name = logic |> Map.keys |> List.first
    values = logic |> Map.values |> List.first
    Kernel.apply(__MODULE__, @operations[operation_name], [values, data])
  end

  # conclusive branch of apply
  def apply(logic, _) do
    logic
  end

  @doc false
  def operation_var("", data) do
    Enum.at(data, 0)
  end

  @doc false
  def operation_var(path, data) when is_binary(path) do
    [variable_name | names] = path |> String.split(".")

    fetched_data = if is_list(data) do
      {index, _} = Integer.parse(variable_name)
      Enum.at(data, index)
    else
      data[variable_name]
    end

    case names do
      [] -> fetched_data
      _ -> operation_var(names |> Enum.join("."), fetched_data)
    end
  end

  @doc false
  def operation_var([path, default_key], data) do
    operation_var(path, data) || JsonLogic.apply(default_key, data)
  end

  @doc false
  def operation_var(index, data) when is_number(index) do
    Enum.at(data, index)
  end

  @doc false
  def operation_similar([left, right], data \\ nil) do
    JsonLogic.apply(left, data) == JsonLogic.apply(right, data)
  end

  @doc false
  def operation_not_similar([left, right], data \\ nil) do
    JsonLogic.apply(left, data) != JsonLogic.apply(right, data)
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
  def operation_not(condition, data) do
    case condition do
      [condition] -> !JsonLogic.apply(condition, data)
      condition -> !JsonLogic.apply(condition, data)
    end
  end

  @doc false
  # TODO: may need refactoring
  def operation_if(statements, data) do
    case statements do
      [last] -> JsonLogic.apply(last, data)
      [condition, yes, no] -> if JsonLogic.apply(condition, data), do: JsonLogic.apply(yes, data), else: JsonLogic.apply(no, data)
      [condition, yes | others] -> if JsonLogic.apply(condition, data), do: JsonLogic.apply(yes, data), else: operation_if(others, data)
      others -> operation_if(others, data)
    end
  end

  @doc false
  def operation_or(statements, data) do
    [first | others] = statements
    JsonLogic.apply(first, data) || operation_or(others, data)
  end

  @doc false
  def operation_and(statements, data) do
    [first | others] = statements

    first_result = JsonLogic.apply(first, data)
    if first_result && others != [] do
      operation_and(others, data)
    else
      first_result
    end
  end

  @doc false
  def operation_max(list, data) do
    list |> Enum.map(fn(x) -> JsonLogic.apply(x, data) end) |> Enum.max
  end

  @doc false
  def operation_min(list, data) do
    list |> Enum.map(fn(x) -> JsonLogic.apply(x, data) end) |> Enum.min
  end

  @doc false
  def operation_less_than([left, right], data) do
    JsonLogic.apply(left, data) < JsonLogic.apply(right, data)
  end

  @doc false
  def operation_less_than([left, middle, right | _], data) do
    JsonLogic.apply(left, data) < JsonLogic.apply(middle, data) &&
    JsonLogic.apply(middle, data) < JsonLogic.apply(right, data)
  end

  @doc false
  def operation_greater_than([left, right], data) do
    JsonLogic.apply(left, data) > JsonLogic.apply(right, data)
  end

  @doc false
  def operation_greater_than([left, middle, right | _], data) do
    JsonLogic.apply(left, data) > JsonLogic.apply(middle, data) &&
    JsonLogic.apply(middle, data) > JsonLogic.apply(right, data)
  end

  @doc false
  def operation_less_than_or_equal([left, right], data) do
    JsonLogic.apply(left, data) <= JsonLogic.apply(right, data)
  end

  @doc false
  def operation_less_than_or_equal([left, middle, right | _], data) do
    JsonLogic.apply(left, data) <= JsonLogic.apply(middle, data) &&
    JsonLogic.apply(middle, data) <= JsonLogic.apply(right, data)
  end

  @doc false
  def operation_greater_than_or_equal([left, right], data) do
    JsonLogic.apply(left, data) >= JsonLogic.apply(right, data)
  end

  @doc false
  def operation_greater_than_or_equal([left, middle, right | _], data) do
    JsonLogic.apply(left, data) >= JsonLogic.apply(middle, data) &&
    JsonLogic.apply(middle, data) >= JsonLogic.apply(right, data)
  end

  @doc false
  def operation_addition(numbers, data) do
    [first | rest] = numbers
    reduce_from = JsonLogic.apply(first, data)
    reduce_on = Enum.map(rest, fn(n) -> JsonLogic.apply(n, data) end)
    {_, result} = Enum.map_reduce(reduce_on, reduce_from, fn(n, total) -> {n, total + n} end)
    result
  end

  @doc false
  def operation_subtraction([first, last], data) do
    reduce_on = [JsonLogic.apply(last, data)]
    reduce_from = JsonLogic.apply(first, data)
    {_, result} = Enum.map_reduce(reduce_on, reduce_from, fn(n, total) -> {n, total - n} end)
    result
  end

  @doc false
  def operation_subtraction([first], data) do
    -JsonLogic.apply(first, data)
  end

  @doc false
  def operation_multiplication([first | rest], data) do
    reduce_on = Enum.map(rest, fn(n) -> JsonLogic.apply(n, data) end)
    reduce_from = JsonLogic.apply(first, data)
    {_, result} = Enum.map_reduce(reduce_on, reduce_from, fn(n, total) -> {n, total * n} end)
    result
  end

  @doc false
  def operation_division([first, last], data) do
    reduce_on = [JsonLogic.apply(last, data)]
    reduce_from = JsonLogic.apply(first, data)
    {_, result} = Enum.map_reduce(reduce_on, reduce_from, fn(n, total) -> {n, total / n} end)
    result
  end

  @doc false
  def operation_remainder([first, last], data) do
    Kernel.rem(JsonLogic.apply(first, data), JsonLogic.apply(last, data))
  end

  @doc false
  def operation_map([list, map_action], data) do
    JsonLogic.apply(list, data)
    |> Enum.map(fn(item) -> JsonLogic.apply(map_action, [JsonLogic.apply(item)]) end)
  end

  @doc false
  def operation_filter([list, filter_action], data) do
    JsonLogic.apply(list, data)
    |> Enum.filter(fn(item) -> JsonLogic.apply(filter_action, [JsonLogic.apply(item)]) end)
  end

  @doc false
  def operation_reduce([list, reduce_action], data) do
    [first | others] = JsonLogic.apply(list, data)
    others |> Enum.reduce(first, fn(item, accumulator) ->
        JsonLogic.apply(reduce_action, %{"current" => JsonLogic.apply(item), "accumulator" => accumulator})
      end)
  end

  @doc false
  def operation_in([member, list], data) when is_list(list) do
    members = list |> Enum.map(fn(m) -> JsonLogic.apply(m, data) end)
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
  def operation_cat(strings, data) do
    strings |> Enum.map(fn(s) -> JsonLogic.apply(s, data) end) |> Enum.join
  end

  @doc false
  def operation_log(logic, data) do
    JsonLogic.apply(logic, data)
  end
end
