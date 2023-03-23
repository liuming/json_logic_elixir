defmodule JsonLogic.ImplHelpers do
  def cast_comparison_operator(left, right) when is_number(left) and is_binary(right) do
    if numeric_string?(right) do
      case parse_number(right) do
        {:ok, parsed} ->
          {left, parsed}

        _ ->
          raise ArgumentError, "Unable to parse number `#{right}`"
      end
    else
      {left, right}
    end
  end

  def cast_comparison_operator(left, right) when is_binary(left) and is_number(right) do
    if numeric_string?(left) do
      case parse_number(left) do
        {:ok, parsed} ->
          {parsed, right}

        _ ->
          raise ArgumentError, "Unable to parse number `#{left}`"
      end
    else
      {left, right}
    end
  end

  def cast_comparison_operator(left, right) when is_binary(left) and is_binary(right) do
    if numeric_string?(left) and numeric_string?(right) do
      with {:ok, left} <- parse_number(left),
           {:ok, right} <- parse_number(right) do
        {left, right}
      else
        :error ->
          raise ArgumentError, "Unsupported numeric values `#{left}` and `#{right}`"
      end
    else
      {left, right}
    end
  end

  def cast_comparison_operator(left, right), do: {left, right}

  @numeric_regex ~r/^[\+-]?(\d+)((\.((\d+)([eE][\-\+]?(\d+))?)?))?$/
  def numeric_string?(value), do: String.match?(value, @numeric_regex)

  def parse_number(value) do
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

  def less_than(left, right) when is_float(left) and is_float(right),
    do: left < right

  def less_than(left, right) when is_float(left),
    do: less_than(Decimal.from_float(left), right)

  def less_than(left, right) when is_float(right),
    do: less_than(left, Decimal.from_float(right))

  def less_than(left, right) when is_integer(left),
    do: less_than(Decimal.new(left), right)

  def less_than(left, right) when is_integer(right),
    do: less_than(left, Decimal.new(right))

  def less_than(left, right) when is_binary(left) do
    if numeric_string?(left) do
      less_than(Decimal.new(left), right)
    else
      false
    end
  end

  def less_than(left, right) when is_binary(right) do
    if numeric_string?(right) do
      less_than(left, Decimal.new(right))
    else
      false
    end
  end

  def less_than(%Decimal{} = left, %Decimal{} = right) do
    case Decimal.compare(left, right) do
      :lt -> true
      :eq -> false
      _ -> false
    end
  end

  def less_than(left, right), do: left < right

  def less_than_equal_to(left, right) when is_float(left) and is_float(right),
    do: left <= right

  def less_than_equal_to(left, right) when is_float(left),
    do: less_than_equal_to(Decimal.from_float(left), right)

  def less_than_equal_to(left, right) when is_float(right),
    do: less_than_equal_to(left, Decimal.from_float(right))

  def less_than_equal_to(left, right) when is_integer(left),
    do: less_than_equal_to(Decimal.new(left), right)

  def less_than_equal_to(left, right) when is_integer(right),
    do: less_than_equal_to(left, Decimal.new(right))

  def less_than_equal_to(left, right) when is_binary(left) do
    if numeric_string?(left) do
      less_than_equal_to(Decimal.new(left), right)
    else
      false
    end
  end

  def less_than_equal_to(left, right) when is_binary(right) do
    if numeric_string?(right) do
      less_than_equal_to(left, Decimal.new(right))
    else
      false
    end
  end

  def less_than_equal_to(%Decimal{} = left, %Decimal{} = right) do
    case Decimal.compare(left, right) do
      :lt -> true
      :eq -> true
      _ -> false
    end
  end

  def less_than_equal_to(left, right), do: left <= right

  def greater_than(left, right) when is_float(left) and is_float(right),
    do: left > right

  def greater_than(left, right) when is_float(left),
    do: greater_than(Decimal.from_float(left), right)

  def greater_than(left, right) when is_float(right),
    do: greater_than(left, Decimal.from_float(right))

  def greater_than(left, right) when is_integer(left),
    do: greater_than(Decimal.new(left), right)

  def greater_than(left, right) when is_integer(right),
    do: greater_than(left, Decimal.new(right))

  def greater_than(left, right) when is_binary(left) do
    if numeric_string?(left) do
      greater_than(Decimal.new(left), right)
    else
      false
    end
  end

  def greater_than(left, right) when is_binary(right) do
    if numeric_string?(right) do
      greater_than(left, Decimal.new(right))
    else
      false
    end
  end

  def greater_than(%Decimal{} = left, %Decimal{} = right) do
    case Decimal.compare(left, right) do
      :gt -> true
      :eq -> false
      _ -> false
    end
  end

  def greater_than(left, right), do: left > right

  def greater_than_equal_to(left, right) when is_float(left) and is_float(right),
    do: left >= right

  def greater_than_equal_to(left, right) when is_float(left),
    do: greater_than_equal_to(Decimal.from_float(left), right)

  def greater_than_equal_to(left, right) when is_float(right),
    do: greater_than_equal_to(left, Decimal.from_float(right))

  def greater_than_equal_to(left, right) when is_integer(left),
    do: greater_than_equal_to(Decimal.new(left), right)

  def greater_than_equal_to(left, right) when is_integer(right),
    do: greater_than_equal_to(left, Decimal.new(right))

  def greater_than_equal_to(left, right) when is_binary(left) do
    if numeric_string?(left) do
      greater_than_equal_to(Decimal.new(left), right)
    else
      false
    end
  end

  def greater_than_equal_to(left, right) when is_binary(right) do
    if numeric_string?(right) do
      greater_than_equal_to(left, Decimal.new(right))
    else
      false
    end
  end

  def greater_than_equal_to(%Decimal{} = left, %Decimal{} = right) do
    case Decimal.compare(left, right) do
      :gt -> true
      :eq -> true
      _ -> false
    end
  end

  def greater_than_equal_to(left, right), do: left >= right

  def equal_to(left, right) when is_float(left),
    do: equal_to(Decimal.from_float(left), right)

  def equal_to(left, right) when is_float(right),
    do: equal_to(left, Decimal.from_float(right))

  def equal_to(left, right) when is_integer(left),
    do: equal_to(Decimal.new(left), right)

  def equal_to(left, right) when is_integer(right),
    do: equal_to(left, Decimal.new(right))

  def equal_to(left, right) when is_binary(left) do
    if numeric_string?(left) do
      equal_to(Decimal.new(left), right)
    else
      left == right
    end
  end

  def equal_to(left, right) when is_binary(right) do
    if numeric_string?(right) do
      equal_to(left, Decimal.new(right))
    else
      left == right
    end
  end

  def equal_to(left, right) when is_integer(left) and is_integer(right),
    do: left == right

  def equal_to(%Decimal{} = left, %Decimal{} = right),
    do: Decimal.compare(left, right) == :eq

  def equal_to(left, right), do: left == right

  def multiply(%Decimal{} = left, right) when is_float(right),
    do: multiply(left, Decimal.from_float(right))

  def multiply(%Decimal{} = left, right) when is_integer(right),
    do: multiply(left, Decimal.new(right))

  def multiply(left, %Decimal{} = right) when is_float(left),
    do: multiply(Decimal.from_float(left), right)

  def multiply(left, %Decimal{} = right) when is_integer(left),
    do: multiply(Decimal.new(left), right)

  def multiply(%Decimal{} = left, %Decimal{} = right),
    do: Decimal.mult(left, right)

  def multiply(left, right) when is_binary(left) do
    if numeric_string?(left) do
      {:ok, parsed} = parse_number(left)
      multiply(parsed, right)
    end
  end

  def multiply(left, right) when is_binary(right) do
    if numeric_string?(right) do
      {:ok, parsed} = parse_number(right)
      multiply(left, parsed)
    end
  end

  def multiply(left, right), do: left * right

  def divide(%Decimal{} = left, right) when is_float(right),
    do: divide(left, Decimal.from_float(right))

  def divide(%Decimal{} = left, right) when is_integer(right),
    do: divide(left, Decimal.new(right))

  def divide(left, %Decimal{} = right) when is_float(left),
    do: divide(Decimal.from_float(left), right)

  def divide(left, %Decimal{} = right) when is_integer(left),
    do: divide(Decimal.new(left), right)

  def divide(%Decimal{} = left, %Decimal{} = right),
    do: Decimal.div(left, right)

  def divide(left, right) when is_binary(left) do
    if numeric_string?(left) do
      {:ok, parsed} = parse_number(left)
      divide(parsed, right)
    end
  end

  def divide(left, right) when is_binary(right) do
    if numeric_string?(right) do
      {:ok, parsed} = parse_number(right)
      divide(left, parsed)
    end
  end

  def divide(left, right), do: left / right

  def subtract(left, right) when is_float(left),
    do: subtract(Decimal.from_float(left), right)

  def subtract(left, right) when is_float(right),
    do: subtract(left, Decimal.from_float(right))

  def subtract(%Decimal{} = left, right) when is_integer(right),
    do: subtract(left, Decimal.new(right))

  def subtract(left, %Decimal{} = right) when is_integer(left),
    do: subtract(Decimal.new(left), right)

  def subtract(%Decimal{} = left, %Decimal{} = right),
    do: Decimal.sub(left, right)

  def subtract(left, right) when is_binary(left) do
    if numeric_string?(left) do
      {:ok, parsed} = parse_number(left)
      subtract(parsed, right)
    end
  end

  def subtract(left, right) when is_binary(right) do
    if numeric_string?(right) do
      {:ok, parsed} = parse_number(right)
      subtract(left, parsed)
    end
  end

  def subtract(left, right), do: left - right

  def add(left, right) when is_float(left),
    do: add(Decimal.from_float(left), right)

  def add(left, right) when is_float(right),
    do: add(left, Decimal.from_float(right))

  def add(left, %Decimal{} = right) when is_integer(left),
    do: add(Decimal.new(left), right)

  def add(%Decimal{} = left, right) when is_integer(right),
    do: add(left, Decimal.new(right))

  def add(%Decimal{} = left, %Decimal{} = right),
    do: Decimal.add(left, right)

  def add(left, right) when is_binary(left) do
    if numeric_string?(left) do
      {:ok, parsed} = parse_number(left)
      add(parsed, right)
    end
  end

  def add(left, right) when is_binary(right) do
    if numeric_string?(right) do
      {:ok, parsed} = parse_number(right)
      add(left, parsed)
    end
  end

  def add(left, right), do: left + right

  def remainder(dividend, devisor) when is_float(dividend),
    do: remainder(Decimal.from_float(dividend), devisor)

  def remainder(dividend, devisor) when is_float(devisor),
    do: remainder(dividend, Decimal.from_float(devisor))

  def remainder(%Decimal{} = dividend, devisor) when is_integer(devisor),
    do: remainder(dividend, Decimal.new(devisor))

  def remainder(dividend, %Decimal{} = devisor) when is_integer(dividend),
    do: remainder(Decimal.new(dividend), devisor)

  def remainder(%Decimal{} = dividend, %Decimal{} = devisor),
    do: Decimal.rem(dividend, devisor)

  def remainder(dividend, devisor) when is_binary(dividend) do
    if numeric_string?(dividend) do
      {:ok, parsed} = parse_number(dividend)
      remainder(parsed, devisor)
    end
  end

  def remainder(dividend, devisor) when is_binary(devisor) do
    if numeric_string?(devisor) do
      {:ok, parsed} = parse_number(devisor)
      remainder(dividend, parsed)
    end
  end

  def remainder(dividend, devisor) do
    rem(dividend, devisor)
  end
end
