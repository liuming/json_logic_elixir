defmodule JSONLogic_ExtendedOperations do
  @moduledoc """
  Extended operators on top of the existing JSON Logic operators
  """

  @doc """
  implements the exponential operator
  """
  def exponent_op(numbers, data) do
    numbers
    |> Enum.map(fn x -> JsonLogicXL.resolve(x, data) end)
    |> Enum.reduce_while({nil, 0}, fn
      number, {nil, total} ->
        {:cont, {number, total}}
      number, {base, total} when is_number(number) ->
        {:cont, {base, total + number}}
      %Decimal{} = decimal, {base, total} ->
        # Convert Decimal to float
        number = Decimal.to_float(decimal)
        {:cont, {base, total + number}}
      string, {base, total} when is_binary(string) ->
        case parse_number(string) do
          {:ok, number} ->
            {:cont, {base, total + number}}

          :error ->
            {:cont, {base, total}}  # Continue accumulating valid base and exponents
        end
      _any, {base, total} ->
        {:cont, {base, total}}  # Continue accumulating valid base and exponents
    end)
    |> case do
      {base, exponent} when is_number(base) and is_number(exponent) ->
        result = exponentiate(base, exponent)
        result
      {base, exponent} when is_binary(base) ->
        # Convert base if it's a string
        case parse_numeric(base) do
          {:ok, base_number} ->
            result = exponentiate(base_number, exponent)
            result
          :error ->
            nil
        end
      {base, exponent} when is_struct(base, Decimal) ->
          # Convert base from Decimal to float
          base_float = Decimal.to_float(base)
          result = exponentiate(base_float, exponent)
          result
      {_base, _exponent} ->
        nil
    end
  end

  defp exponentiate(%Decimal{} = left, right) when is_number(right) do
    left_float = Decimal.to_float(left)
    exponentiate(left_float, right)
  end

  defp exponentiate(left, %Decimal{} = right) when is_number(left) do
    right_float = Decimal.to_float(right)
    exponentiate(left, right_float)
  end

  defp exponentiate(left, right) when is_binary(left) do
    case parse_numeric(left) do
      {:ok, number} ->
        exponentiate(number, right)
      :error ->
        nil
    end
  end

  defp exponentiate(left, right) when is_binary(right) do
    case parse_numeric(right) do
      {:ok, number} ->
        exponentiate(left, number)
      :error ->
        nil
    end
  end

  defp exponentiate(base, exponent) when is_number(base) and is_number(exponent) do
    Float.pow(float(base), float(exponent))
  end

  def parse_numeric(string) do
    case Float.parse(string) do
      {number, _} ->
        {:ok, number}
      :error ->
        :error
    end
  end

  defp parse_number(value) do
    case Integer.parse(value) do
      {integer, ""} ->
        {:ok, integer}

      _ ->
        case Float.parse(value) do
          {float, ""} ->
            {:ok, float}

          {float, "."} ->
            {:ok, float}

          _ ->
            :error
        end
    end
  end

  def float(value) when is_integer(value), do: value * 1.0
  def float(value) when is_float(value), do: value

  @doc """
  implements the xlookup operator
  """
  def xlookup_op([match, opts, map_key_prop, map_val_prop | _rest_of_list], data) do
    xlookup(JsonLogicXL.resolve(match, data), JsonLogicXL.resolve(opts, data),
      JsonLogicXL.resolve(map_key_prop, data), JsonLogicXL.resolve(map_val_prop, data))
  end

  defguardp xlookup_guard(match, opts, k_prop, v_prop) when (is_binary(match) or is_number(match)) and is_list(opts)
    and is_binary(k_prop) and is_binary(v_prop)

  defp xlookup(match, options, key_prop, val_prop) when
    xlookup_guard(match, options, key_prop, val_prop)
  do
    options |> Enum.find_value(fn opt ->
      if opt[key_prop] == match, do: opt[val_prop]
    end)
  end

  @doc """
  implements the ln (natural log) operator
  """
  def natural_log_op(num, data) do
    natural_log(JsonLogicXL.resolve(num, data))
  end

  defp natural_log(val) when is_binary(val) do
    {:ok, num} = parse_number(val)
    natural_log(num)
  end
  defp natural_log(val) when is_number(val) do
    :math.log(val)
  end

  @doc """
  implements the range_lookup operator
  """
  def range_lookup_op([value, ranges], data), do: range_lookup_op([value, ranges, nil], data)
  def range_lookup_op([value, ranges, default_value | _], data) do
    range_lookup(JsonLogicXL.resolve(value, data), JsonLogicXL.resolve(ranges, data),
      JsonLogicXL.resolve(default_value, data))
  end

  defp range_lookup(value, ranges, default_val)
  defp range_lookup(value, ranges, default_val) when is_binary(value) do
    {:ok, num} = parse_number(value)
    range_lookup(num, ranges, default_val)
  end
  defp range_lookup(value, ranges, default_val) when is_number(value) and is_list(ranges) do
    res = Enum.find_value(ranges, fn x ->
      min_check = x["min"] == nil || value >= x["min"]
      max_check = x["max"] == nil || value < x["max"]
      if min_check && max_check do
        x["result"]
      end
    end)
    if res != nil do
      res
    else
      default_val
    end
  end

  @eulers_constant 2.7182818284590452353602874713526624977572470936999595749669676277
  @doc """
  raises eulers number to a power passed in.
  Similar to Excel's "exp" function.
  """
  def eulers_exponent_op(val, data), do: eulers_exponent(JsonLogicXL.resolve(val, data))

  defp eulers_exponent(val) when is_binary(val) do
    {:ok, num} = parse_number(val)
    eulers_exponent(num)
  end
  defp eulers_exponent(val) when is_number(val) do
    @eulers_constant ** val
  end
end
