defmodule CustomJsonLogic do
  use JsonLogic

  JsonLogic.add_operation("plus", __MODULE__, :plus)

  def plus([a, b], _), do: a + b
end

defmodule CustomJsonLogicTest do
  use ExUnit.Case

  test "list of operations contains newly added `plus` function" do
    assert {CustomJsonLogic, :plus} == Map.get(CustomJsonLogic.operations(), "plus")
  end

  test "plus operation exist and works" do
    assert CustomJsonLogic.apply(%{"plus" => [2, 3]}) == 5
  end
end
