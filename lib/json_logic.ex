defmodule JsonLogic do
  @moduledoc """
  Documentation for JsonLogic.

  ## Examples
    iex> JsonLogic.apply(nil)
    nil

    iex> JsonLogic.apply(%{})
    %{}

    iex> JsonLogic.apply(%{"var" => "key"}, %{"key" => "value"})
    "value"

    iex> JsonLogic.apply(%{"var" => "nested.key"}, %{"nested" => %{"key" => "value"}})
    "value"

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
  }

  @doc """
  ## apply JsonLogic

  This is the entry point
  """
  def apply(logic, data \\ nil)

  @doc """
  ## operations selector branch of apply
  """
  def apply(logic, data) when is_map(logic) and logic != %{} do
    operation_name = logic |> Map.keys |> List.first
    values = logic |> Map.values |> List.first
    Kernel.apply(__MODULE__, @operations[operation_name], [values, data])
  end

  @doc """
  ## conclusive branch of apply
  """
  def apply(logic, _) do
    logic
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

end
