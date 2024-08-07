defmodule JsonLogicTest do
  use ExUnit.Case, async: true

  describe "*" do
    test "returns multiplied result of vars" do
      logic = %{"*" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogic.resolve(logic, data) == 10
    end

    test "strings being multipled" do
      assert JsonLogic.resolve(%{"*" => ["a", "b"]}) == nil
      assert JsonLogic.resolve(%{"*" => ["a"]}) == nil
    end

    test "integer multiplication" do
      assert JsonLogic.resolve(%{"*" => [1, 2]}) == 2
      assert JsonLogic.resolve(%{"*" => [1, 2, 3]}) == 6
      assert JsonLogic.resolve(%{"*" => [1, 2, 3, 4]}) == 24
      assert JsonLogic.resolve(%{"*" => [1]}) == 1

      assert JsonLogic.resolve(%{"*" => [1, "2"]}) == 2
      assert JsonLogic.resolve(%{"*" => [1, 2, "3"]}) == 6
      assert JsonLogic.resolve(%{"*" => [1, "2", "3", 4]}) == 24
      assert JsonLogic.resolve(%{"*" => ["1"]}) == 1
      assert JsonLogic.resolve(%{"*" => ["1", 1]}) == 1
    end

    test "float multiplication" do
      assert JsonLogic.resolve(%{"*" => [1.0, 2.0]}) == 2.0
      assert JsonLogic.resolve(%{"*" => [1.0, 2.0, 3.0]}) == 6.0
      assert JsonLogic.resolve(%{"*" => [1.0, 2.0, 3.0, 4.0]}) == 24.0
      assert JsonLogic.resolve(%{"*" => [1.0]}) == 1.0

      assert JsonLogic.resolve(%{"*" => [1.0, "2.0"]}) == 2.0
      assert JsonLogic.resolve(%{"*" => [1.0, 2.0, "3.0"]}) == 6.0
      assert JsonLogic.resolve(%{"*" => [1.0, "2.0", "3.0", 4.0]}) == 24.0
      assert JsonLogic.resolve(%{"*" => ["1.0"]}) == 1.0
      assert JsonLogic.resolve(%{"*" => ["1.0", 1.0]}) == 1.0
    end

    test "decimal multiplication" do
      twos = [2, 2.0, "2.0", Decimal.new("2.0")]

      for left <- twos, right <- twos do
        assert_approx_eq(
          Decimal.new("4.0"),
          JsonLogic.resolve(%{"*" => [left, right]})
        )
      end

      assert_approx_eq(
        Decimal.new("8.0"),
        JsonLogic.resolve(%{
          "*" => [
            Decimal.new("2.0"),
            Decimal.new("2.0"),
            Decimal.new("2.0")
          ]
        })
      )

      assert JsonLogic.resolve(%{"*" => ["1", "foo"]}) == nil
      assert JsonLogic.resolve(%{"*" => [1, "foo"]}) == nil
      assert JsonLogic.resolve(%{"*" => [1.0, "foo"]}) == nil
      assert JsonLogic.resolve(%{"*" => ["1.0", "foo"]}) == nil
      assert JsonLogic.resolve(%{"*" => ["foo", "1"]}) == nil
      assert JsonLogic.resolve(%{"*" => ["foo", 1]}) == nil
      assert JsonLogic.resolve(%{"*" => ["foo", 1.0]}) == nil
      assert JsonLogic.resolve(%{"*" => ["foo", "1.0"]}) == nil
    end
  end

  describe "*" do
    test "returns multiplied result of vars" do
      logic = %{"*" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogic.resolve(logic, data) == 10
    end

    test "strings being multipled" do
      assert JsonLogic.resolve(%{"*" => ["a", "b"]}) == nil
      assert JsonLogic.resolve(%{"*" => ["a"]}) == nil
    end

    test "integer multiplication" do
      assert JsonLogic.resolve(%{"*" => [1, 2]}) == 2
      assert JsonLogic.resolve(%{"*" => [1, 2, 3]}) == 6
      assert JsonLogic.resolve(%{"*" => [1, 2, 3, 4]}) == 24
      assert JsonLogic.resolve(%{"*" => [1]}) == 1

      assert JsonLogic.resolve(%{"*" => [1, "2"]}) == 2
      assert JsonLogic.resolve(%{"*" => [1, 2, "3"]}) == 6
      assert JsonLogic.resolve(%{"*" => [1, "2", "3", 4]}) == 24
      assert JsonLogic.resolve(%{"*" => ["1"]}) == 1
      assert JsonLogic.resolve(%{"*" => ["1", 1]}) == 1
    end

    test "float multiplication" do
      assert JsonLogic.resolve(%{"*" => [1.0, 2.0]}) == 2.0
      assert JsonLogic.resolve(%{"*" => [1.0, 2.0, 3.0]}) == 6.0
      assert JsonLogic.resolve(%{"*" => [1.0, 2.0, 3.0, 4.0]}) == 24.0
      assert JsonLogic.resolve(%{"*" => [1.0]}) == 1.0

      assert JsonLogic.resolve(%{"*" => [1.0, "2.0"]}) == 2.0
      assert JsonLogic.resolve(%{"*" => [1.0, 2.0, "3.0"]}) == 6.0
      assert JsonLogic.resolve(%{"*" => [1.0, "2.0", "3.0", 4.0]}) == 24.0
      assert JsonLogic.resolve(%{"*" => ["1.0"]}) == 1.0
      assert JsonLogic.resolve(%{"*" => ["1.0", 1.0]}) == 1.0
    end

    test "decimal multiplication" do
      twos = [2, 2.0, "2.0", Decimal.new("2.0")]

      for left <- twos, right <- twos do
        assert_approx_eq(
          Decimal.new("4.0"),
          JsonLogic.resolve(%{"*" => [left, right]})
        )
      end

      assert_approx_eq(
        Decimal.new("8.0"),
        JsonLogic.resolve(%{
          "*" => [
            Decimal.new("2.0"),
            Decimal.new("2.0"),
            Decimal.new("2.0")
          ]
        })
      )

      assert JsonLogic.resolve(%{"*" => ["1", "foo"]}) == nil
      assert JsonLogic.resolve(%{"*" => [1, "foo"]}) == nil
      assert JsonLogic.resolve(%{"*" => [1.0, "foo"]}) == nil
      assert JsonLogic.resolve(%{"*" => ["1.0", "foo"]}) == nil
      assert JsonLogic.resolve(%{"*" => ["foo", "1"]}) == nil
      assert JsonLogic.resolve(%{"*" => ["foo", 1]}) == nil
      assert JsonLogic.resolve(%{"*" => ["foo", 1.0]}) == nil
      assert JsonLogic.resolve(%{"*" => ["foo", "1.0"]}) == nil
    end
  end

  describe "map" do
    test "returns mapped integers" do
      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3, 4, 5]}

      assert JsonLogic.resolve(logic, data) == [2, 4, 6, 8, 10]
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

      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == [2, 4, 6]

      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
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
          %{"*" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          1
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogic.resolve(logic, data) == 24

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"*" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }
    end
  end