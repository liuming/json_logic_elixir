defmodule JsonLogicTest do
  use ExUnit.Case
  doctest JsonLogic

  test "apply" do
    assert JsonLogic.apply(nil) == nil
    assert JsonLogic.apply(%{}) == %{}
  end

  describe "var" do
    test "returns from array inside hash" do
      assert JsonLogic.apply(%{"var" => "key.1"}, %{"key" => %{"1" => "a"}}) == "a"
      assert JsonLogic.apply(%{"var" => "key.1"}, %{"key" => ~w{a b}}) == "b"
    end
  end

  describe "==" do
    test "nested true" do
      assert JsonLogic.apply(%{"==" => [true, %{"==" => [1, 1]}]})
    end

    test "nested false" do
      assert JsonLogic.apply(%{"==" => [false, %{"==" => [0, 1]}]})
    end
  end

  describe "!=" do
    test "nested true" do
      assert JsonLogic.apply(%{"!=" => [false, %{"!=" => [0, 1]}]})
    end

    test "nested false" do
      assert JsonLogic.apply(%{"!=" => [true, %{"!=" => [1, 1]}]})
    end
  end

  describe "===" do
    test "nested true" do
      assert JsonLogic.apply(%{"===" => [true, %{"===" => [1, 1]}]})
    end

    test "nested false" do
      assert JsonLogic.apply(%{"===" => [false, %{"===" => [1, 1.0]}]})
    end
  end

  describe "!==" do
    test "nested true" do
      assert JsonLogic.apply(%{"!==" => [false, %{"!==" => [1, 1.0]}]})
    end

    test "nested false" do
      assert JsonLogic.apply(%{"!==" => [true, %{"!==" => [1, 1]}]})
    end
  end

  describe "!" do
    test "returns true with [false]" do
      assert JsonLogic.apply(%{"!" => [false]}) == true
    end

    test "returns false with [true]" do
      assert JsonLogic.apply(%{"!" => [true]}) == false
    end

    test "returns true with [false] from data" do
      assert JsonLogic.apply(%{"!" => [%{"var" => "key"}]}, %{"key" => false}) == true
    end
  end

  describe "if" do
    test "returns var when true" do
      assert JsonLogic.apply(%{"if" => [true, %{"var" => "key"}, "unexpected"]}, %{"key" => "yes"}) ==
               "yes"
    end

    test "returns var when false" do
      assert JsonLogic.apply(%{"if" => [false, "unexpected", %{"var" => "key"}]}, %{"key" => "no"}) ==
               "no"
    end

    test "returns var with multiple branches" do
      assert JsonLogic.apply(
               %{"if" => [false, "unexpected", false, "unexpected", %{"var" => "key"}]},
               %{"key" => "default"}
             ) == "default"
    end

    test "returns nil when else is not present" do
      assert JsonLogic.apply(%{"if" => [false, "unexpected"]}) == nil
    end
  end

  describe "max" do
    test "returns max from vars" do
      logic = [%{"var" => "three"}, %{"var" => "one"}, %{"var" => "two"}]
      data = %{"one" => 1, "two" => 2, "three" => 3}
      assert JsonLogic.apply(%{"max" => logic}, data) == 3
    end
  end

  describe "min" do
    test "returns min from vars" do
      logic = [%{"var" => "three"}, %{"var" => "one"}, %{"var" => "two"}]
      data = %{"one" => 1, "two" => 2, "three" => 3}
      assert JsonLogic.apply(%{"min" => logic}, data) == 1
    end
  end

  describe "+" do
    test "returns added result of vars" do
      assert JsonLogic.apply(%{"+" => [%{"var" => "left"}, %{"var" => "right"}]}, %{
               "left" => 5,
               "right" => 2
             }) == 7
    end
  end

  describe "-" do
    test "returns subtraced result of vars" do
      assert JsonLogic.apply(%{"-" => [%{"var" => "left"}, %{"var" => "right"}]}, %{
               "left" => 5,
               "right" => 2
             }) == 3
    end

    test "returns negative of a var" do
      assert JsonLogic.apply(%{"-" => [%{"var" => "key"}]}, %{"key" => 2}) == -2
    end
  end

  describe "*" do
    test "returns multiplied result of vars" do
      assert JsonLogic.apply(%{"*" => [%{"var" => "left"}, %{"var" => "right"}]}, %{
               "left" => 5,
               "right" => 2
             }) == 10
    end
  end

  describe "/" do
    test "returns multiplied result of vars" do
      assert JsonLogic.apply(%{"/" => [%{"var" => "left"}, %{"var" => "right"}]}, %{
               "left" => 5,
               "right" => 2
             }) == 2.5
    end
  end

  describe "map" do
    test "returns mapped integers" do
      assert JsonLogic.apply(
               %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]},
               %{"integers" => [1, 2, 3, 4, 5]}
             ) == [2, 4, 6, 8, 10]
    end
  end

  describe "filter" do
    test "returns filtered integers" do
      assert JsonLogic.apply(
               %{"filter" => [%{"var" => "integers"}, %{">" => [%{"var" => ""}, 2]}]},
               %{"integers" => [1, 2, 3, 4, 5]}
             ) == [3, 4, 5]
    end

    test "returns filtered objects" do
      data = %{"objects" => [%{"uid" => "A"}, %{"uid" => "B"}]}

      assert JsonLogic.apply(
               %{"filter" => [%{"var" => "objects"}, %{"==" => [%{"var" => "uid"}, "A"]}]},
               data
             ) == [%{"uid" => "A"}]
    end
  end

  describe "reduce" do
    test "returns reduced integers" do
      assert JsonLogic.apply(
               %{
                 "reduce" => [
                   %{"var" => "integers"},
                   %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
                   0
                 ]
               },
               %{"integers" => [1, 2, 3]}
             ) == 6
    end
  end

  describe "in" do
    test "returns true from vars" do
      assert JsonLogic.apply(%{"in" => [%{"var" => "find"}, %{"var" => "from"}]}, %{
               "find" => "sub",
               "from" => "substring"
             }) == true
    end

    test "returns true from var list" do
      assert JsonLogic.apply(%{"in" => [%{"var" => "find"}, %{"var" => "from"}]}, %{
               "find" => "sub",
               "from" => ["sub", "string"]
             }) == true
    end

    test "returns false from nil" do
      assert JsonLogic.apply(%{"in" => [%{"var" => "find"}, %{"var" => "from"}]}, %{
               "find" => "sub",
               "from" => nil
             }) == false
    end

    test "returns false from var list" do
      assert JsonLogic.apply(%{"in" => [%{"var" => "find"}, %{"var" => "from"}]}, %{
               "find" => "sub",
               "from" => ["A", "B"]
             }) == false
    end
  end
end
