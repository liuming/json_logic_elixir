defmodule JsonLogicTest do
  use ExUnit.Case, async: true
  doctest JsonLogic

  describe "non rules" do
    test "nil" do
      assert JsonLogic.apply(nil) == nil
    end

    test "empty map" do
      assert JsonLogic.apply(%{}) == %{}
    end

    test "true" do
      assert JsonLogic.apply(true) == true
    end

    test "false" do
      assert JsonLogic.apply(false) == false
    end

    test "integer" do
      assert JsonLogic.apply(17) == 17
    end

    test "float" do
      assert JsonLogic.apply(3.14) == 3.14
    end

    test "string" do
      assert JsonLogic.apply("apple") == "apple"
    end

    test "null" do
      assert JsonLogic.apply(nil) == nil
    end

    test "list of strings" do
      assert JsonLogic.apply(["a", "b"]) == ["a", "b"]
    end
  end

  describe "var" do
    test "returns from array inside hash" do
      assert JsonLogic.apply(%{"var" => "key.1"}, %{"key" => %{"1" => "a"}}) == "a"
      assert JsonLogic.apply(%{"var" => "key.1"}, %{"key" => ~w{a b}}) == "b"
    end
  end

  describe "==" do
    test "nested true" do
      logic = %{"==" => [true, %{"==" => [1, 1]}]}
      assert JsonLogic.apply(logic)
    end

    test "nested false" do
      logic = %{"==" => [false, %{"==" => [0, 1]}]}
      assert JsonLogic.apply(logic)
    end

    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        assert JsonLogic.apply(%{"==" => [left, right]})
      end

      for left <- twos, right <- ones do
        refute JsonLogic.apply(%{"==" => [left, right]})
      end

      for left <- ones, right <- twos do
        refute JsonLogic.apply(%{"==" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{"==" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{"==" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{"==" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      assert JsonLogic.apply(%{"==" => [3.14, 1.0 + 2.14]})
      refute JsonLogic.apply(%{"==" => [3.14, 3.1399999999999997]})
    end
  end

  describe "!=" do
    test "nested true" do
      assert JsonLogic.apply(%{"!=" => [false, %{"!=" => [0, 1]}]})
    end

    test "nested false" do
      assert JsonLogic.apply(%{"!=" => [true, %{"!=" => [1, 1]}]})
    end

    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        refute JsonLogic.apply(%{"!=" => [left, right]})
      end

      for left <- twos, right <- ones do
        assert JsonLogic.apply(%{"!=" => [left, right]})
      end

      for left <- ones, right <- twos do
        assert JsonLogic.apply(%{"!=" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{"!=" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{"!=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{"!=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      refute JsonLogic.apply(%{"!=" => [3.14, 1.0 + 2.14]})
      assert JsonLogic.apply(%{"!=" => [3.14, 3.1399999999999997]})
    end
  end

  describe "===" do
    test "nested true" do
      assert JsonLogic.apply(%{"===" => [true, %{"===" => [1, 1]}]})
    end

    test "nested false" do
      assert JsonLogic.apply(%{"===" => [false, %{"===" => [1, 1.0]}]})
    end

    test "integer comparisons" do
      assert JsonLogic.apply(%{"===" => [1, 1]})
      refute JsonLogic.apply(%{"===" => [1, "1"]})
      assert JsonLogic.apply(%{"===" => ["1", "1"]})
      refute JsonLogic.apply(%{"===" => ["1", 1]})

      refute JsonLogic.apply(%{"===" => [1, 2]})
      refute JsonLogic.apply(%{"===" => [1, "2"]})
      refute JsonLogic.apply(%{"===" => ["1", "2"]})
      refute JsonLogic.apply(%{"===" => ["1", 2]})
    end

    test "float comparisons" do
      assert JsonLogic.apply(%{"===" => [1.0, 1.0]})
      refute JsonLogic.apply(%{"===" => [1.0, "1.0"]})
      assert JsonLogic.apply(%{"===" => ["1.0", "1.0"]})
      refute JsonLogic.apply(%{"===" => ["1.0", 1.0]})

      refute JsonLogic.apply(%{"===" => [1.0, 2.0]})
      refute JsonLogic.apply(%{"===" => [1.0, "2.0"]})
      refute JsonLogic.apply(%{"===" => ["1.0", "2.0"]})
      refute JsonLogic.apply(%{"===" => ["1.0", 2.0]})
    end

    test "decimal comparisons" do
      refute JsonLogic.apply(%{"===" => ["1.0", Decimal.new("1.0")]})
      refute JsonLogic.apply(%{"===" => [1.0, Decimal.new("1.0")]})
      refute JsonLogic.apply(%{"===" => [1, Decimal.new("1.0")]})
      refute JsonLogic.apply(%{"===" => [1, Decimal.new("1")]})
      refute JsonLogic.apply(%{"===" => [Decimal.new("1.0"), "1.0"]})
      refute JsonLogic.apply(%{"===" => [Decimal.new("1.0"), 1.0]})
      refute JsonLogic.apply(%{"===" => [Decimal.new("1.0"), 1]})
      refute JsonLogic.apply(%{"===" => [Decimal.new("1"), 1]})

      assert JsonLogic.apply(%{"===" => [Decimal.new("1.0"), Decimal.new("1.0")]})
      refute JsonLogic.apply(%{"===" => [Decimal.new("1.00"), Decimal.new("1.0")]})
      refute JsonLogic.apply(%{"===" => [Decimal.new("1.0"), Decimal.new("1.00")]})
    end
  end

  describe "!==" do
    test "nested true" do
      assert JsonLogic.apply(%{"!==" => [false, %{"!==" => [1, 1.0]}]})
    end

    test "nested false" do
      assert JsonLogic.apply(%{"!==" => [true, %{"!==" => [1, 1]}]})
    end

    test "integer comparisons" do
      refute JsonLogic.apply(%{"!==" => [1, 1]})
      assert JsonLogic.apply(%{"!==" => [1, 2]})
      assert JsonLogic.apply(%{"!==" => [1, "1"]})
      refute JsonLogic.apply(%{"!==" => ["1", "1"]})
      assert JsonLogic.apply(%{"!==" => ["1", 1]})
    end

    test "float comparisons" do
      refute JsonLogic.apply(%{"!==" => [1.0, 1.0]})
      assert JsonLogic.apply(%{"!==" => [1.0, 2.0]})
      assert JsonLogic.apply(%{"!==" => [1.0, "1.0"]})
      refute JsonLogic.apply(%{"!==" => ["1.0", "1.0"]})
      assert JsonLogic.apply(%{"!==" => ["1.0", 1.0]})
    end

    test "decimal comparisons" do
      assert JsonLogic.apply(%{"!==" => ["1.0", Decimal.new("1.0")]})
      assert JsonLogic.apply(%{"!==" => [1.0, Decimal.new("1.0")]})
      assert JsonLogic.apply(%{"!==" => [1, Decimal.new("1.0")]})
      assert JsonLogic.apply(%{"!==" => [1, Decimal.new("1")]})
      assert JsonLogic.apply(%{"!==" => [Decimal.new("1.0"), "1.0"]})
      assert JsonLogic.apply(%{"!==" => [Decimal.new("1.0"), 1.0]})
      assert JsonLogic.apply(%{"!==" => [Decimal.new("1.0"), 1]})
      assert JsonLogic.apply(%{"!==" => [Decimal.new("1"), 1]})

      refute JsonLogic.apply(%{"!==" => [Decimal.new("1.0"), Decimal.new("1.0")]})
      assert JsonLogic.apply(%{"!==" => [Decimal.new("1.00"), Decimal.new("1.0")]})
      assert JsonLogic.apply(%{"!==" => [Decimal.new("1.0"), Decimal.new("1.00")]})
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

    test "notting boolean" do
      assert JsonLogic.apply(%{"!" => [false]})
      assert JsonLogic.apply(%{"!" => false})
      refute JsonLogic.apply(%{"!" => [true]})
      refute JsonLogic.apply(%{"!" => true})
    end

    test "notting nil" do
      assert JsonLogic.apply(%{"!" => nil})
      assert JsonLogic.apply(%{"!" => [nil]})
      refute JsonLogic.apply(%{"!" => [nil, nil]})
    end

    test "notting numbers" do
      assert JsonLogic.apply(%{"!" => 0})
      refute JsonLogic.apply(%{"!" => 1})
      refute JsonLogic.apply(%{"!" => -1})
      refute JsonLogic.apply(%{"!" => 100})
      refute JsonLogic.apply(%{"!" => 0.0})
      refute JsonLogic.apply(%{"!" => 1.0})
      refute JsonLogic.apply(%{"!" => -1.0})
      refute JsonLogic.apply(%{"!" => Decimal.new("1.0")})
    end

    test "notting vars" do
      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => 0}
      assert JsonLogic.apply(logic, data)

      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => 1}
      refute JsonLogic.apply(logic, data)

      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => 1.0}
      refute JsonLogic.apply(logic, data)

      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => 0.0}
      refute JsonLogic.apply(logic, data)

      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => Decimal.new("1.0")}
      refute JsonLogic.apply(logic, data)
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

    test "too few args" do
      assert JsonLogic.apply(%{"if" => []}) == nil
      assert JsonLogic.apply(%{"if" => [true]}) == true
      assert JsonLogic.apply(%{"if" => [false]}) == false
      assert JsonLogic.apply(%{"if" => ["apple"]}) == "apple"
    end

    test "simple if then else cases" do
      assert JsonLogic.apply(%{"if" => [true, "apple"]}) == "apple"
      assert JsonLogic.apply(%{"if" => [false, "apple"]}) == nil
      assert JsonLogic.apply(%{"if" => [true, "apple", "banana"]}) == "apple"
      assert JsonLogic.apply(%{"if" => [false, "apple", "banana"]}) == "banana"
    end

    test "empty arrays are falsey" do
      assert JsonLogic.apply(%{"if" => [[], "apple", "banana"]}) == "banana"
      assert JsonLogic.apply(%{"if" => [[1], "apple", "banana"]}) == "apple"
      assert JsonLogic.apply(%{"if" => [[1, 2, 3, 4], "apple", "banana"]}) == "apple"
    end

    test "empty strings are falsey, all other strings are truthy" do
      assert JsonLogic.apply(%{"if" => ["", "apple", "banana"]}) == "banana"
      assert JsonLogic.apply(%{"if" => ["zucchini", "apple", "banana"]}) == "apple"
      assert JsonLogic.apply(%{"if" => ["0", "apple", "banana"]}) == "apple"
    end

    test "you can cast a string to numeric with a unary + " do
      assert JsonLogic.apply(%{"===" => [0, "0"]}) == false
      assert JsonLogic.apply(%{"===" => [0, %{"+" => "0"}]}) == true
      assert JsonLogic.apply(%{"if" => ["", "apple", "banana"]}) == "banana"
      assert JsonLogic.apply(%{"if" => [%{"+" => "0"}, "apple", "banana"]}) == "banana"
      assert JsonLogic.apply(%{"if" => [%{"+" => "1"}, "apple", "banana"]}) == "apple"
    end

    test "zero is falsy, all other numbers are truthy" do
      assert JsonLogic.apply(%{"if" => [0, "apple", "banana"]}) == "banana"
      assert JsonLogic.apply(%{"if" => [1, "apple", "banana"]}) == "apple"
      assert JsonLogic.apply(%{"if" => [3.1416, "apple", "banana"]}) == "apple"
      assert JsonLogic.apply(%{"if" => [-1, "apple", "banana"]}) == "apple"
    end

    test "truthy and falsy definitions matter in boolean operations" do
      assert JsonLogic.apply(%{"!" => [[]]}) == true
      assert JsonLogic.apply(%{"!!" => [[]]}) == false
      assert JsonLogic.apply(%{"and" => [[], true]}) == []
      assert JsonLogic.apply(%{"or" => [[], true]}) == true
      assert JsonLogic.apply(%{"!" => [0]}) == true
      assert JsonLogic.apply(%{"!!" => [0]}) == false
      assert JsonLogic.apply(%{"and" => [0, true]}) == 0
      assert JsonLogic.apply(%{"or" => [0, true]}) == true
      assert JsonLogic.apply(%{"!" => [""]}) == true
      assert JsonLogic.apply(%{"!!" => [""]}) == false
      assert JsonLogic.apply(%{"and" => ["", true]}) == ""
      assert JsonLogic.apply(%{"or" => ["", true]}) == true
      assert JsonLogic.apply(%{"!" => ["0"]}) == false
      assert JsonLogic.apply(%{"!!" => ["0"]}) == true
      assert JsonLogic.apply(%{"and" => ["0", true]}) == true
      assert JsonLogic.apply(%{"or" => ["0", true]}) == "0"
    end

    test "if the conditional is logic, it gets evaluated" do
      logic = %{"if" => [%{">" => [2, 1]}, "apple", "banana"]}
      assert JsonLogic.apply(logic) == "apple"

      logic = %{"if" => [%{">" => [1, 2]}, "apple", "banana"]}
      assert JsonLogic.apply(logic) == "banana"
    end

    test "if the consequents are logic, they get evaluated" do
      logic = %{
        "if" => [
          true,
          %{"cat" => ["ap", "ple"]},
          %{"cat" => ["ba", "na", "na"]}
        ]
      }

      assert JsonLogic.apply(logic) == "apple"

      logic = %{
        "if" => [
          false,
          %{"cat" => ["ap", "ple"]},
          %{"cat" => ["ba", "na", "na"]}
        ]
      }

      assert JsonLogic.apply(logic) == "banana"
    end

    test "if / then / elseif / then cases" do
      logic = %{"if" => [true, "apple", true, "banana"]}
      assert JsonLogic.apply(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana"]}
      assert JsonLogic.apply(logic) == "apple"

      logic = %{"if" => [false, "apple", true, "banana"]}
      assert JsonLogic.apply(logic) == "banana"

      logic = %{"if" => [false, "apple", false, "banana"]}
      assert JsonLogic.apply(logic) == nil

      logic = %{"if" => [true, "apple", true, "banana", "carrot"]}
      assert JsonLogic.apply(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana", "carrot"]}
      assert JsonLogic.apply(logic) == "apple"

      logic = %{"if" => [false, "apple", true, "banana", "carrot"]}
      assert JsonLogic.apply(logic) == "banana"

      logic = %{"if" => [false, "apple", false, "banana", "carrot"]}
      assert JsonLogic.apply(logic) == "carrot"

      logic = %{"if" => [false, "apple", false, "banana", false, "carrot"]}
      assert JsonLogic.apply(logic) == nil

      logic = %{"if" => [false, "apple", false, "banana", false, "carrot", "date"]}
      assert JsonLogic.apply(logic) == "date"

      logic = %{"if" => [false, "apple", false, "banana", true, "carrot", "date"]}
      assert JsonLogic.apply(logic) == "carrot"

      logic = %{"if" => [false, "apple", true, "banana", false, "carrot", "date"]}
      assert JsonLogic.apply(logic) == "banana"

      logic = %{"if" => [false, "apple", true, "banana", true, "carrot", "date"]}
      assert JsonLogic.apply(logic) == "banana"

      logic = %{"if" => [true, "apple", false, "banana", false, "carrot", "date"]}
      assert JsonLogic.apply(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana", true, "carrot", "date"]}
      assert JsonLogic.apply(logic) == "apple"

      logic = %{"if" => [true, "apple", true, "banana", false, "carrot", "date"]}
      assert JsonLogic.apply(logic) == "apple"

      logic = %{"if" => [true, "apple", true, "banana", true, "carrot", "date"]}
      assert JsonLogic.apply(logic) == "apple"
    end

    test "returns object" do
      logic = %{
        "if" => [
          %{"==" => [%{"var" => "foo"}, "bar"]},
          %{"foo" => "is_bar", "path" => "foo_is_bar"},
          %{"foo" => "not_bar", "path" => "default_object"}
        ]
      }

      data = %{"foo" => "bar"}

      assert %{
               "foo" => "is_bar",
               "path" => "foo_is_bar"
             } == JsonLogic.apply(logic, data)
    end
  end

  describe "max" do
    test "returns max from vars" do
      logic = %{"max" => [%{"var" => "three"}, %{"var" => "one"}, %{"var" => "two"}]}
      data = %{"one" => 1, "two" => 2, "three" => 3}
      assert JsonLogic.apply(logic, data) == 3
    end

    test "integers" do
      assert JsonLogic.apply(%{"max" => [1, 2, 3]}) == 3
      assert JsonLogic.apply(%{"max" => [1, 3, 3]}) == 3
      assert JsonLogic.apply(%{"max" => [3, 2, 1]}) == 3
      assert JsonLogic.apply(%{"max" => [3, 2]}) == 3
      assert JsonLogic.apply(%{"max" => [1]}) == 1

      assert JsonLogic.apply(%{"max" => ["1", "2", "3"]}) == "3"
      assert JsonLogic.apply(%{"max" => ["1", "3", "3"]}) == "3"
      assert JsonLogic.apply(%{"max" => ["3", "2", "1"]}) == "3"
      assert JsonLogic.apply(%{"max" => ["3", "2"]}) == "3"
      assert JsonLogic.apply(%{"max" => ["1"]}) == "1"

      assert JsonLogic.apply(%{"max" => ["1", "2", 3]}) == 3
      assert JsonLogic.apply(%{"max" => [3, "2", "1"]}) == 3
      assert JsonLogic.apply(%{"max" => [3, "2"]}) == 3
      assert JsonLogic.apply(%{"max" => [1]}) == 1
    end

    test "floats" do
      assert_approx_eq(3.1, JsonLogic.apply(%{"max" => [1.1, 2.1, 3.1]}))
      assert_approx_eq(3.1, JsonLogic.apply(%{"max" => [1.1, 3.1, 3.1]}))
      assert_approx_eq(3.1, JsonLogic.apply(%{"max" => [3.1, 2.1, 1.1]}))
      assert_approx_eq(3.1, JsonLogic.apply(%{"max" => [3.1, 2.1]}))
      assert_approx_eq(1.1, JsonLogic.apply(%{"max" => [1.1]}))

      assert JsonLogic.apply(%{"max" => ["1.1", "2.1", "3.1"]}) == "3.1"
      assert JsonLogic.apply(%{"max" => ["1.1", "3.1", "3.1"]}) == "3.1"
      assert JsonLogic.apply(%{"max" => ["3.1", "2.1", "1.1"]}) == "3.1"
      assert JsonLogic.apply(%{"max" => ["3.", "2.1", "1.1"]}) == "3."
      assert JsonLogic.apply(%{"max" => ["3.1", "2.1"]}) == "3.1"
      assert JsonLogic.apply(%{"max" => ["1.1"]}) == "1.1"
      assert JsonLogic.apply(%{"max" => ["1."]}) == "1."

      assert_approx_eq(3.1, JsonLogic.apply(%{"max" => ["1.1", "2.1", 3.1]}))
      assert_approx_eq(3.1, JsonLogic.apply(%{"max" => [3.1, "2.1", "1.1"]}))
      assert_approx_eq(3.1, JsonLogic.apply(%{"max" => [3.1, "2.1"]}))
    end

    test "integer, floats, and decimals" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]
      threes = [3, 3.0, "3", "3.0", Decimal.new("3.0")]

      for one <- ones, two <- twos, three <- threes do
        assert_approx_eq(3, JsonLogic.apply(%{"max" => [one, two, three]}))
      end
    end

    test "list with non numeric value" do
      assert JsonLogic.apply(%{"max" => ["1", "2", "foo"]}) == nil
    end

    test "empty list" do
      assert JsonLogic.apply(%{"max" => []}) == nil
    end
  end

  describe "min" do
    test "returns min from vars" do
      logic = [%{"var" => "three"}, %{"var" => "one"}, %{"var" => "two"}]
      data = %{"one" => 1, "two" => 2, "three" => 3}
      assert JsonLogic.apply(%{"min" => logic}, data) == 1
    end

    test "integers" do
      assert JsonLogic.apply(%{"min" => [1, 2, 3]}) == 1
      assert JsonLogic.apply(%{"min" => [1, 3, 3]}) == 1
      assert JsonLogic.apply(%{"min" => [3, 2, 1]}) == 1
      assert JsonLogic.apply(%{"min" => [3, 2]}) == 2
      assert JsonLogic.apply(%{"min" => [1]}) == 1

      assert JsonLogic.apply(%{"min" => ["1", "2", "3"]}) == "1"
      assert JsonLogic.apply(%{"min" => ["1", "3", "3"]}) == "1"
      assert JsonLogic.apply(%{"min" => ["3", "2", "1"]}) == "1"
      assert JsonLogic.apply(%{"min" => ["3", "2"]}) == "2"
      assert JsonLogic.apply(%{"min" => ["1"]}) == "1"

      assert JsonLogic.apply(%{"min" => [1, "2", "3"]}) == 1
      assert JsonLogic.apply(%{"min" => [1, "3", "3"]}) == 1
      assert JsonLogic.apply(%{"min" => ["3", "2", 1]}) == 1
      assert JsonLogic.apply(%{"min" => ["3", 2]}) == 2
    end

    test "floats" do
      assert JsonLogic.apply(%{"min" => [1.1, 2.1, 3.1]}) == 1.1
      assert JsonLogic.apply(%{"min" => [1.1, 3.1, 3.1]}) == 1.1
      assert JsonLogic.apply(%{"min" => [3.1, 2.1, 1.1]}) == 1.1
      assert JsonLogic.apply(%{"min" => [3.1, 2.1]}) == 2.1
      assert JsonLogic.apply(%{"min" => [1.1]}) == 1.1

      assert JsonLogic.apply(%{"min" => ["1.1", "2.1", "3.1"]}) == "1.1"
      assert JsonLogic.apply(%{"min" => ["1.1", "3.1", "3.1"]}) == "1.1"
      assert JsonLogic.apply(%{"min" => ["3.1", "2.1", "1.1"]}) == "1.1"
      assert JsonLogic.apply(%{"min" => ["3.1", "2.1"]}) == "2.1"
      assert JsonLogic.apply(%{"min" => ["1.1"]}) == "1.1"

      assert JsonLogic.apply(%{"min" => ["1.", "2.1", "3.1"]}) == "1."
      assert JsonLogic.apply(%{"min" => ["1."]}) == "1."
    end

    test "integer, floats, and decimals" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]
      threes = [3, 3.0, "3", "3.0", Decimal.new("3.0")]

      for one <- ones, two <- twos, three <- threes do
        assert_approx_eq(1, JsonLogic.apply(%{"min" => [one, two, three]}))
      end
    end

    test "list with non numeric value" do
      assert JsonLogic.apply(%{"min" => ["1", "2", "foo"]}) == nil
    end

    test "empty list" do
      assert JsonLogic.apply(%{"min" => []}) == nil
    end
  end

  describe "+" do
    test "returns added result of vars" do
      assert JsonLogic.apply(%{"+" => [%{"var" => "left"}, %{"var" => "right"}]}, %{
               "left" => 5,
               "right" => 2
             }) == 7
    end

    test "handles empty list" do
      assert JsonLogic.apply(%{"+" => []}) == 0
    end

    test "integer addition" do
      assert JsonLogic.apply(%{"+" => [1, 2]}) == 3
      assert JsonLogic.apply(%{"+" => [1, 2, 3]}) == 6
      assert JsonLogic.apply(%{"+" => [1, 2, 3, 4]}) == 10
      assert JsonLogic.apply(%{"+" => [1]}) == 1

      assert JsonLogic.apply(%{"+" => [1, "2"]}) == 3
      assert JsonLogic.apply(%{"+" => [1, 2, "3"]}) == 6
      assert JsonLogic.apply(%{"+" => [1, "2", "3", 4]}) == 10
      assert JsonLogic.apply(%{"+" => ["1"]}) == 1
      assert JsonLogic.apply(%{"+" => ["1", 1]}) == 2
    end

    test "float addition" do
      assert_approx_eq(3.14, JsonLogic.apply(%{"+" => ["3.14"]}))
      assert_approx_eq(3.14, JsonLogic.apply(%{"+" => ["1.14", "2.0"]}))
    end

    test "float addition with mixed integer" do
      assert_approx_eq(3.14, JsonLogic.apply(%{"+" => ["1.14", "2"]}))
      assert_approx_eq(3.14, JsonLogic.apply(%{"+" => ["1.14", 2]}))
    end

    test "integer, float, and decimal addition" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]

      for left <- ones, right <- twos do
        assert_approx_eq(3, JsonLogic.apply(%{"+" => [left, right]}))
      end
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

    test "handles empty list" do
      assert JsonLogic.apply(%{"-" => []}) == nil
    end

    test "floating point handles" do
      assert_approx_eq(-1.1, JsonLogic.apply(%{"-" => [1.1, 2.2]}))
      assert_approx_eq(-1.2, JsonLogic.apply(%{"-" => ["1.", 2.2]}))
      assert_approx_eq(7.8, JsonLogic.apply(%{"-" => ["1.0e1", 2.2]}))
      assert_approx_eq(7.8, JsonLogic.apply(%{"-" => ["1.0E1", 2.2]}))
      assert_approx_eq(7.8, JsonLogic.apply(%{"-" => ["1.0E+1", 2.2]}))

      assert JsonLogic.apply(%{"-" => ["1.0F+1", 2.2]}) == nil
    end

    test "specification" do
      assert JsonLogic.apply(%{"-" => [1, 2]}) == -1
      assert JsonLogic.apply(%{"-" => [3, 2]}) == 1
      assert JsonLogic.apply(%{"-" => [3]}) == -3
      assert JsonLogic.apply(%{"-" => [-3]}) == 3

      assert JsonLogic.apply(%{"-" => ["1", "2"]}) == -1
      assert JsonLogic.apply(%{"-" => ["3", "2"]}) == 1
      assert JsonLogic.apply(%{"-" => ["3"]}) == -3
      assert JsonLogic.apply(%{"-" => ["-3"]}) == 3

      assert JsonLogic.apply(%{"-" => ["1", 2]}) == -1
      assert JsonLogic.apply(%{"-" => ["3", 2]}) == 1

      assert JsonLogic.apply(%{"-" => ["-1", 2]}) == -3
      assert JsonLogic.apply(%{"-" => ["-3", 2]}) == -5

      assert JsonLogic.apply(%{"-" => [1, "2"]}) == -1
      assert JsonLogic.apply(%{"-" => [3, "2"]}) == 1
    end

    test "integer, float, and decimal subtraction" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]

      for left <- ones, right <- twos do
        assert_approx_eq(-1, JsonLogic.apply(%{"-" => [left, right]}))
      end
    end
  end

  describe "*" do
    test "returns multiplied result of vars" do
      assert JsonLogic.apply(%{"*" => [%{"var" => "left"}, %{"var" => "right"}]}, %{
               "left" => 5,
               "right" => 2
             }) == 10
    end

    test "strings being multipled" do
      assert JsonLogic.apply(%{"*" => ["a", "b"]}) == nil
      assert JsonLogic.apply(%{"*" => ["a"]}) == nil
    end

    test "integer multiplication" do
      assert JsonLogic.apply(%{"*" => [1, 2]}) == 2
      assert JsonLogic.apply(%{"*" => [1, 2, 3]}) == 6
      assert JsonLogic.apply(%{"*" => [1, 2, 3, 4]}) == 24
      assert JsonLogic.apply(%{"*" => [1]}) == 1

      assert JsonLogic.apply(%{"*" => [1, "2"]}) == 2
      assert JsonLogic.apply(%{"*" => [1, 2, "3"]}) == 6
      assert JsonLogic.apply(%{"*" => [1, "2", "3", 4]}) == 24
      assert JsonLogic.apply(%{"*" => ["1"]}) == 1
      assert JsonLogic.apply(%{"*" => ["1", 1]}) == 1
    end

    test "float multiplication" do
      assert JsonLogic.apply(%{"*" => [1.0, 2.0]}) == 2.0
      assert JsonLogic.apply(%{"*" => [1.0, 2.0, 3.0]}) == 6.0
      assert JsonLogic.apply(%{"*" => [1.0, 2.0, 3.0, 4.0]}) == 24.0
      assert JsonLogic.apply(%{"*" => [1.0]}) == 1.0

      assert JsonLogic.apply(%{"*" => [1.0, "2.0"]}) == 2.0
      assert JsonLogic.apply(%{"*" => [1.0, 2.0, "3.0"]}) == 6.0
      assert JsonLogic.apply(%{"*" => [1.0, "2.0", "3.0", 4.0]}) == 24.0
      assert JsonLogic.apply(%{"*" => ["1.0"]}) == 1.0
      assert JsonLogic.apply(%{"*" => ["1.0", 1.0]}) == 1.0
    end

    test "decimal multiplication" do
      twos = [2, 2.0, "2.0", Decimal.new("2.0")]

      for left <- twos, right <- twos do
        assert_approx_eq(
          Decimal.new("4.0"),
          JsonLogic.apply(%{"*" => [left, right]})
        )
      end

      assert_approx_eq(
        Decimal.new("8.0"),
        JsonLogic.apply(%{
          "*" => [
            Decimal.new("2.0"),
            Decimal.new("2.0"),
            Decimal.new("2.0")
          ]
        })
      )

      assert JsonLogic.apply(%{"*" => ["1", "foo"]}) == nil
      assert JsonLogic.apply(%{"*" => [1, "foo"]}) == nil
      assert JsonLogic.apply(%{"*" => [1.0, "foo"]}) == nil
      assert JsonLogic.apply(%{"*" => ["1.0", "foo"]}) == nil
      assert JsonLogic.apply(%{"*" => ["foo", "1"]}) == nil
      assert JsonLogic.apply(%{"*" => ["foo", 1]}) == nil
      assert JsonLogic.apply(%{"*" => ["foo", 1.0]}) == nil
      assert JsonLogic.apply(%{"*" => ["foo", "1.0"]}) == nil
    end
  end

  describe "/" do
    test "returns multiplied result of vars" do
      assert JsonLogic.apply(%{"/" => [%{"var" => "left"}, %{"var" => "right"}]}, %{
               "left" => 5,
               "right" => 2
             }) == 2.5
    end

    test "integer division" do
      assert JsonLogic.apply(%{"/" => [4, 2]}) == 2
      assert JsonLogic.apply(%{"/" => [4, "2"]}) == 2
      assert JsonLogic.apply(%{"/" => ["4", "2"]}) == 2
      assert JsonLogic.apply(%{"/" => ["4", 2]}) == 2

      assert JsonLogic.apply(%{"/" => [2, 4]}) == 0.5
      assert JsonLogic.apply(%{"/" => ["2", 4]}) == 0.5
      assert JsonLogic.apply(%{"/" => ["2", "4"]}) == 0.5
      assert JsonLogic.apply(%{"/" => [2, "4"]}) == 0.5

      assert JsonLogic.apply(%{"/" => ["1", 1]}) == 1
      assert JsonLogic.apply(%{"/" => ["1", "1"]}) == 1
      assert JsonLogic.apply(%{"/" => [1, "1"]}) == 1
    end

    test "float division" do
      assert JsonLogic.apply(%{"/" => [2.0, 4.0]}) == 0.5
      assert JsonLogic.apply(%{"/" => ["2.0", 4.0]}) == 0.5
      assert JsonLogic.apply(%{"/" => ["2.0", "4.0"]}) == 0.5
      assert JsonLogic.apply(%{"/" => [2.0, "4.0"]}) == 0.5
    end

    test "decimal division" do
      twos = [2, 2.0, "2.0", Decimal.new("2.0")]

      for left <- twos, right <- twos do
        assert_approx_eq(
          Decimal.new("1.0"),
          JsonLogic.apply(%{"/" => [left, right]})
        )
      end

      assert JsonLogic.apply(%{"/" => ["1", "foo"]}) == nil
      assert JsonLogic.apply(%{"/" => [1, "foo"]}) == nil
      assert JsonLogic.apply(%{"/" => [1.0, "foo"]}) == nil
      assert JsonLogic.apply(%{"/" => ["1.0", "foo"]}) == nil
      assert JsonLogic.apply(%{"/" => ["foo", "1"]}) == nil
      assert JsonLogic.apply(%{"/" => ["foo", 1]}) == nil
      assert JsonLogic.apply(%{"/" => ["foo", 1.0]}) == nil
      assert JsonLogic.apply(%{"/" => ["foo", "1.0"]}) == nil
    end
  end

  describe "%" do
    test "integer, float, and decimal remainders" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]

      for left <- ones, right <- twos do
        assert_approx_eq(1.0, JsonLogic.apply(%{"%" => [left, right]}))
      end
    end
  end

  describe ">" do
    test "comparison with variables" do
      logic = %{">" => [%{"var" => "quantity"}, 25]}
      data = %{"quantity" => 1}
      assert JsonLogic.apply(logic, data) == false

      logic = %{">" => [%{"var" => "quantity"}, 25]}
      data = %{"abc" => 1}
      assert JsonLogic.apply(logic, data) == false
    end

    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        refute JsonLogic.apply(%{">" => [left, right]})
      end

      for left <- twos, right <- ones do
        assert JsonLogic.apply(%{">" => [left, right]})
      end

      for left <- ones, right <- twos do
        refute JsonLogic.apply(%{">" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{">" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{">" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{">" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end
    end
  end

  describe ">=" do
    test "number compared to non numeric string" do
      refute JsonLogic.apply(%{">=" => [1, "foo"]})
      refute JsonLogic.apply(%{">=" => ["foo", 1]})
    end

    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        assert JsonLogic.apply(%{">=" => [left, right]})
      end

      for left <- twos, right <- ones do
        assert JsonLogic.apply(%{">=" => [left, right]})
      end

      for left <- ones, right <- twos do
        refute JsonLogic.apply(%{">=" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{">=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{">=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{">=" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end
    end
  end

  describe "<" do
    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        refute JsonLogic.apply(%{"<" => [left, right]})
      end

      for left <- twos, right <- ones do
        refute JsonLogic.apply(%{"<" => [left, right]})
      end

      for left <- ones, right <- twos do
        assert JsonLogic.apply(%{"<" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{"<" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{"<" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{"<" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end
    end
  end

  describe "<=" do
    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        assert JsonLogic.apply(%{"<=" => [left, right]})
      end

      for left <- twos, right <- ones do
        refute JsonLogic.apply(%{"<=" => [left, right]})
      end

      for left <- ones, right <- twos do
        assert JsonLogic.apply(%{"<=" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{"<=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{"<=" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{"<=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogic.apply(logic, %{"left" => left, "right" => right})
      end
    end
  end

  describe "between" do
    test "exclusive" do
      assert JsonLogic.apply(%{"<" => [1, 2, 3]})
      refute JsonLogic.apply(%{"<" => [1, 1, 3]})
      refute JsonLogic.apply(%{"<" => [1, 3, 3]})
      refute JsonLogic.apply(%{"<" => [1, 4, 3]})
    end

    test "inclusive" do
      assert JsonLogic.apply(%{"<=" => [1, 2, 3]})
      assert JsonLogic.apply(%{"<=" => [1, 1, 3]})
      assert JsonLogic.apply(%{"<=" => [1, 3, 3]})
      refute JsonLogic.apply(%{"<=" => [1, 4, 3]})
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

    test "Bart is found in the list" do
      logic = %{"in" => ["Bart", ["Bart", "Homer", "Lisa", "Marge", "Maggie"]]}

      assert JsonLogic.apply(logic)
    end

    test "Milhouse is not found in the list" do
      logic = %{
        "in" => ["Milhouse", ["Bart", "Homer", "Lisa", "Marge", "Maggie"]]
      }

      refute JsonLogic.apply(logic)
    end

    test "finding a string in a string" do
      assert JsonLogic.apply(%{"in" => ["Spring", "Springfield"]})
      refute JsonLogic.apply(%{"in" => ["i", "team"]})
    end

    test "raises on non-enumerable list" do
      assert_raise(ArgumentError, fn ->
        logic = %{"in" => [%{"var" => "users.id"}, 1]}
        JsonLogic.apply(logic, nil)
      end)
    end
  end

  describe "merge" do
    test "empty array" do
      assert JsonLogic.apply(%{"merge" => []}) == []
    end

    test "flattens arrays" do
      assert JsonLogic.apply(%{"merge" => [[1]]}) == [1]
      assert JsonLogic.apply(%{"merge" => [[1], []]}) == [1]
      assert JsonLogic.apply(%{"merge" => [[1], [2]]}) == [1, 2]
      assert JsonLogic.apply(%{"merge" => [[1], [2], [3]]}) == [1, 2, 3]
      assert JsonLogic.apply(%{"merge" => [[1, 2], [3]]}) == [1, 2, 3]
      assert JsonLogic.apply(%{"merge" => [[1], [2, 3]]}) == [1, 2, 3]
      assert JsonLogic.apply(%{"merge" => [[1, 2], [3, 4]]}) == [1, 2, 3, 4]
    end

    test "non array argumnets" do
      assert JsonLogic.apply(%{"merge" => nil}) == [nil]
      assert JsonLogic.apply(%{"merge" => 1}, nil) == [1]
      assert JsonLogic.apply(%{"merge" => [1, 2]}) == [1, 2]
      assert JsonLogic.apply(%{"merge" => [1, [2]]}) == [1, 2]
    end
  end

  describe "and" do
    test "nested rules" do
      logic = %{
        "and" => [
          %{">" => [3, 1]},
          %{"<" => [1, 3]}
        ]
      }

      assert JsonLogic.apply(logic) == true
    end
  end

  describe "substr" do
    test "substr with only start" do
      assert JsonLogic.apply(%{"substr" => ["jsonlogic", 4]}) == "logic"
      assert JsonLogic.apply(%{"substr" => ["jsonlogic", -5]}) == "logic"
      assert JsonLogic.apply(%{"substr" => ["jsonlögic", -5]}) == "lögic"
      assert JsonLogic.apply(%{"substr" => ["jsönlögic", -5]}) == "lögic"

      assert JsonLogic.apply(%{"substr" => ["", 4]}) == ""
      assert JsonLogic.apply(%{"substr" => ["", -4]}) == ""

      assert JsonLogic.apply(%{"substr" => ["Göödnight", 4]}) == "night"
      assert JsonLogic.apply(%{"substr" => ["Göödnight", 2]}) == "ödnight"
    end

    test "substr with start and character count" do
      assert JsonLogic.apply(%{"substr" => ["jsonlogic", 0, 1]}) == "j"
      assert JsonLogic.apply(%{"substr" => ["jsonlogic", -1, 1]}) == "c"
      assert JsonLogic.apply(%{"substr" => ["jsonlogic", 4, 5]}) == "logic"
      assert JsonLogic.apply(%{"substr" => ["jsonlögic", 4, 5]}) == "lögic"
      assert JsonLogic.apply(%{"substr" => ["jsönlögic", 4, 5]}) == "lögic"

      assert JsonLogic.apply(%{"substr" => ["jsonlogic", -5, 5]}) == "logic"
      assert JsonLogic.apply(%{"substr" => ["jsonlögic", -5, 5]}) == "lögic"
      assert JsonLogic.apply(%{"substr" => ["jsönlögic", -5, 5]}) == "lögic"

      assert JsonLogic.apply(%{"substr" => ["jsönlögic", -5, -2]}) == "lög"
      assert JsonLogic.apply(%{"substr" => ["jsönlogic", -5, -2]}) == "log"

      assert JsonLogic.apply(%{"substr" => ["jsonlogic", 1, -5]}) == "son"
      assert JsonLogic.apply(%{"substr" => ["jsönlogic", 1, -5]}) == "sön"
    end
  end

  describe "arrays with logic" do
    test "using a variable" do
      logic = [1, %{"var" => "x"}, 3]
      data = %{"x" => 2}
      assert JsonLogic.apply(logic, data) == [1, 2, 3]
    end

    test "using a variable in an if" do
      logic = %{"if" => [%{"var" => "x"}, %{"var" => "y"}, 99]}
      data = %{"x" => true, "y" => 2}
      assert JsonLogic.apply(logic, data) == 2

      logic = %{"if" => [%{"var" => "x"}, [%{"var" => "y"}], [99]]}
      data = %{"x" => true, "y" => 2}
      assert JsonLogic.apply(logic, data) == [2]

      logic = %{"if" => [%{"var" => "x"}, %{"var" => "y"}, 99]}
      data = %{"x" => false, "y" => 2}
      assert JsonLogic.apply(logic, data) == 99

      logic = %{"if" => [%{"var" => "x"}, [%{"var" => "y"}], [99]]}
      data = %{"x" => false, "y" => 2}
      assert JsonLogic.apply(logic, data) == [99]
    end

    test "compount test" do
      logic = %{"and" => [%{">" => [3, 1]}, true]}
      assert JsonLogic.apply(logic, %{})

      logic = %{"and" => [%{">" => [3, 1]}, false]}
      refute JsonLogic.apply(logic, %{})

      logic = %{"and" => [%{">" => [3, 1]}, %{"!" => true}]}
      refute JsonLogic.apply(logic, %{})

      logic = %{"and" => [%{">" => [3, 1]}, %{"<" => [1, 3]}]}
      assert JsonLogic.apply(logic, %{})

      logic = %{"?:" => [%{">" => [3, 1]}, "visible", "hidden"]}
      assert JsonLogic.apply(logic, %{}) == "visible"
    end

    test "data driven" do
      logic = %{"var" => ["a"]}
      data = %{"a" => 1}
      assert JsonLogic.apply(logic, data) == 1

      logic = %{"var" => ["b"]}
      data = %{"a" => 1}
      assert JsonLogic.apply(logic, data) == nil

      logic = %{"var" => ["a"]}
      assert JsonLogic.apply(logic, nil) == nil

      logic = %{"var" => "a"}
      data = %{"a" => 1}
      assert JsonLogic.apply(logic, data) == 1

      logic = %{"var" => "b"}
      data = %{"a" => 1}
      assert JsonLogic.apply(logic, data) == nil

      logic = %{"var" => "a"}
      assert JsonLogic.apply(logic, nil) == nil

      logic = %{"var" => ["a", 1]}
      assert JsonLogic.apply(logic, nil) == 1

      logic = %{"var" => ["b", 2]}
      data = %{"a" => 1}
      assert JsonLogic.apply(logic, data) == 2

      logic = %{"var" => "a.b"}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogic.apply(logic, data) == "c"

      logic = %{"var" => "a.q"}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogic.apply(logic, data) == nil

      logic = %{"var" => ["a.q", 9]}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogic.apply(logic, data) == 9

      logic = %{"var" => 1}
      data = ["apple", "banana"]
      assert JsonLogic.apply(logic, data) == "banana"

      logic = %{"var" => "1"}
      data = ["apple", "banana"]
      assert JsonLogic.apply(logic, data) == "banana"

      logic = %{"var" => "1.1"}
      data = ["apple", ["banana", "beer"]]
      assert JsonLogic.apply(logic, data) == "beer"

      logic = %{
        "and" => [
          %{"<" => [%{"var" => "temp"}, 110]},
          %{"==" => [%{"var" => "pie.filling"}, "apple"]}
        ]
      }

      data = %{"pie" => %{"filling" => "apple"}, "temp" => 100}
      assert JsonLogic.apply(logic, data)

      logic = %{
        "var" => [
          %{
            "?:" => [
              %{"<" => [%{"var" => "temp"}, 110]},
              "pie.filling",
              "pie.eta"
            ]
          }
        ]
      }

      data = %{"pie" => %{"eta" => "60s", "filling" => "apple"}, "temp" => 100}
      assert JsonLogic.apply(logic, data) == "apple"

      logic = %{"in" => [%{"var" => "filling"}, ["apple", "cherry"]]}
      data = %{"filling" => "apple"}
      assert JsonLogic.apply(logic, data)

      logic = %{"var" => "a.b.c"}
      assert JsonLogic.apply(logic, nil) == nil

      logic = %{"var" => "a.b.c"}
      data = %{"a" => nil}
      assert JsonLogic.apply(logic, data) == nil

      logic = %{"var" => "a.b.c"}
      data = %{"a" => %{"b" => nil}}
      assert JsonLogic.apply(logic, data) == nil

      logic = %{"var" => ""}
      assert JsonLogic.apply(logic, 1) == 1

      logic = %{"var" => nil}
      assert JsonLogic.apply(logic, 1) == 1

      logic = %{"var" => []}
      assert JsonLogic.apply(logic, 1) == 1
    end
  end

  describe "missing" do
    test "missing and If are friends, because empty arrays are falsey in JsonLogic" do
      logic = %{"if" => [%{"missing" => "a"}, "missed it", "found it"]}
      data = %{"a" => "apple"}
      assert JsonLogic.apply(logic, data) == "found it"

      logic = %{"if" => [%{"missing" => "a"}, "missed it", "found it"]}
      data = %{"b" => "banana"}
      assert JsonLogic.apply(logic, data) == "missed it"
    end

    test "missing, merge, and if are friends. VIN is always required, APR is only required if financing is true." do
      logic = %{
        "missing" => %{
          "merge" => ["vin", %{"if" => [%{"var" => "financing"}, ["apr"], []]}]
        }
      }

      data = %{"financing" => true}
      assert JsonLogic.apply(logic, data) == ["vin", "apr"]

      logic = %{
        "missing" => %{
          "merge" => ["vin", %{"if" => [%{"var" => "financing"}, ["apr"], []]}]
        }
      }

      data = %{"financing" => false}
      assert JsonLogic.apply(logic, data) == ["vin"]
    end
  end

  describe "collections" do
    test "filter, map, all, none, and some" do
      logic = %{"filter" => [%{"var" => "integers"}, true]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data) == [1, 2, 3]

      logic = %{"filter" => [%{"var" => "integers"}, false]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data) == []

      logic = %{"filter" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data) == [2, 3]

      logic = %{"filter" => [%{"var" => "integers"}, %{"%" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data) == [1, 3]

      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data) == [2, 4, 6]

      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
      assert JsonLogic.apply(logic, nil) == []

      logic = %{"map" => [%{"var" => "desserts"}, %{"var" => "qty"}]}

      data = %{
        "desserts" => [
          %{"name" => "apple", "qty" => 1},
          %{"name" => "brownie", "qty" => 2},
          %{"name" => "cupcake", "qty" => 3}
        ]
      }

      assert JsonLogic.apply(logic, data) == [1, 2, 3]

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogic.apply(logic, data) == 10

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = nil
      assert JsonLogic.apply(logic, data) == 0

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"*" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          1
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogic.apply(logic, data) == 24

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"*" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogic.apply(logic, data) == 0

      logic = %{
        "reduce" => [
          %{"var" => "desserts"},
          %{"+" => [%{"var" => "accumulator"}, %{"var" => "current.qty"}]},
          0
        ]
      }

      data = %{
        "desserts" => [
          %{"name" => "apple", "qty" => 1},
          %{"name" => "brownie", "qty" => 2},
          %{"name" => "cupcake", "qty" => 3}
        ]
      }

      assert JsonLogic.apply(logic, data) == 6

      logic = %{"all" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data)

      logic = %{"all" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogic.apply(logic, data)

      logic = %{"all" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogic.apply(logic, data)

      logic = %{"all" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      refute JsonLogic.apply(logic, data)

      logic = %{"all" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.apply(logic, data)

      logic = %{"all" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogic.apply(logic, data)

      logic = %{"all" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogic.apply(logic, data)

      logic = %{"all" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      refute JsonLogic.apply(logic, data)

      logic = %{"none" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogic.apply(logic, data)

      logic = %{"none" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogic.apply(logic, data)

      logic = %{"none" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data)

      logic = %{"none" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      assert JsonLogic.apply(logic, data)

      logic = %{"none" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogic.apply(logic, data)

      logic = %{"none" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogic.apply(logic, data)

      logic = %{"none" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.apply(logic, data)

      logic = %{"none" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      assert JsonLogic.apply(logic, data)

      logic = %{"some" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data)

      logic = %{"some" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.apply(logic, data)

      logic = %{"some" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogic.apply(logic, data)

      logic = %{"some" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      refute JsonLogic.apply(logic, data)

      logic = %{"some" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.apply(logic, data)

      logic = %{"some" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.apply(logic, data)

      logic = %{"some" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogic.apply(logic, data)

      logic = %{"some" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      refute JsonLogic.apply(logic, data)
    end
  end

  describe "data does not contain the param specified in conditions" do
    test "cannot compare nil" do
      assert JsonLogic.apply(%{"==" => [nil, nil]})
      assert JsonLogic.apply(%{"<" => [nil, nil]})
      assert JsonLogic.apply(%{">" => [nil, nil]})
      assert JsonLogic.apply(%{"<=" => [nil, nil]})
      assert JsonLogic.apply(%{">=" => [nil, nil]})

      logic = %{"<=" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogic.apply(logic, data)

      logic = %{">=" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogic.apply(logic, data)

      logic = %{"==" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogic.apply(logic, data)

      refute JsonLogic.apply(%{">" => [5, nil]})
      refute JsonLogic.apply(%{">" => [nil, 5]})
      refute JsonLogic.apply(%{">=" => [5, nil]})
      refute JsonLogic.apply(%{">=" => [nil, 5]})

      refute JsonLogic.apply(%{"<" => [5, nil]})
      refute JsonLogic.apply(%{"<" => [nil, 5]})
      refute JsonLogic.apply(%{"<=" => [5, nil]})
      refute JsonLogic.apply(%{"<=" => [nil, 5]})

      logic = %{">" => [%{"var" => "quantity"}, 25]}
      data = %{"abc" => 1}
      refute JsonLogic.apply(logic, data)

      logic = %{"<" => [%{"var" => "quantity"}, 25]}
      data = %{"abc" => 1}
      refute JsonLogic.apply(logic, data)

      logic = %{
        "and" => [
          %{">" => [%{"var" => "quantity"}, 25]},
          %{">" => [%{"var" => "durations"}, 23]}
        ]
      }

      data = %{"code" => "FUM", "occurence" => 15}
      refute JsonLogic.apply(logic, data)

      logic = %{
        "or" => [
          %{
            "and" => [
              %{">" => [%{"var" => "accessorial_service.occurence"}, 5]},
              %{"==" => [%{"var" => "accessorial_service.code"}, "WAT"]}
            ]
          },
          %{
            "and" => [
              %{">" => [%{"var" => "accessorial_service.occurence"}, 0]},
              %{"==" => [%{"var" => "accessorial_service.code"}, "washing"]}
            ]
          }
        ]
      }

      data = %{"accessorial_service" => %{"code" => "WAT", "occurence" => 15}}
      assert JsonLogic.apply(logic, data)

      data = %{"accessorial_service" => %{"code" => "FUM", "occurence" => 15}}
      refute JsonLogic.apply(logic, data)
    end
  end

  describe "all" do
    test "returns false for `nil` lists" do
      assert JsonLogic.apply(%{"all" => [nil, true]}, %{}) == false
      assert JsonLogic.apply(%{"all" => [%{"var" => "list"}, true]}, %{}) == false
      assert JsonLogic.apply(%{"all" => [%{"var" => "list"}, true]}, %{"list" => nil}) == false
    end

    test "returns false for non-lists" do
      assert JsonLogic.apply(%{"all" => ["foo", true]}, %{}) == false
      assert JsonLogic.apply(%{"all" => [42, true]}, %{}) == false
    end
  end

  describe "some" do
    test "returns false for `nil` lists" do
      assert JsonLogic.apply(%{"some" => [nil, true]}, %{}) == false
      assert JsonLogic.apply(%{"some" => [%{"var" => "list"}, true]}, %{}) == false
      assert JsonLogic.apply(%{"some" => [%{"var" => "list"}, true]}, %{"list" => nil}) == false
    end

    test "returns false for non-lists" do
      assert JsonLogic.apply(%{"some" => ["foo", true]}, %{}) == false
      assert JsonLogic.apply(%{"some" => [42, true]}, %{}) == false
    end
  end

  describe "none" do
    test "returns true for `nil` lists" do
      assert JsonLogic.apply(%{"none" => [nil, true]}, %{}) == true
      assert JsonLogic.apply(%{"none" => [%{"var" => "list"}, true]}, %{}) == true
      assert JsonLogic.apply(%{"none" => [%{"var" => "list"}, true]}, %{"list" => nil}) == true
    end

    test "returns true for non-lists" do
      assert JsonLogic.apply(%{"none" => ["foo", true]}, %{}) == true
      assert JsonLogic.apply(%{"none" => [42, true]}, %{}) == true
    end
  end

  describe "log" do
    test "that log is just a pass throug" do
      assert JsonLogic.apply(%{"log" => [1]}) == [1]
    end
  end

  describe "unsupported operation" do
    test "raises exception" do
      assert_raise(ArgumentError, fn ->
        JsonLogic.apply(%{"doesnotexist" => 1})
      end)
    end
  end

  describe "providing a json object" do
    test "passes through the results" do
      # This is the expected result according to
      #
      # https://jsonlogic.com/play.html
      logic = %{"-" => [1, 1], "+" => [1, 1]}
      assert logic == JsonLogic.apply(logic)
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
