defmodule JsonLogicTest do
  use ExUnit.Case, async: true

  describe "^" do
    test "returns exponentiated result of vars" do
      logic = %{"^" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogic.resolve(logic, data) == 25.0
    end

    test "strings being exponentiated" do
      assert JsonLogic.resolve(%{"^" => ["a", "b"]}) == nil
      assert JsonLogic.resolve(%{"^" => ["a"]}) == nil
    end

    test "integer exponentiation" do
      assert JsonLogic.resolve(%{"^" => [1, 2]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1, 2, 3]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1, 2, 3, 4]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1]}) == 1

      assert JsonLogic.resolve(%{"^" => [2, "2"]}) == 4.0
      assert JsonLogic.resolve(%{"^" => [2, 2, "3"]}) == 32.0
      assert JsonLogic.resolve(%{"^" => [2, "2", "3", 4]}) == 512.0
      assert JsonLogic.resolve(%{"^" => ["1"]}) == 1
      assert JsonLogic.resolve(%{"^" => ["1", 1]}) == 1
    end

    test "float exponentiation" do
      assert JsonLogic.resolve(%{"^" => [1.0, 2.0]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1.0, 2.0, 3.0]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1.0, 2.0, 3.0, 4.0]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1.0]}) == 1.0

      assert JsonLogic.resolve(%{"^" => [1.0, "2.0"]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1.0, 2.0, "3.0"]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1.0, "2.0", "3.0", 4.0]}) == 1.0
      assert JsonLogic.resolve(%{"^" => ["1.0"]}) == 1.0
      assert JsonLogic.resolve(%{"^" => ["1.0", 1.0]}) == 1.0
      assert JsonLogic.resolve(%{"^" => ["0.97", 5.0]}) == 0.8587340256999999
    end

    test "decimal exponentiation" do
      twos = [2, 2.0, "2.0", Decimal.new("2.0")]

      for left <- twos, right <- twos do
        assert_approx_eq(
          Decimal.new("4.0"),
          JsonLogic.resolve(%{"^" => [left, right]})
        )
      end

      assert_approx_eq(
        Decimal.new("16.0"),
        JsonLogic.resolve(%{
          "^" => [
            Decimal.new("2.0"),
            Decimal.new("2.0"),
            Decimal.new("2.0")
          ]
        })
      )

      assert JsonLogic.resolve(%{"^" => ["1", "foo"]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1, "foo"]}) == 1.0
      assert JsonLogic.resolve(%{"^" => [1.0, "foo"]}) == 1.0
      assert JsonLogic.resolve(%{"^" => ["1.0", "foo"]}) == 1.0
      assert JsonLogic.resolve(%{"^" => ["foo", "1"]}) == nil
      assert JsonLogic.resolve(%{"^" => ["foo", 1]}) == nil
      assert JsonLogic.resolve(%{"^" => ["foo", 1.0]}) == nil
      assert JsonLogic.resolve(%{"^" => ["foo", "1.0"]}) == nil
    end
  end

  describe "map" do
    test "returns mapped integers" do
      logic = %{"map" => [%{"var" => "integers"}, %{"^" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3, 4, 5]}

      assert JsonLogic.resolve(logic, data) == [1.0, 4.0, 9.0, 16.0, 25.0]
    end
  end

  describe "collections" do
    test "filter, map, all, none, and some" do
      logic = %{"filter" => [%{"var" => "integers"}, true]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == [1, 2, 3]

      logic = %{"filter" => [%{"var" => "integers"}, false]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"filter" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == [2, 3]

      logic = %{"filter" => [%{"var" => "integers"}, %{"%" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == [1, 3]

      logic = %{"map" => [%{"var" => "integers"}, %{"^" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == [1.0, 4.0, 9.0]

      logic = %{"map" => [%{"var" => "integers"}, %{"^" => [%{"var" => ""}, 2]}]}
      assert JsonLogic.resolve(logic, nil) == []

      logic = %{"map" => [%{"var" => "desserts"}, %{"var" => "qty"}]}

      data = %{
        "desserts" => [
          %{"name" => "apple", "qty" => 1},
          %{"name" => "brownie", "qty" => 2},
          %{"name" => "cupcake", "qty" => 3}
        ]
      }

      assert JsonLogic.resolve(logic, data) == [1, 2, 3]

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogic.resolve(logic, data) == 10

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = nil
      assert JsonLogic.resolve(logic, data) == 0

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"^" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          1
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogic.resolve(logic, data) == 262144.0

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"^" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }
    end
  end

  defp assert_approx_eq(value1, value2) do
    assert_approx_eq(value1, value2, 1.0e-5)
  end

  defp assert_approx_eq(value1, value2, delta) when is_float(value1) do
    assert_approx_eq(Decimal.from_float(value1), value2, delta)
  end

  defp assert_approx_eq(value1, value2, delta) when is_float(value2) do
    assert_approx_eq(value1, Decimal.from_float(value2), delta)
  end

  defp assert_approx_eq(value1, value2, delta) when is_float(delta) do
    assert_approx_eq(value1, value2, Decimal.from_float(delta))
  end

  defp assert_approx_eq(value1, value2, delta) do
    value1 = Decimal.new(value1)
    value2 = Decimal.new(value2)
    delta = Decimal.new(delta)

    diff =
      value1
      |> Decimal.sub(value2)
      |> Decimal.abs()

    message =
      "Expected the difference between #{inspect(value1)} and " <>
        "#{inspect(value2)} to be less than or equal to #{inspect(delta)}"

    assert Decimal.lt?(diff, delta), message
  end
end
