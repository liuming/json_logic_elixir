defmodule JsonLogic.Base do
  @moduledoc """
  Base module that can be used to extend the default JsonLogic operations by defining own operations implemented in the
  parent module.

  ## Example
  The following shows the definition of a custom module that extends JsonLogic with our own `is_42` operation that
  succeeds when its argument is `42`.

      # See 1.
      defmodule MyApp.JsonLogic do
        use JsonLogic.Base,
          operations: %{
            # See 2.
            "is_42" => :operation_is_42
          }

        # See 3.
        def operation_is_42([value], data) do
          operation_is_42(value, data)
        end

        def operation_is_42(value, data) do
          # Allow `value` to be a "var" construct or something else that needs evaluation.
          # See 4.
          value = if(is_map(value), do: __MODULE__.apply(value, data), else: value)

          value == 42
        end
      end

  There are a few things to explain here:

  1. We can use any module name that fits our application structure and even define multiple custom JsonLogic extensions
     for different areas. We just need to make sure to use their respective [`apply/2`](`JsonLogic.apply/2`) function
     when evaluating logic that needs access to our custom operations.
  2. All custom operations must be listed in the mapping from string keys (used in JsonLogic) to function atoms defined
     in this module. Since this mechanism allows overriding built-in operations, be carefull when chosing the name for
     your operation (see the list of [supported operations](https://jsonlogic.com/operations.html) for identifiers
     already in use).
  3. For this operation that only takes one argument, we can support both versions of passing that argument: As a list
     with one item or as a bare value. For operations with multiple arguments, adjust the match clauses appropriately.
  4. When calling other JsonLogic operators (either through [`apply/2`](`JsonLogic.apply/2`) or directly), always use
     `__MODULE__` or an alias pointing to **our own** JsonLogic module. When referencing the *original* `JsonLogic`
     module, our custom operations will not be available for nested evaluations.

  By following these rules, JsonLogic can be extended in a reproducible way.

      iex> MyApp.JsonLogic.apply(%{"is_42" => [%{"var" => "answer"}]}, %{"answer" => 42})
      true

  """

  @doc false
  def operations(),
    do: %{
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

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @all_ops Map.merge(JsonLogic.Base.operations(), Keyword.get(opts, :operations, %{}))

      @falsey [0, "", [], nil, false]

      @doc """
      Apply JsonLogic.
      Accepts logic and data arguments as Map
      Returns resolved result as Map
      """
      @spec apply(Map.t(), Map.t()) :: Map.t()
      def apply(logic, data \\ nil)

      # operations selector branch of apply
      def apply(logic, data) when is_map(logic) and logic != %{} do
        operation_name = logic |> Map.keys() |> List.first()
        values = logic |> Map.values() |> List.first()

        case Map.fetch(@all_ops, operation_name) do
          {:ok, value} -> Kernel.apply(__MODULE__, value, [values, data])
          :error -> raise "Unrecognized operation `#{operation_name}`"
        end
      end

      # conclusive branch of apply
      def apply(logic, _) do
        logic
      end

      @doc false
      def operation_var("", data) do
        data
      end

      @doc false
      def operation_var([path, default_key], data) do
        operation_var(path, data) || __MODULE__.apply(default_key, data)
      end

      @doc false
      def operation_var([path], data) do
        operation_var(path, data)
      end

      @doc false
      # TODO: may need refactoring
      def operation_var(path, data) when not is_number(path) do
        case __MODULE__.apply(path, data) do
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
        case __MODULE__.apply(keys, data) do
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
          cast_comparison_operator(__MODULE__.apply(left, data), __MODULE__.apply(right, data))

        op1 == op2
      end

      @doc false
      def operation_not_similar([left, right], data \\ nil) do
        {op1, op2} =
          cast_comparison_operator(__MODULE__.apply(left, data), __MODULE__.apply(right, data))

        op1 != op2
      end

      @doc false
      def operation_equal([left, right], data \\ nil) do
        __MODULE__.apply(left, data) === __MODULE__.apply(right, data)
      end

      @doc false
      def operation_not_equal([left, right], data \\ nil) do
        __MODULE__.apply(left, data) !== __MODULE__.apply(right, data)
      end

      @doc false
      def operation_not_not([condition], data) do
        case __MODULE__.apply(condition, data) do
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
        __MODULE__.apply(last, data)
      end

      @doc false
      def operation_if([condition, yes], data) do
        case __MODULE__.apply(condition, data) do
          value when value in @falsey -> nil
          _ -> __MODULE__.apply(yes, data)
        end
      end

      @doc false
      def operation_if([condition, yes, no], data) do
        case __MODULE__.apply(condition, data) do
          value when value in @falsey -> __MODULE__.apply(no, data)
          _ -> __MODULE__.apply(yes, data)
        end
      end

      @doc false
      def operation_if([condition, yes | others], data) do
        case __MODULE__.apply(condition, data) do
          value when value in @falsey -> operation_if(others, data)
          _ -> __MODULE__.apply(yes, data)
        end
      end

      @doc false
      def operation_or([first], data) do
        __MODULE__.apply(first, data)
      end

      def operation_or([first | others], data) do
        case __MODULE__.apply(first, data) do
          value when value in @falsey -> operation_or(others, data)
          other -> other
        end
      end

      @doc false
      def operation_and([first], data) do
        __MODULE__.apply(first, data)
      end

      def operation_and([first | others], data) do
        case __MODULE__.apply(first, data) do
          value when value in @falsey -> value
          _truthy -> operation_and(others, data)
        end
      end

      @doc false
      def operation_max(list, data) do
        list |> Enum.map(fn x -> __MODULE__.apply(x, data) end) |> Enum.max()
      end

      @doc false
      def operation_min(list, data) do
        list |> Enum.map(fn x -> __MODULE__.apply(x, data) end) |> Enum.min()
      end

      @doc false
      def operation_less_than([left, right], data) do
        {op1, op2} =
          cast_comparison_operator(__MODULE__.apply(left, data), __MODULE__.apply(right, data))

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
          cast_comparison_operator(__MODULE__.apply(left, data), __MODULE__.apply(right, data))

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
        |> Enum.map(&__MODULE__.apply(&1, data))
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
          cast_comparison_operator(__MODULE__.apply(first, data), __MODULE__.apply(last, data))

        op1 - op2
      end

      @doc false
      def operation_subtraction([first], data) do
        -__MODULE__.apply(first, data)
      end

      @doc false
      def operation_multiplication(numbers, data) do
        numbers
        |> Enum.map(&__MODULE__.apply(&1, data))
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
          cast_comparison_operator(__MODULE__.apply(first, data), __MODULE__.apply(last, data))

        op1 / op2
      end

      @doc false
      def operation_remainder([first, last], data) do
        Kernel.rem(__MODULE__.apply(first, data), __MODULE__.apply(last, data))
      end

      @doc false
      def operation_map([list, map_action], data) do
        case __MODULE__.apply(list, data) do
          list when is_list(list) ->
            Enum.map(list, fn item -> __MODULE__.apply(map_action, item) end)

          _ ->
            []
        end
      end

      @doc false
      def operation_filter([list, filter_action], data) do
        __MODULE__.apply(list, data)
        |> Enum.filter(fn item ->
          operation_not_not(filter_action, item)
        end)
      end

      @doc false
      def operation_reduce([list, reduce_action], data) do
        operation_reduce([list, reduce_action, nil], data)
      end

      def operation_reduce([list, reduce_action, first], data) do
        eval_first = __MODULE__.apply(first, data)

        case __MODULE__.apply(list, data) do
          list when is_list(list) ->
            Enum.reduce(list, eval_first, fn item, accumulator ->
              __MODULE__.apply(reduce_action, %{"current" => item, "accumulator" => accumulator})
            end)

          _ ->
            first
        end
      end

      @doc false
      def operation_all([list, test], data) do
        case __MODULE__.apply(list, data) do
          [] -> false
          list when is_list(list) -> Enum.all?(list, fn item -> __MODULE__.apply(test, item) end)
          _ -> false
        end
      end

      @doc false
      def operation_none([list, test], data) do
        __MODULE__.apply(list, data)
        |> nil_to_empty_list()
        |> Enum.all?(fn item -> Kernel.if(__MODULE__.apply(test, item), do: false, else: true) end)
      end

      @doc false
      def operation_some([list, test], data) do
        __MODULE__.apply(list, data)
        |> nil_to_empty_list()
        |> Enum.any?(fn item -> __MODULE__.apply(test, item) end)
      end

      defp nil_to_empty_list(nil), do: []
      defp nil_to_empty_list(list), do: list

      def operation_merge([], _data), do: []

      def operation_merge([elem | rest], data) do
        case __MODULE__.apply(elem, data) do
          list when is_list(list) ->
            list ++ operation_merge(rest, data)

          elem ->
            [elem | operation_merge(rest, data)]
        end
      end

      def operation_merge(elem, data) do
        [__MODULE__.apply(elem, data)]
      end

      @doc false
      def operation_in([member, list], data) when is_list(list) do
        members = list |> Enum.map(fn m -> __MODULE__.apply(m, data) end)
        Enum.member?(members, __MODULE__.apply(member, data))
      end

      @doc false
      def operation_in([substring, string], data) when is_binary(string) do
        String.contains?(string, __MODULE__.apply(substring, data))
      end

      @doc false
      def operation_in([_, from], _) when is_nil(from) do
        false
      end

      @doc false
      def operation_in([find, from], data) do
        operation_in([__MODULE__.apply(find, data), __MODULE__.apply(from, data)], data)
      end

      @doc false
      def operation_cat(strings, data) when is_list(strings) do
        strings |> Enum.map(fn s -> __MODULE__.apply(s, data) end) |> Enum.join()
      end

      def operation_cat(string, data) do
        __MODULE__.apply(string, data) |> to_string
      end

      @doc false
      def operation_substr([string, offset], data) do
        string
        |> __MODULE__.apply(data)
        |> String.slice(offset..-1)
      end

      def operation_substr([string, offset, length], data) when length >= 0 do
        string
        |> __MODULE__.apply(data)
        |> String.slice(offset, length)
      end

      def operation_substr([string, offset, length], data) do
        string
        |> __MODULE__.apply(data)
        |> String.slice(offset..(length - 1))
      end

      @doc false
      def operation_log(logic, data) do
        __MODULE__.apply(logic, data)
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
  end
end
