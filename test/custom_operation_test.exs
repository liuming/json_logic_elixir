defmodule CustomOperationTest do
  use ExUnit.Case, async: true

  # Ad-hoc module that extends JsonLogic with a custom operation.
  defmodule JsonLogicExt do
    use JsonLogic.Base,
      operations: %{
        "is_42" => :operation_is_42
      }

    def operation_is_42([value], data) do
      operation_is_42(value, data)
    end

    def operation_is_42(value, data) do
      value = if(is_map(value), do: __MODULE__.apply(value, data), else: value)

      value == 42
    end
  end

  describe "Custom operation" do
    test "executes operation" do
      assert JsonLogicExt.apply(%{"is_42" => [42]})
      assert JsonLogicExt.apply(%{"is_42" => 42})
    end

    test "custom operations can call built-in operations" do
      logic = %{
        "all" => [%{"var" => "numbers"}, %{"is_42" => %{"var" => "value"}}]
      }

      assert JsonLogicExt.apply(logic, %{"numbers" => [%{"value" => 42}, %{"value" => 42}]})
      refute JsonLogicExt.apply(logic, %{"numbers" => [%{"value" => 12}]})
    end
  end
end
