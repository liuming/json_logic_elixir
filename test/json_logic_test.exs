defmodule JsonLogicTest do
  use ExUnit.Case
  doctest JsonLogic

  test "apply" do
    assert JsonLogic.apply() == nil
  end
end
