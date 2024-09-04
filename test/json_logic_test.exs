defmodule JsonLogicXLTest do
  use ExUnit.Case, async: true

  describe "non rules" do
    test "nil" do
      assert JsonLogicXL.resolve(nil) == nil
    end

    test "empty map" do
      assert JsonLogicXL.resolve(%{}) == %{}
    end

    test "true" do
      assert JsonLogicXL.resolve(true) == true
    end

    test "false" do
      assert JsonLogicXL.resolve(false) == false
    end

    test "integer" do
      assert JsonLogicXL.resolve(17) == 17
    end

    test "float" do
      assert JsonLogicXL.resolve(3.14) == 3.14
    end

    test "string" do
      assert JsonLogicXL.resolve("apple") == "apple"
    end

    test "null" do
      assert JsonLogicXL.resolve(nil) == nil
    end

    test "list of strings" do
      assert JsonLogicXL.resolve(["a", "b"]) == ["a", "b"]
    end
  end

  describe "var" do
    test "returns from array inside hash" do
      logic = %{"var" => "key.1"}
      data = %{"key" => %{"1" => "a"}}
      assert JsonLogicXL.resolve(logic, data) == "a"

      logic = %{"var" => "key.1"}
      data = %{"key" => ~w{a b}}
      assert JsonLogicXL.resolve(logic, data) == "b"
    end
  end

  describe "==" do
    test "nested true" do
      logic = %{"==" => [true, %{"==" => [1, 1]}]}
      assert JsonLogicXL.resolve(logic)
    end

    test "nested false" do
      logic = %{"==" => [false, %{"==" => [0, 1]}]}
      assert JsonLogicXL.resolve(logic)
    end

    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        assert JsonLogicXL.resolve(%{"==" => [left, right]})
      end

      for left <- twos, right <- ones do
        refute JsonLogicXL.resolve(%{"==" => [left, right]})
      end

      for left <- ones, right <- twos do
        refute JsonLogicXL.resolve(%{"==" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{"==" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{"==" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{"==" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      assert JsonLogicXL.resolve(%{"==" => [3.14, 1.0 + 2.14]})
      refute JsonLogicXL.resolve(%{"==" => [3.14, 3.1399999999999997]})
    end
  end

  describe "!=" do
    test "nested true" do
      assert JsonLogicXL.resolve(%{"!=" => [false, %{"!=" => [0, 1]}]})
    end

    test "nested false" do
      assert JsonLogicXL.resolve(%{"!=" => [true, %{"!=" => [1, 1]}]})
    end

    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        refute JsonLogicXL.resolve(%{"!=" => [left, right]})
      end

      for left <- twos, right <- ones do
        assert JsonLogicXL.resolve(%{"!=" => [left, right]})
      end

      for left <- ones, right <- twos do
        assert JsonLogicXL.resolve(%{"!=" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{"!=" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{"!=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{"!=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      refute JsonLogicXL.resolve(%{"!=" => [3.14, 1.0 + 2.14]})
      assert JsonLogicXL.resolve(%{"!=" => [3.14, 3.1399999999999997]})
    end
  end

  describe "===" do
    test "nested true" do
      assert JsonLogicXL.resolve(%{"===" => [true, %{"===" => [1, 1]}]})
    end

    test "nested false" do
      assert JsonLogicXL.resolve(%{"===" => [false, %{"===" => [1, 1.0]}]})
    end

    test "integer comparisons" do
      assert JsonLogicXL.resolve(%{"===" => [1, 1]})
      refute JsonLogicXL.resolve(%{"===" => [1, "1"]})
      assert JsonLogicXL.resolve(%{"===" => ["1", "1"]})
      refute JsonLogicXL.resolve(%{"===" => ["1", 1]})

      refute JsonLogicXL.resolve(%{"===" => [1, 2]})
      refute JsonLogicXL.resolve(%{"===" => [1, "2"]})
      refute JsonLogicXL.resolve(%{"===" => ["1", "2"]})
      refute JsonLogicXL.resolve(%{"===" => ["1", 2]})
    end

    test "float comparisons" do
      assert JsonLogicXL.resolve(%{"===" => [1.0, 1.0]})
      refute JsonLogicXL.resolve(%{"===" => [1.0, "1.0"]})
      assert JsonLogicXL.resolve(%{"===" => ["1.0", "1.0"]})
      refute JsonLogicXL.resolve(%{"===" => ["1.0", 1.0]})

      refute JsonLogicXL.resolve(%{"===" => [1.0, 2.0]})
      refute JsonLogicXL.resolve(%{"===" => [1.0, "2.0"]})
      refute JsonLogicXL.resolve(%{"===" => ["1.0", "2.0"]})
      refute JsonLogicXL.resolve(%{"===" => ["1.0", 2.0]})
    end

    test "decimal comparisons" do
      refute JsonLogicXL.resolve(%{"===" => ["1.0", Decimal.new("1.0")]})
      refute JsonLogicXL.resolve(%{"===" => [1.0, Decimal.new("1.0")]})
      refute JsonLogicXL.resolve(%{"===" => [1, Decimal.new("1.0")]})
      refute JsonLogicXL.resolve(%{"===" => [1, Decimal.new("1")]})
      refute JsonLogicXL.resolve(%{"===" => [Decimal.new("1.0"), "1.0"]})
      refute JsonLogicXL.resolve(%{"===" => [Decimal.new("1.0"), 1.0]})
      refute JsonLogicXL.resolve(%{"===" => [Decimal.new("1.0"), 1]})
      refute JsonLogicXL.resolve(%{"===" => [Decimal.new("1"), 1]})

      assert JsonLogicXL.resolve(%{"===" => [Decimal.new("1.0"), Decimal.new("1.0")]})
      refute JsonLogicXL.resolve(%{"===" => [Decimal.new("1.00"), Decimal.new("1.0")]})
      refute JsonLogicXL.resolve(%{"===" => [Decimal.new("1.0"), Decimal.new("1.00")]})
    end
  end

  describe "!==" do
    test "nested true" do
      assert JsonLogicXL.resolve(%{"!==" => [false, %{"!==" => [1, 1.0]}]})
    end

    test "nested false" do
      assert JsonLogicXL.resolve(%{"!==" => [true, %{"!==" => [1, 1]}]})
    end

    test "integer comparisons" do
      refute JsonLogicXL.resolve(%{"!==" => [1, 1]})
      assert JsonLogicXL.resolve(%{"!==" => [1, 2]})
      assert JsonLogicXL.resolve(%{"!==" => [1, "1"]})
      refute JsonLogicXL.resolve(%{"!==" => ["1", "1"]})
      assert JsonLogicXL.resolve(%{"!==" => ["1", 1]})
    end

    test "float comparisons" do
      refute JsonLogicXL.resolve(%{"!==" => [1.0, 1.0]})
      assert JsonLogicXL.resolve(%{"!==" => [1.0, 2.0]})
      assert JsonLogicXL.resolve(%{"!==" => [1.0, "1.0"]})
      refute JsonLogicXL.resolve(%{"!==" => ["1.0", "1.0"]})
      assert JsonLogicXL.resolve(%{"!==" => ["1.0", 1.0]})
    end

    test "decimal comparisons" do
      assert JsonLogicXL.resolve(%{"!==" => ["1.0", Decimal.new("1.0")]})
      assert JsonLogicXL.resolve(%{"!==" => [1.0, Decimal.new("1.0")]})
      assert JsonLogicXL.resolve(%{"!==" => [1, Decimal.new("1.0")]})
      assert JsonLogicXL.resolve(%{"!==" => [1, Decimal.new("1")]})
      assert JsonLogicXL.resolve(%{"!==" => [Decimal.new("1.0"), "1.0"]})
      assert JsonLogicXL.resolve(%{"!==" => [Decimal.new("1.0"), 1.0]})
      assert JsonLogicXL.resolve(%{"!==" => [Decimal.new("1.0"), 1]})
      assert JsonLogicXL.resolve(%{"!==" => [Decimal.new("1"), 1]})

      refute JsonLogicXL.resolve(%{"!==" => [Decimal.new("1.0"), Decimal.new("1.0")]})
      assert JsonLogicXL.resolve(%{"!==" => [Decimal.new("1.00"), Decimal.new("1.0")]})
      assert JsonLogicXL.resolve(%{"!==" => [Decimal.new("1.0"), Decimal.new("1.00")]})
    end
  end

  describe "!" do
    test "returns true with [false]" do
      assert JsonLogicXL.resolve(%{"!" => [false]})
    end

    test "returns false with [true]" do
      refute JsonLogicXL.resolve(%{"!" => [true]})
    end

    test "returns true with [false] from data" do
      logic = %{"!" => [%{"var" => "key"}]}
      data = %{"key" => false}
      assert JsonLogicXL.resolve(logic, data)
    end

    test "notting boolean" do
      assert JsonLogicXL.resolve(%{"!" => [false]})
      assert JsonLogicXL.resolve(%{"!" => false})
      refute JsonLogicXL.resolve(%{"!" => [true]})
      refute JsonLogicXL.resolve(%{"!" => true})
    end

    test "notting nil" do
      assert JsonLogicXL.resolve(%{"!" => nil})
      assert JsonLogicXL.resolve(%{"!" => [nil]})
      refute JsonLogicXL.resolve(%{"!" => [nil, nil]})
    end

    test "notting numbers" do
      assert JsonLogicXL.resolve(%{"!" => 0})
      refute JsonLogicXL.resolve(%{"!" => 1})
      refute JsonLogicXL.resolve(%{"!" => -1})
      refute JsonLogicXL.resolve(%{"!" => 100})
      refute JsonLogicXL.resolve(%{"!" => 0.0})
      refute JsonLogicXL.resolve(%{"!" => 1.0})
      refute JsonLogicXL.resolve(%{"!" => -1.0})
      refute JsonLogicXL.resolve(%{"!" => Decimal.new("1.0")})
    end

    test "notting vars" do
      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => 0}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => 1}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => 1.0}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => 0.0}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"!" => [%{"var" => "foo"}]}
      data = %{"foo" => Decimal.new("1.0")}
      refute JsonLogicXL.resolve(logic, data)
    end
  end

  describe "if" do
    test "returns var when true" do
      logic = %{"if" => [true, %{"var" => "key"}, "unexpected"]}
      data = %{"key" => "yes"}
      assert JsonLogicXL.resolve(logic, data) == "yes"
    end

    test "returns var when false" do
      logic = %{"if" => [false, "unexpected", %{"var" => "key"}]}
      data = %{"key" => "no"}
      assert JsonLogicXL.resolve(logic, data) == "no"
    end

    test "returns var with multiple branches" do
      logic = %{"if" => [false, "unexpected", false, "unexpected", %{"var" => "key"}]}
      data = %{"key" => "default"}

      assert JsonLogicXL.resolve(logic, data) == "default"
    end

    test "returns nil when else is not present" do
      assert JsonLogicXL.resolve(%{"if" => [false, "unexpected"]}) == nil
    end

    test "too few args" do
      assert JsonLogicXL.resolve(%{"if" => []}) == nil
      assert JsonLogicXL.resolve(%{"if" => [true]}) == true
      assert JsonLogicXL.resolve(%{"if" => [false]}) == false
      assert JsonLogicXL.resolve(%{"if" => ["apple"]}) == "apple"
    end

    test "simple if then else cases" do
      assert JsonLogicXL.resolve(%{"if" => [true, "apple"]}) == "apple"
      assert JsonLogicXL.resolve(%{"if" => [false, "apple"]}) == nil
      assert JsonLogicXL.resolve(%{"if" => [true, "apple", "banana"]}) == "apple"
      assert JsonLogicXL.resolve(%{"if" => [false, "apple", "banana"]}) == "banana"
    end

    test "empty arrays are falsey" do
      assert JsonLogicXL.resolve(%{"if" => [[], "apple", "banana"]}) == "banana"
      assert JsonLogicXL.resolve(%{"if" => [[1], "apple", "banana"]}) == "apple"
      assert JsonLogicXL.resolve(%{"if" => [[1, 2, 3, 4], "apple", "banana"]}) == "apple"
    end

    test "empty strings are falsey, all other strings are truthy" do
      assert JsonLogicXL.resolve(%{"if" => ["", "apple", "banana"]}) == "banana"
      assert JsonLogicXL.resolve(%{"if" => ["zucchini", "apple", "banana"]}) == "apple"
      assert JsonLogicXL.resolve(%{"if" => ["0", "apple", "banana"]}) == "apple"
    end

    test "you can cast a string to numeric with a unary + " do
      assert JsonLogicXL.resolve(%{"===" => [0, "0"]}) == false
      assert JsonLogicXL.resolve(%{"===" => [0, %{"+" => "0"}]}) == true
      assert JsonLogicXL.resolve(%{"if" => ["", "apple", "banana"]}) == "banana"
      assert JsonLogicXL.resolve(%{"if" => [%{"+" => "0"}, "apple", "banana"]}) == "banana"
      assert JsonLogicXL.resolve(%{"if" => [%{"+" => "1"}, "apple", "banana"]}) == "apple"
    end

    test "zero is falsy, all other numbers are truthy" do
      assert JsonLogicXL.resolve(%{"if" => [0, "apple", "banana"]}) == "banana"
      assert JsonLogicXL.resolve(%{"if" => [1, "apple", "banana"]}) == "apple"
      assert JsonLogicXL.resolve(%{"if" => [3.1416, "apple", "banana"]}) == "apple"
      assert JsonLogicXL.resolve(%{"if" => [-1, "apple", "banana"]}) == "apple"
    end

    test "truthy and falsy definitions matter in boolean operations" do
      assert JsonLogicXL.resolve(%{"!" => [[]]}) == true
      assert JsonLogicXL.resolve(%{"!!" => [[]]}) == false
      assert JsonLogicXL.resolve(%{"and" => [[], true]}) == []
      assert JsonLogicXL.resolve(%{"or" => [[], true]}) == true
      assert JsonLogicXL.resolve(%{"!" => [0]}) == true
      assert JsonLogicXL.resolve(%{"!!" => [0]}) == false
      assert JsonLogicXL.resolve(%{"and" => [0, true]}) == 0
      assert JsonLogicXL.resolve(%{"or" => [0, true]}) == true
      assert JsonLogicXL.resolve(%{"!" => [""]}) == true
      assert JsonLogicXL.resolve(%{"!!" => [""]}) == false
      assert JsonLogicXL.resolve(%{"and" => ["", true]}) == ""
      assert JsonLogicXL.resolve(%{"or" => ["", true]}) == true
      assert JsonLogicXL.resolve(%{"!" => ["0"]}) == false
      assert JsonLogicXL.resolve(%{"!!" => ["0"]}) == true
      assert JsonLogicXL.resolve(%{"and" => ["0", true]}) == true
      assert JsonLogicXL.resolve(%{"or" => ["0", true]}) == "0"
    end

    test "if the conditional is logic, it gets evaluated" do
      logic = %{"if" => [%{">" => [2, 1]}, "apple", "banana"]}
      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{"if" => [%{">" => [1, 2]}, "apple", "banana"]}
      assert JsonLogicXL.resolve(logic) == "banana"
    end

    test "if the consequents are logic, they get evaluated" do
      logic = %{
        "if" => [
          true,
          %{"cat" => ["ap", "ple"]},
          %{"cat" => ["ba", "na", "na"]}
        ]
      }

      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{
        "if" => [
          false,
          %{"cat" => ["ap", "ple"]},
          %{"cat" => ["ba", "na", "na"]}
        ]
      }

      assert JsonLogicXL.resolve(logic) == "banana"
    end

    test "if / then / elseif / then cases" do
      logic = %{"if" => [true, "apple", true, "banana"]}
      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana"]}
      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{"if" => [false, "apple", true, "banana"]}
      assert JsonLogicXL.resolve(logic) == "banana"

      logic = %{"if" => [false, "apple", false, "banana"]}
      assert JsonLogicXL.resolve(logic) == nil

      logic = %{"if" => [true, "apple", true, "banana", "carrot"]}
      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana", "carrot"]}
      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{"if" => [false, "apple", true, "banana", "carrot"]}
      assert JsonLogicXL.resolve(logic) == "banana"

      logic = %{"if" => [false, "apple", false, "banana", "carrot"]}
      assert JsonLogicXL.resolve(logic) == "carrot"

      logic = %{"if" => [false, "apple", false, "banana", false, "carrot"]}
      assert JsonLogicXL.resolve(logic) == nil

      logic = %{"if" => [false, "apple", false, "banana", false, "carrot", "date"]}
      assert JsonLogicXL.resolve(logic) == "date"

      logic = %{"if" => [false, "apple", false, "banana", true, "carrot", "date"]}
      assert JsonLogicXL.resolve(logic) == "carrot"

      logic = %{"if" => [false, "apple", true, "banana", false, "carrot", "date"]}
      assert JsonLogicXL.resolve(logic) == "banana"

      logic = %{"if" => [false, "apple", true, "banana", true, "carrot", "date"]}
      assert JsonLogicXL.resolve(logic) == "banana"

      logic = %{"if" => [true, "apple", false, "banana", false, "carrot", "date"]}
      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana", true, "carrot", "date"]}
      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", true, "banana", false, "carrot", "date"]}
      assert JsonLogicXL.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", true, "banana", true, "carrot", "date"]}
      assert JsonLogicXL.resolve(logic) == "apple"
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
             } == JsonLogicXL.resolve(logic, data)
    end
  end

  describe "max" do
    test "returns max from vars" do
      logic = %{"max" => [%{"var" => "three"}, %{"var" => "one"}, %{"var" => "two"}]}
      data = %{"one" => 1, "two" => 2, "three" => 3}
      assert JsonLogicXL.resolve(logic, data) == 3
    end

    test "integers" do
      assert JsonLogicXL.resolve(%{"max" => [1, 2, 3]}) == 3
      assert JsonLogicXL.resolve(%{"max" => [1, 3, 3]}) == 3
      assert JsonLogicXL.resolve(%{"max" => [3, 2, 1]}) == 3
      assert JsonLogicXL.resolve(%{"max" => [3, 2]}) == 3
      assert JsonLogicXL.resolve(%{"max" => [1]}) == 1

      assert JsonLogicXL.resolve(%{"max" => ["1", "2", "3"]}) == "3"
      assert JsonLogicXL.resolve(%{"max" => ["1", "3", "3"]}) == "3"
      assert JsonLogicXL.resolve(%{"max" => ["3", "2", "1"]}) == "3"
      assert JsonLogicXL.resolve(%{"max" => ["3", "2"]}) == "3"
      assert JsonLogicXL.resolve(%{"max" => ["1"]}) == "1"

      assert JsonLogicXL.resolve(%{"max" => ["1", "2", 3]}) == 3
      assert JsonLogicXL.resolve(%{"max" => [3, "2", "1"]}) == 3
      assert JsonLogicXL.resolve(%{"max" => [3, "2"]}) == 3
      assert JsonLogicXL.resolve(%{"max" => [1]}) == 1
    end

    test "floats" do
      assert_approx_eq(3.1, JsonLogicXL.resolve(%{"max" => [1.1, 2.1, 3.1]}))
      assert_approx_eq(3.1, JsonLogicXL.resolve(%{"max" => [1.1, 3.1, 3.1]}))
      assert_approx_eq(3.1, JsonLogicXL.resolve(%{"max" => [3.1, 2.1, 1.1]}))
      assert_approx_eq(3.1, JsonLogicXL.resolve(%{"max" => [3.1, 2.1]}))
      assert_approx_eq(1.1, JsonLogicXL.resolve(%{"max" => [1.1]}))

      assert JsonLogicXL.resolve(%{"max" => ["1.1", "2.1", "3.1"]}) == "3.1"
      assert JsonLogicXL.resolve(%{"max" => ["1.1", "3.1", "3.1"]}) == "3.1"
      assert JsonLogicXL.resolve(%{"max" => ["3.1", "2.1", "1.1"]}) == "3.1"
      assert JsonLogicXL.resolve(%{"max" => ["3.", "2.1", "1.1"]}) == "3."
      assert JsonLogicXL.resolve(%{"max" => ["3.1", "2.1"]}) == "3.1"
      assert JsonLogicXL.resolve(%{"max" => ["1.1"]}) == "1.1"
      assert JsonLogicXL.resolve(%{"max" => ["1."]}) == "1."

      assert_approx_eq(3.1, JsonLogicXL.resolve(%{"max" => ["1.1", "2.1", 3.1]}))
      assert_approx_eq(3.1, JsonLogicXL.resolve(%{"max" => [3.1, "2.1", "1.1"]}))
      assert_approx_eq(3.1, JsonLogicXL.resolve(%{"max" => [3.1, "2.1"]}))
    end

    test "integer, floats, and decimals" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]
      threes = [3, 3.0, "3", "3.0", Decimal.new("3.0")]

      for one <- ones, two <- twos, three <- threes do
        assert_approx_eq(3, JsonLogicXL.resolve(%{"max" => [one, two, three]}))
      end
    end

    test "list with non numeric value" do
      assert JsonLogicXL.resolve(%{"max" => ["1", "2", "foo"]}) == nil
    end

    test "empty list" do
      assert JsonLogicXL.resolve(%{"max" => []}) == nil
    end
  end

  describe "min" do
    test "returns min from vars" do
      logic = %{"min" => [%{"var" => "three"}, %{"var" => "one"}, %{"var" => "two"}]}
      data = %{"one" => 1, "two" => 2, "three" => 3}

      assert JsonLogicXL.resolve(logic, data) == 1
    end

    test "integers" do
      assert JsonLogicXL.resolve(%{"min" => [1, 2, 3]}) == 1
      assert JsonLogicXL.resolve(%{"min" => [1, 3, 3]}) == 1
      assert JsonLogicXL.resolve(%{"min" => [3, 2, 1]}) == 1
      assert JsonLogicXL.resolve(%{"min" => [3, 2]}) == 2
      assert JsonLogicXL.resolve(%{"min" => [1]}) == 1

      assert JsonLogicXL.resolve(%{"min" => ["1", "2", "3"]}) == "1"
      assert JsonLogicXL.resolve(%{"min" => ["1", "3", "3"]}) == "1"
      assert JsonLogicXL.resolve(%{"min" => ["3", "2", "1"]}) == "1"
      assert JsonLogicXL.resolve(%{"min" => ["3", "2"]}) == "2"
      assert JsonLogicXL.resolve(%{"min" => ["1"]}) == "1"

      assert JsonLogicXL.resolve(%{"min" => [1, "2", "3"]}) == 1
      assert JsonLogicXL.resolve(%{"min" => [1, "3", "3"]}) == 1
      assert JsonLogicXL.resolve(%{"min" => ["3", "2", 1]}) == 1
      assert JsonLogicXL.resolve(%{"min" => ["3", 2]}) == 2
    end

    test "floats" do
      assert JsonLogicXL.resolve(%{"min" => [1.1, 2.1, 3.1]}) == 1.1
      assert JsonLogicXL.resolve(%{"min" => [1.1, 3.1, 3.1]}) == 1.1
      assert JsonLogicXL.resolve(%{"min" => [3.1, 2.1, 1.1]}) == 1.1
      assert JsonLogicXL.resolve(%{"min" => [3.1, 2.1]}) == 2.1
      assert JsonLogicXL.resolve(%{"min" => [1.1]}) == 1.1

      assert JsonLogicXL.resolve(%{"min" => ["1.1", "2.1", "3.1"]}) == "1.1"
      assert JsonLogicXL.resolve(%{"min" => ["1.1", "3.1", "3.1"]}) == "1.1"
      assert JsonLogicXL.resolve(%{"min" => ["3.1", "2.1", "1.1"]}) == "1.1"
      assert JsonLogicXL.resolve(%{"min" => ["3.1", "2.1"]}) == "2.1"
      assert JsonLogicXL.resolve(%{"min" => ["1.1"]}) == "1.1"

      assert JsonLogicXL.resolve(%{"min" => ["1.", "2.1", "3.1"]}) == "1."
      assert JsonLogicXL.resolve(%{"min" => ["1."]}) == "1."
    end

    test "integer, floats, and decimals" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]
      threes = [3, 3.0, "3", "3.0", Decimal.new("3.0")]

      for one <- ones, two <- twos, three <- threes do
        assert_approx_eq(1, JsonLogicXL.resolve(%{"min" => [one, two, three]}))
      end
    end

    test "list with non numeric value" do
      assert JsonLogicXL.resolve(%{"min" => ["1", "2", "foo"]}) == nil
    end

    test "empty list" do
      assert JsonLogicXL.resolve(%{"min" => []}) == nil
    end
  end

  describe "+" do
    test "returns added result of vars" do
      logic = %{"+" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogicXL.resolve(logic, data) == 7
    end

    test "handles empty list" do
      assert JsonLogicXL.resolve(%{"+" => []}) == 0
    end

    test "integer addition" do
      assert JsonLogicXL.resolve(%{"+" => [1, 2]}) == 3
      assert JsonLogicXL.resolve(%{"+" => [1, 2, 3]}) == 6
      assert JsonLogicXL.resolve(%{"+" => [1, 2, 3, 4]}) == 10
      assert JsonLogicXL.resolve(%{"+" => [1]}) == 1

      assert JsonLogicXL.resolve(%{"+" => [1, "2"]}) == 3
      assert JsonLogicXL.resolve(%{"+" => [1, 2, "3"]}) == 6
      assert JsonLogicXL.resolve(%{"+" => [1, "2", "3", 4]}) == 10
      assert JsonLogicXL.resolve(%{"+" => ["1"]}) == 1
      assert JsonLogicXL.resolve(%{"+" => ["1", 1]}) == 2
    end

    test "float addition" do
      assert_approx_eq(3.14, JsonLogicXL.resolve(%{"+" => ["3.14"]}))
      assert_approx_eq(3.14, JsonLogicXL.resolve(%{"+" => ["1.14", "2.0"]}))
    end

    test "float addition with mixed integer" do
      assert_approx_eq(3.14, JsonLogicXL.resolve(%{"+" => ["1.14", "2"]}))
      assert_approx_eq(3.14, JsonLogicXL.resolve(%{"+" => ["1.14", 2]}))
    end

    test "integer, float, and decimal addition" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]

      for left <- ones, right <- twos do
        assert_approx_eq(3, JsonLogicXL.resolve(%{"+" => [left, right]}))
      end
    end
  end

  describe "-" do
    test "returns subtraced result of vars" do
      logic = %{"-" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogicXL.resolve(logic, data) == 3
    end

    test "returns negative of a var" do
      assert JsonLogicXL.resolve(%{"-" => [%{"var" => "key"}]}, %{"key" => 2}) == -2
    end

    test "handles empty list" do
      assert JsonLogicXL.resolve(%{"-" => []}) == nil
    end

    test "floating point handles" do
      assert_approx_eq(-1.1, JsonLogicXL.resolve(%{"-" => [1.1, 2.2]}))
      assert_approx_eq(-1.2, JsonLogicXL.resolve(%{"-" => ["1.", 2.2]}))
      assert_approx_eq(7.8, JsonLogicXL.resolve(%{"-" => ["1.0e1", 2.2]}))
      assert_approx_eq(7.8, JsonLogicXL.resolve(%{"-" => ["1.0E1", 2.2]}))
      assert_approx_eq(7.8, JsonLogicXL.resolve(%{"-" => ["1.0E+1", 2.2]}))

      assert JsonLogicXL.resolve(%{"-" => ["1.0F+1", 2.2]}) == nil
    end

    test "specification" do
      assert JsonLogicXL.resolve(%{"-" => [1, 2]}) == -1
      assert JsonLogicXL.resolve(%{"-" => [3, 2]}) == 1
      assert JsonLogicXL.resolve(%{"-" => [3]}) == -3
      assert JsonLogicXL.resolve(%{"-" => [-3]}) == 3

      assert JsonLogicXL.resolve(%{"-" => ["1", "2"]}) == -1
      assert JsonLogicXL.resolve(%{"-" => ["3", "2"]}) == 1
      assert JsonLogicXL.resolve(%{"-" => ["3"]}) == -3
      assert JsonLogicXL.resolve(%{"-" => ["-3"]}) == 3

      assert JsonLogicXL.resolve(%{"-" => ["1", 2]}) == -1
      assert JsonLogicXL.resolve(%{"-" => ["3", 2]}) == 1

      assert JsonLogicXL.resolve(%{"-" => ["-1", 2]}) == -3
      assert JsonLogicXL.resolve(%{"-" => ["-3", 2]}) == -5

      assert JsonLogicXL.resolve(%{"-" => [1, "2"]}) == -1
      assert JsonLogicXL.resolve(%{"-" => [3, "2"]}) == 1
    end

    test "integer, float, and decimal subtraction" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]

      for left <- ones, right <- twos do
        assert_approx_eq(-1, JsonLogicXL.resolve(%{"-" => [left, right]}))
      end
    end
  end

  describe "*" do
    test "returns multiplied result of vars" do
      logic = %{"*" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogicXL.resolve(logic, data) == 10
    end

    test "strings being multipled" do
      assert JsonLogicXL.resolve(%{"*" => ["a", "b"]}) == nil
      assert JsonLogicXL.resolve(%{"*" => ["a"]}) == nil
    end

    test "integer multiplication" do
      assert JsonLogicXL.resolve(%{"*" => [1, 2]}) == 2
      assert JsonLogicXL.resolve(%{"*" => [1, 2, 3]}) == 6
      assert JsonLogicXL.resolve(%{"*" => [1, 2, 3, 4]}) == 24
      assert JsonLogicXL.resolve(%{"*" => [1]}) == 1

      assert JsonLogicXL.resolve(%{"*" => [1, "2"]}) == 2
      assert JsonLogicXL.resolve(%{"*" => [1, 2, "3"]}) == 6
      assert JsonLogicXL.resolve(%{"*" => [1, "2", "3", 4]}) == 24
      assert JsonLogicXL.resolve(%{"*" => ["1"]}) == 1
      assert JsonLogicXL.resolve(%{"*" => ["1", 1]}) == 1
    end

    test "float multiplication" do
      assert JsonLogicXL.resolve(%{"*" => [1.0, 2.0]}) == 2.0
      assert JsonLogicXL.resolve(%{"*" => [1.0, 2.0, 3.0]}) == 6.0
      assert JsonLogicXL.resolve(%{"*" => [1.0, 2.0, 3.0, 4.0]}) == 24.0
      assert JsonLogicXL.resolve(%{"*" => [1.0]}) == 1.0

      assert JsonLogicXL.resolve(%{"*" => [1.0, "2.0"]}) == 2.0
      assert JsonLogicXL.resolve(%{"*" => [1.0, 2.0, "3.0"]}) == 6.0
      assert JsonLogicXL.resolve(%{"*" => [1.0, "2.0", "3.0", 4.0]}) == 24.0
      assert JsonLogicXL.resolve(%{"*" => ["1.0"]}) == 1.0
      assert JsonLogicXL.resolve(%{"*" => ["1.0", 1.0]}) == 1.0
    end

    test "decimal multiplication" do
      twos = [2, 2.0, "2.0", Decimal.new("2.0")]

      for left <- twos, right <- twos do
        assert_approx_eq(
          Decimal.new("4.0"),
          JsonLogicXL.resolve(%{"*" => [left, right]})
        )
      end

      assert_approx_eq(
        Decimal.new("8.0"),
        JsonLogicXL.resolve(%{
          "*" => [
            Decimal.new("2.0"),
            Decimal.new("2.0"),
            Decimal.new("2.0")
          ]
        })
      )

      assert JsonLogicXL.resolve(%{"*" => ["1", "foo"]}) == nil
      assert JsonLogicXL.resolve(%{"*" => [1, "foo"]}) == nil
      assert JsonLogicXL.resolve(%{"*" => [1.0, "foo"]}) == nil
      assert JsonLogicXL.resolve(%{"*" => ["1.0", "foo"]}) == nil
      assert JsonLogicXL.resolve(%{"*" => ["foo", "1"]}) == nil
      assert JsonLogicXL.resolve(%{"*" => ["foo", 1]}) == nil
      assert JsonLogicXL.resolve(%{"*" => ["foo", 1.0]}) == nil
      assert JsonLogicXL.resolve(%{"*" => ["foo", "1.0"]}) == nil
    end
  end

  describe "/" do
    test "returns multiplied result of vars" do
      logic = %{"/" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogicXL.resolve(logic, data) == 2.5
    end

    test "integer division" do
      assert JsonLogicXL.resolve(%{"/" => [4, 2]}) == 2
      assert JsonLogicXL.resolve(%{"/" => [4, "2"]}) == 2
      assert JsonLogicXL.resolve(%{"/" => ["4", "2"]}) == 2
      assert JsonLogicXL.resolve(%{"/" => ["4", 2]}) == 2

      assert JsonLogicXL.resolve(%{"/" => [2, 4]}) == 0.5
      assert JsonLogicXL.resolve(%{"/" => ["2", 4]}) == 0.5
      assert JsonLogicXL.resolve(%{"/" => ["2", "4"]}) == 0.5
      assert JsonLogicXL.resolve(%{"/" => [2, "4"]}) == 0.5

      assert JsonLogicXL.resolve(%{"/" => ["1", 1]}) == 1
      assert JsonLogicXL.resolve(%{"/" => ["1", "1"]}) == 1
      assert JsonLogicXL.resolve(%{"/" => [1, "1"]}) == 1
    end

    test "float division" do
      assert JsonLogicXL.resolve(%{"/" => [2.0, 4.0]}) == 0.5
      assert JsonLogicXL.resolve(%{"/" => ["2.0", 4.0]}) == 0.5
      assert JsonLogicXL.resolve(%{"/" => ["2.0", "4.0"]}) == 0.5
      assert JsonLogicXL.resolve(%{"/" => [2.0, "4.0"]}) == 0.5
    end

    test "decimal division" do
      twos = [2, 2.0, "2.0", Decimal.new("2.0")]

      for left <- twos, right <- twos do
        assert_approx_eq(
          Decimal.new("1.0"),
          JsonLogicXL.resolve(%{"/" => [left, right]})
        )
      end

      assert JsonLogicXL.resolve(%{"/" => ["1", "foo"]}) == nil
      assert JsonLogicXL.resolve(%{"/" => [1, "foo"]}) == nil
      assert JsonLogicXL.resolve(%{"/" => [1.0, "foo"]}) == nil
      assert JsonLogicXL.resolve(%{"/" => ["1.0", "foo"]}) == nil
      assert JsonLogicXL.resolve(%{"/" => ["foo", "1"]}) == nil
      assert JsonLogicXL.resolve(%{"/" => ["foo", 1]}) == nil
      assert JsonLogicXL.resolve(%{"/" => ["foo", 1.0]}) == nil
      assert JsonLogicXL.resolve(%{"/" => ["foo", "1.0"]}) == nil
    end
  end

  describe "%" do
    test "integer, float, and decimal remainders" do
      ones = [1, 1.0, "1", "1.0", Decimal.new("1.0")]
      twos = [2, 2.0, "2", "2.0", Decimal.new("2.0")]

      for left <- ones, right <- twos do
        assert_approx_eq(1.0, JsonLogicXL.resolve(%{"%" => [left, right]}))
      end
    end
  end

  describe ">" do
    test "comparison with variables" do
      logic = %{">" => [%{"var" => "quantity"}, 25]}
      data = %{"quantity" => 1}
      assert JsonLogicXL.resolve(logic, data) == false

      logic = %{">" => [%{"var" => "quantity"}, 25]}
      data = %{"abc" => 1}
      assert JsonLogicXL.resolve(logic, data) == false
    end

    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        refute JsonLogicXL.resolve(%{">" => [left, right]})
      end

      for left <- twos, right <- ones do
        assert JsonLogicXL.resolve(%{">" => [left, right]})
      end

      for left <- ones, right <- twos do
        refute JsonLogicXL.resolve(%{">" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{">" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{">" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{">" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end
    end
  end

  describe ">=" do
    test "number compared to non numeric string" do
      refute JsonLogicXL.resolve(%{">=" => [1, "foo"]})
      refute JsonLogicXL.resolve(%{">=" => ["foo", 1]})
    end

    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        assert JsonLogicXL.resolve(%{">=" => [left, right]})
      end

      for left <- twos, right <- ones do
        assert JsonLogicXL.resolve(%{">=" => [left, right]})
      end

      for left <- ones, right <- twos do
        refute JsonLogicXL.resolve(%{">=" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{">=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{">=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{">=" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end
    end
  end

  describe "<" do
    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        refute JsonLogicXL.resolve(%{"<" => [left, right]})
      end

      for left <- twos, right <- ones do
        refute JsonLogicXL.resolve(%{"<" => [left, right]})
      end

      for left <- ones, right <- twos do
        assert JsonLogicXL.resolve(%{"<" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{"<" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{"<" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{"<" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end
    end
  end

  describe "<=" do
    test "integer, float, and decimal comparisons" do
      ones = [Decimal.new("1.0"), "1.0", "1", 1.0, 1]
      twos = [Decimal.new("2.0"), "2.0", "2", 2.0, 2]

      for left <- ones, right <- ones do
        assert JsonLogicXL.resolve(%{"<=" => [left, right]})
      end

      for left <- twos, right <- ones do
        refute JsonLogicXL.resolve(%{"<=" => [left, right]})
      end

      for left <- ones, right <- twos do
        assert JsonLogicXL.resolve(%{"<=" => [left, right]})
      end

      for left <- ones, right <- ones do
        logic = %{"<=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- twos, right <- ones do
        logic = %{"<=" => [%{"var" => "left"}, %{"var" => "right"}]}
        refute JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end

      for left <- ones, right <- twos do
        logic = %{"<=" => [%{"var" => "left"}, %{"var" => "right"}]}
        assert JsonLogicXL.resolve(logic, %{"left" => left, "right" => right})
      end
    end
  end

  describe "between" do
    test "exclusive" do
      assert JsonLogicXL.resolve(%{"<" => [1, 2, 3]})
      refute JsonLogicXL.resolve(%{"<" => [1, 1, 3]})
      refute JsonLogicXL.resolve(%{"<" => [1, 3, 3]})
      refute JsonLogicXL.resolve(%{"<" => [1, 4, 3]})
    end

    test "inclusive" do
      assert JsonLogicXL.resolve(%{"<=" => [1, 2, 3]})
      assert JsonLogicXL.resolve(%{"<=" => [1, 1, 3]})
      assert JsonLogicXL.resolve(%{"<=" => [1, 3, 3]})
      refute JsonLogicXL.resolve(%{"<=" => [1, 4, 3]})
    end
  end

  describe "map" do
    test "returns mapped integers" do
      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3, 4, 5]}

      assert JsonLogicXL.resolve(logic, data) == [2, 4, 6, 8, 10]
    end
  end

  describe "filter" do
    test "returns filtered integers" do
      logic = %{"filter" => [%{"var" => "integers"}, %{">" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3, 4, 5]}

      assert JsonLogicXL.resolve(logic, data) == [3, 4, 5]
    end

    test "returns filtered objects" do
      logic = %{"filter" => [%{"var" => "objects"}, %{"==" => [%{"var" => "uid"}, "A"]}]}
      data = %{"objects" => [%{"uid" => "A"}, %{"uid" => "B"}]}

      assert JsonLogicXL.resolve(logic, data) == [%{"uid" => "A"}]
    end
  end

  describe "reduce" do
    test "returns reduced integers" do
      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = %{"integers" => [1, 2, 3]}

      assert JsonLogicXL.resolve(logic, data) == 6
    end
  end

  describe "in" do
    test "returns true from vars" do
      logic = %{"in" => [%{"var" => "find"}, %{"var" => "from"}]}
      data = %{"find" => "sub", "from" => "substring"}

      assert JsonLogicXL.resolve(logic, data)
    end

    test "returns true from var list" do
      logic = %{"in" => [%{"var" => "find"}, %{"var" => "from"}]}

      data = %{
        "find" => "sub",
        "from" => ["sub", "string"]
      }

      assert JsonLogicXL.resolve(logic, data)
    end

    test "returns false from nil" do
      logic = %{"in" => [%{"var" => "find"}, %{"var" => "from"}]}

      data = %{
        "find" => "sub",
        "from" => nil
      }

      refute JsonLogicXL.resolve(logic, data)
    end

    test "returns false from var list" do
      logic = %{"in" => [%{"var" => "find"}, %{"var" => "from"}]}

      data = %{
        "find" => "sub",
        "from" => ["A", "B"]
      }

      refute JsonLogicXL.resolve(logic, data)
    end

    test "Bart is found in the list" do
      logic = %{"in" => ["Bart", ["Bart", "Homer", "Lisa", "Marge", "Maggie"]]}

      assert JsonLogicXL.resolve(logic)
    end

    test "Milhouse is not found in the list" do
      logic = %{
        "in" => ["Milhouse", ["Bart", "Homer", "Lisa", "Marge", "Maggie"]]
      }

      refute JsonLogicXL.resolve(logic)
    end

    test "finding a string in a string" do
      assert JsonLogicXL.resolve(%{"in" => ["Spring", "Springfield"]})
      refute JsonLogicXL.resolve(%{"in" => ["i", "team"]})
    end

    test "raises on non-enumerable list" do
      assert_raise(ArgumentError, fn ->
        logic = %{"in" => [%{"var" => "users.id"}, 1]}
        JsonLogicXL.resolve(logic, nil)
      end)
    end
  end

  describe "merge" do
    test "empty array" do
      assert JsonLogicXL.resolve(%{"merge" => []}) == []
    end

    test "flattens arrays" do
      assert JsonLogicXL.resolve(%{"merge" => [[1]]}) == [1]
      assert JsonLogicXL.resolve(%{"merge" => [[1], []]}) == [1]
      assert JsonLogicXL.resolve(%{"merge" => [[1], [2]]}) == [1, 2]
      assert JsonLogicXL.resolve(%{"merge" => [[1], [2], [3]]}) == [1, 2, 3]
      assert JsonLogicXL.resolve(%{"merge" => [[1, 2], [3]]}) == [1, 2, 3]
      assert JsonLogicXL.resolve(%{"merge" => [[1], [2, 3]]}) == [1, 2, 3]
      assert JsonLogicXL.resolve(%{"merge" => [[1, 2], [3, 4]]}) == [1, 2, 3, 4]
    end

    test "non array argumnets" do
      assert JsonLogicXL.resolve(%{"merge" => nil}) == [nil]
      assert JsonLogicXL.resolve(%{"merge" => 1}, nil) == [1]
      assert JsonLogicXL.resolve(%{"merge" => [1, 2]}) == [1, 2]
      assert JsonLogicXL.resolve(%{"merge" => [1, [2]]}) == [1, 2]
    end
  end

  describe "or" do
    test "specification" do
      assert JsonLogicXL.resolve(%{"or" => [true, true]}) == true
      assert JsonLogicXL.resolve(%{"or" => [false, true]}) == true
      assert JsonLogicXL.resolve(%{"or" => [true, false]}) == true
      assert JsonLogicXL.resolve(%{"or" => [false, false]}) == false

      assert JsonLogicXL.resolve(%{"or" => [true, nil]}) == true
      assert JsonLogicXL.resolve(%{"or" => [nil, nil]}) == nil
      assert JsonLogicXL.resolve(%{"or" => [nil, 1]}) == 1
      assert JsonLogicXL.resolve(%{"or" => [nil, 3]}) == 3
      assert JsonLogicXL.resolve(%{"or" => [1, 3]}) == 1
      assert JsonLogicXL.resolve(%{"or" => [true, 3]}) == true

      assert JsonLogicXL.resolve(%{"or" => [true, true, true]}) == true
      assert JsonLogicXL.resolve(%{"or" => [false, true, true]}) == true
      assert JsonLogicXL.resolve(%{"or" => [true, false, true]}) == true
      assert JsonLogicXL.resolve(%{"or" => [true, false, false]}) == true
      assert JsonLogicXL.resolve(%{"or" => [false, false, false]}) == false

      assert JsonLogicXL.resolve(%{"or" => [false, false, false, 1]}) == 1
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

      assert JsonLogicXL.resolve(logic) == true
    end

    test "specification" do
      assert JsonLogicXL.resolve(%{"and" => [true]}) == true
      assert JsonLogicXL.resolve(%{"and" => [false]}) == false

      assert JsonLogicXL.resolve(%{"and" => [true, true]})
      assert JsonLogicXL.resolve(%{"and" => [false, true]}) == false
      assert JsonLogicXL.resolve(%{"and" => [true, false]}) == false
      assert JsonLogicXL.resolve(%{"and" => [false, false]}) == false

      assert JsonLogicXL.resolve(%{"and" => [true, true, true]}) == true
      assert JsonLogicXL.resolve(%{"and" => [true, true, false]}) == false

      assert JsonLogicXL.resolve(%{"and" => [1, 3]}) == 3
      assert JsonLogicXL.resolve(%{"and" => [1, 2, 3]}) == 3
      assert JsonLogicXL.resolve(%{"and" => [1, false]}) == false
      assert JsonLogicXL.resolve(%{"and" => [false, 1]}) == false
    end
  end

  describe "?:" do
    test "specification" do
      assert JsonLogicXL.resolve(%{"?:" => [true, 1, 2]}) == 1
      assert JsonLogicXL.resolve(%{"?:" => [false, 1, 2]}) == 2
    end
  end

  describe "cat" do
    test "specification" do
      assert JsonLogicXL.resolve(%{"cat" => "ice"}) == "ice"
      assert JsonLogicXL.resolve(%{"cat" => ["ice"]}) == "ice"
      assert JsonLogicXL.resolve(%{"cat" => ["ice", "cream"]}) == "icecream"
      assert JsonLogicXL.resolve(%{"cat" => [1, 2]}) == "12"
      assert JsonLogicXL.resolve(%{"cat" => [1.0, 2.0]}) == "1.02.0"
      assert JsonLogicXL.resolve(%{"cat" => [1.1, 2.1]}) == "1.12.1"
      assert JsonLogicXL.resolve(%{"cat" => ["Robocop", 2]}) == "Robocop2"
      assert JsonLogicXL.resolve(%{"cat" => ["a", nil, "b"]}) == "ab"

      logic = %{"cat" => ["we all scream for ", "ice", "cream"]}
      assert JsonLogicXL.resolve(logic) == "we all scream for icecream"

      logic = %{"cat" => [%{"var" => "x"}, %{"var" => "y"}]}
      data = %{"x" => "foo", "y" => "bar"}
      assert JsonLogicXL.resolve(logic, data) == "foobar"
    end
  end

  describe "substr" do
    test "substr with only start" do
      assert JsonLogicXL.resolve(%{"substr" => ["jsonlogic", 4]}) == "logic"
      assert JsonLogicXL.resolve(%{"substr" => ["jsonlogic", -5]}) == "logic"
      assert JsonLogicXL.resolve(%{"substr" => ["jsonlögic", -5]}) == "lögic"
      assert JsonLogicXL.resolve(%{"substr" => ["jsönlögic", -5]}) == "lögic"

      assert JsonLogicXL.resolve(%{"substr" => ["", 4]}) == ""
      assert JsonLogicXL.resolve(%{"substr" => ["", -4]}) == ""

      assert JsonLogicXL.resolve(%{"substr" => ["Göödnight", 4]}) == "night"
      assert JsonLogicXL.resolve(%{"substr" => ["Göödnight", 2]}) == "ödnight"
    end

    test "substr with start and character count" do
      assert JsonLogicXL.resolve(%{"substr" => ["jsonlogic", 0, 1]}) == "j"
      assert JsonLogicXL.resolve(%{"substr" => ["jsonlogic", -1, 1]}) == "c"
      assert JsonLogicXL.resolve(%{"substr" => ["jsonlogic", 4, 5]}) == "logic"
      assert JsonLogicXL.resolve(%{"substr" => ["jsonlögic", 4, 5]}) == "lögic"
      assert JsonLogicXL.resolve(%{"substr" => ["jsönlögic", 4, 5]}) == "lögic"

      assert JsonLogicXL.resolve(%{"substr" => ["jsonlogic", -5, 5]}) == "logic"
      assert JsonLogicXL.resolve(%{"substr" => ["jsonlögic", -5, 5]}) == "lögic"
      assert JsonLogicXL.resolve(%{"substr" => ["jsönlögic", -5, 5]}) == "lögic"

      assert JsonLogicXL.resolve(%{"substr" => ["jsönlögic", -5, -2]}) == "lög"
      assert JsonLogicXL.resolve(%{"substr" => ["jsönlogic", -5, -2]}) == "log"

      assert JsonLogicXL.resolve(%{"substr" => ["jsonlogic", 1, -5]}) == "son"
      assert JsonLogicXL.resolve(%{"substr" => ["jsönlogic", 1, -5]}) == "sön"
    end
  end

  describe "arrays with logic" do
    test "using a variable" do
      logic = [1, %{"var" => "x"}, 3]
      data = %{"x" => 2}
      assert JsonLogicXL.resolve(logic, data) == [1, 2, 3]
    end

    test "using a variable in an if" do
      logic = %{"if" => [%{"var" => "x"}, %{"var" => "y"}, 99]}
      data = %{"x" => true, "y" => 2}
      assert JsonLogicXL.resolve(logic, data) == 2

      logic = %{"if" => [%{"var" => "x"}, [%{"var" => "y"}], [99]]}
      data = %{"x" => true, "y" => 2}
      assert JsonLogicXL.resolve(logic, data) == [2]

      logic = %{"if" => [%{"var" => "x"}, %{"var" => "y"}, 99]}
      data = %{"x" => false, "y" => 2}
      assert JsonLogicXL.resolve(logic, data) == 99

      logic = %{"if" => [%{"var" => "x"}, [%{"var" => "y"}], [99]]}
      data = %{"x" => false, "y" => 2}
      assert JsonLogicXL.resolve(logic, data) == [99]
    end

    test "compount test" do
      logic = %{"and" => [%{">" => [3, 1]}, true]}
      assert JsonLogicXL.resolve(logic, %{})

      logic = %{"and" => [%{">" => [3, 1]}, false]}
      refute JsonLogicXL.resolve(logic, %{})

      logic = %{"and" => [%{">" => [3, 1]}, %{"!" => true}]}
      refute JsonLogicXL.resolve(logic, %{})

      logic = %{"and" => [%{">" => [3, 1]}, %{"<" => [1, 3]}]}
      assert JsonLogicXL.resolve(logic, %{})

      logic = %{"?:" => [%{">" => [3, 1]}, "visible", "hidden"]}
      assert JsonLogicXL.resolve(logic, %{}) == "visible"
    end

    test "data driven" do
      logic = %{"var" => ["a"]}
      data = %{"a" => 1}
      assert JsonLogicXL.resolve(logic, data) == 1

      logic = %{"var" => ["b"]}
      data = %{"a" => 1}
      assert JsonLogicXL.resolve(logic, data) == nil

      logic = %{"var" => ["a"]}
      assert JsonLogicXL.resolve(logic, nil) == nil

      logic = %{"var" => "a"}
      data = %{"a" => 1}
      assert JsonLogicXL.resolve(logic, data) == 1

      logic = %{"var" => "b"}
      data = %{"a" => 1}
      assert JsonLogicXL.resolve(logic, data) == nil

      logic = %{"var" => "a"}
      assert JsonLogicXL.resolve(logic, nil) == nil

      logic = %{"var" => ["a", 1]}
      assert JsonLogicXL.resolve(logic, nil) == 1

      logic = %{"var" => ["b", 2]}
      data = %{"a" => 1}
      assert JsonLogicXL.resolve(logic, data) == 2

      logic = %{"var" => "a.b"}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogicXL.resolve(logic, data) == "c"

      logic = %{"var" => "a.q"}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogicXL.resolve(logic, data) == nil

      logic = %{"var" => ["a.q", 9]}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogicXL.resolve(logic, data) == 9

      logic = %{"var" => 1}
      data = ["apple", "banana"]
      assert JsonLogicXL.resolve(logic, data) == "banana"

      logic = %{"var" => "1"}
      data = ["apple", "banana"]
      assert JsonLogicXL.resolve(logic, data) == "banana"

      logic = %{"var" => "1.1"}
      data = ["apple", ["banana", "beer"]]
      assert JsonLogicXL.resolve(logic, data) == "beer"

      logic = %{
        "and" => [
          %{"<" => [%{"var" => "temp"}, 110]},
          %{"==" => [%{"var" => "pie.filling"}, "apple"]}
        ]
      }

      data = %{"pie" => %{"filling" => "apple"}, "temp" => 100}
      assert JsonLogicXL.resolve(logic, data)

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
      assert JsonLogicXL.resolve(logic, data) == "apple"

      logic = %{"in" => [%{"var" => "filling"}, ["apple", "cherry"]]}
      data = %{"filling" => "apple"}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"var" => "a.b.c"}
      assert JsonLogicXL.resolve(logic, nil) == nil

      logic = %{"var" => "a.b.c"}
      data = %{"a" => nil}
      assert JsonLogicXL.resolve(logic, data) == nil

      logic = %{"var" => "a.b.c"}
      data = %{"a" => %{"b" => nil}}
      assert JsonLogicXL.resolve(logic, data) == nil

      logic = %{"var" => ""}
      assert JsonLogicXL.resolve(logic, 1) == 1

      logic = %{"var" => nil}
      assert JsonLogicXL.resolve(logic, 1) == 1

      logic = %{"var" => []}
      assert JsonLogicXL.resolve(logic, 1) == 1
    end
  end

  describe "missing" do
    test "specification" do
      logic = %{"missing" => []}
      assert JsonLogicXL.resolve(logic, nil) == []

      logic = %{"missing" => ["a"]}
      assert JsonLogicXL.resolve(logic, nil) == ["a"]

      logic = %{"missing" => "a"}
      assert JsonLogicXL.resolve(logic, nil) == ["a"]

      logic = %{"missing" => "a"}
      data = %{"a" => "apple"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing" => ["a"]}
      data = %{"a" => "apple"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing" => ["a", "b"]}
      data = %{"a" => "apple"}
      assert JsonLogicXL.resolve(logic, data) == ["b"]

      logic = %{"missing" => ["a", "b"]}
      data = %{"b" => "banana"}
      assert JsonLogicXL.resolve(logic, data) == ["a"]

      logic = %{"missing" => ["a", "b"]}
      data = %{"a" => "apple", "b" => "banana"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing" => ["a", "b"]}
      assert JsonLogicXL.resolve(logic, %{}) == ["a", "b"]

      logic = %{"missing" => ["a", "b"]}
      assert JsonLogicXL.resolve(logic, nil) == ["a", "b"]

      logic = %{"missing" => ["a.b"]}
      assert JsonLogicXL.resolve(logic, nil) == ["a.b"]

      logic = %{"missing" => ["a.b"]}
      data = %{"a" => "apple"}
      assert JsonLogicXL.resolve(logic, data) == ["a.b"]

      logic = %{"missing" => ["a.b"]}
      data = %{"a" => %{"c" => "apple cake"}}
      assert JsonLogicXL.resolve(logic, data) == ["a.b"]

      logic = %{"missing" => ["a.b"]}
      data = %{"a" => %{"b" => "apple brownie"}}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing" => ["a.b", "a.c"]}
      data = %{"a" => %{"b" => "apple brownie"}}
      assert JsonLogicXL.resolve(logic, data) == ["a.c"]
    end
  end

  describe "missing_some" do
    test "specification" do
      logic = %{"missing_some" => [1, ["a", "b"]]}
      data = %{"a" => "apple"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing_some" => [1, ["a", "b"]]}
      data = %{"b" => "banana"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing_some" => [1, ["a", "b"]]}
      data = %{"a" => "apple", "b" => "banana"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing_some" => [1, ["a", "b"]]}
      data = %{"c" => "carrot"}
      assert JsonLogicXL.resolve(logic, data) == ["a", "b"]

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"a" => "apple", "b" => "banana"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"a" => "apple", "c" => "carrot"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"a" => "apple", "b" => "banana", "c" => "carrot"}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"a" => "apple", "d" => "durian"}
      assert JsonLogicXL.resolve(logic, data) == ["b", "c"]

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"d" => "durian", "e" => "eggplant"}
      assert JsonLogicXL.resolve(logic, data) == ["a", "b", "c"]
    end

    test "missing and If are friends, because empty arrays are falsey in JsonLogicXL" do
      logic = %{"if" => [%{"missing" => "a"}, "missed it", "found it"]}
      data = %{"a" => "apple"}
      assert JsonLogicXL.resolve(logic, data) == "found it"

      logic = %{"if" => [%{"missing" => "a"}, "missed it", "found it"]}
      data = %{"b" => "banana"}
      assert JsonLogicXL.resolve(logic, data) == "missed it"
    end

    test "missing, merge, and if are friends. VIN is always required, APR is only required if financing is true." do
      logic = %{
        "missing" => %{
          "merge" => ["vin", %{"if" => [%{"var" => "financing"}, ["apr"], []]}]
        }
      }

      data = %{"financing" => true}
      assert JsonLogicXL.resolve(logic, data) == ["vin", "apr"]

      logic = %{
        "missing" => %{
          "merge" => ["vin", %{"if" => [%{"var" => "financing"}, ["apr"], []]}]
        }
      }

      data = %{"financing" => false}
      assert JsonLogicXL.resolve(logic, data) == ["vin"]
    end
  end

  describe "collections" do
    test "filter, map, all, none, and some" do
      logic = %{"filter" => [%{"var" => "integers"}, true]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data) == [1, 2, 3]

      logic = %{"filter" => [%{"var" => "integers"}, false]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data) == []

      logic = %{"filter" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data) == [2, 3]

      logic = %{"filter" => [%{"var" => "integers"}, %{"%" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data) == [1, 3]

      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data) == [2, 4, 6]

      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
      assert JsonLogicXL.resolve(logic, nil) == []

      logic = %{"map" => [%{"var" => "desserts"}, %{"var" => "qty"}]}

      data = %{
        "desserts" => [
          %{"name" => "apple", "qty" => 1},
          %{"name" => "brownie", "qty" => 2},
          %{"name" => "cupcake", "qty" => 3}
        ]
      }

      assert JsonLogicXL.resolve(logic, data) == [1, 2, 3]

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogicXL.resolve(logic, data) == 10

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = nil
      assert JsonLogicXL.resolve(logic, data) == 0

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"*" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          1
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogicXL.resolve(logic, data) == 24

      logic = %{
        "reduce" => [
          %{"var" => "integers"},
          %{"*" => [%{"var" => "current"}, %{"var" => "accumulator"}]},
          0
        ]
      }

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogicXL.resolve(logic, data) == 0

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

      assert JsonLogicXL.resolve(logic, data) == 6

      logic = %{"all" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"all" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"all" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"all" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"all" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogicXL.resolve(logic, data)

      logic = %{"all" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogicXL.resolve(logic, data)

      logic = %{"all" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogicXL.resolve(logic, data)

      logic = %{"all" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"none" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"none" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"none" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"none" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"none" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogicXL.resolve(logic, data)

      logic = %{"none" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogicXL.resolve(logic, data)

      logic = %{"none" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogicXL.resolve(logic, data)

      logic = %{"none" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"some" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"some" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"some" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"some" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"some" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogicXL.resolve(logic, data)

      logic = %{"some" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogicXL.resolve(logic, data)

      logic = %{"some" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      refute JsonLogicXL.resolve(logic, data)

      logic = %{"some" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      refute JsonLogicXL.resolve(logic, data)
    end
  end

  describe "data does not contain the param specified in conditions" do
    test "cannot compare nil" do
      assert JsonLogicXL.resolve(%{"==" => [nil, nil]})
      assert JsonLogicXL.resolve(%{"<" => [nil, nil]})
      assert JsonLogicXL.resolve(%{">" => [nil, nil]})
      assert JsonLogicXL.resolve(%{"<=" => [nil, nil]})
      assert JsonLogicXL.resolve(%{">=" => [nil, nil]})

      logic = %{"<=" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{">=" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogicXL.resolve(logic, data)

      logic = %{"==" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogicXL.resolve(logic, data)

      refute JsonLogicXL.resolve(%{">" => [5, nil]})
      refute JsonLogicXL.resolve(%{">" => [nil, 5]})
      refute JsonLogicXL.resolve(%{">=" => [5, nil]})
      refute JsonLogicXL.resolve(%{">=" => [nil, 5]})

      refute JsonLogicXL.resolve(%{"<" => [5, nil]})
      refute JsonLogicXL.resolve(%{"<" => [nil, 5]})
      refute JsonLogicXL.resolve(%{"<=" => [5, nil]})
      refute JsonLogicXL.resolve(%{"<=" => [nil, 5]})

      logic = %{">" => [%{"var" => "quantity"}, 25]}
      data = %{"abc" => 1}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{"<" => [%{"var" => "quantity"}, 25]}
      data = %{"abc" => 1}
      refute JsonLogicXL.resolve(logic, data)

      logic = %{
        "and" => [
          %{">" => [%{"var" => "quantity"}, 25]},
          %{">" => [%{"var" => "durations"}, 23]}
        ]
      }

      data = %{"code" => "FUM", "occurence" => 15}
      refute JsonLogicXL.resolve(logic, data)

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
      assert JsonLogicXL.resolve(logic, data)

      data = %{"accessorial_service" => %{"code" => "FUM", "occurence" => 15}}
      refute JsonLogicXL.resolve(logic, data)
    end
  end

  describe "log" do
    test "that log is just a pass throug" do
      assert JsonLogicXL.resolve(%{"log" => [1]}) == [1]
    end
  end

  describe "unsupported operation" do
    test "raises exception" do
      assert_raise(ArgumentError, fn ->
        JsonLogicXL.resolve(%{"doesnotexist" => 1})
      end)
    end
  end

  describe "providing a json object" do
    test "passes through the results" do
      # This is the expected result according to
      #
      # https://JsonLogicXL.com/play.html
      logic = %{"-" => [1, 1], "+" => [1, 1]}
      assert logic == JsonLogicXL.resolve(logic)
    end
  end

  describe "xlookup" do
    test "matches a string value" do
      logic = %{
        "xlookup" => [
          %{"var" => "sam_tool_to_be_used"},
          [
            %{"key" => "ILMT", "value" => 1},
            %{"key" => "Flexera", "value" => 1.2},
            %{"key" => "ServiceNow", "value" => 1.15}
          ],
          "key",
          "value"
        ]
      }
      data = %{"sam_tool_to_be_used" => "Flexera"}
      assert JsonLogicXL.resolve(logic, data) == 1.2
    end
    test "gets table from data variable" do
      logic = %{
        "if" => [
          %{">" => [%{"var" => "num_seats__pub"}, 10]},
          "custom",
          %{
            "xlookup" => [
              %{"var" => "course_name__pub"},
              %{"var" => "tbl_trng_crss"},
              "Name",
              "Cost"
            ]
          }
        ]
      }
      data = %{
        "course_name__pub" => "CSAM",
        "num_seats__pub" => 8,
        "tbl_trng_crss" => [
          %{"Cost" => 30, "Name" => "CSAM", "Price" => 4000},
          %{"Cost" => 60, "Name" => "Scuba Diving", "Price" => 10000},
          %{"Cost" => 15, "Name" => "Pottery", "Price" => 1000}
        ]
      }
      assert JsonLogicXL.resolve(logic, data) == 30
    end
    test "no match found" do
      logic = %{
        "xlookup" => [
          "unknown",
          [
            %{"key" => "ILMT", "value" => 1},
          ],
          "key",
          "value"
        ]
      }
      assert JsonLogicXL.resolve(logic) == nil
    end
  end

  describe "ln natural log" do
    test "natural log of 9" do
      logic = %{
        "ln" => "9"
      }
      assert_approx_eq(JsonLogicXL.resolve(logic), 2.1972245)
    end
    test "natural log of 1" do
      logic = %{
        "ln" => 1
      }
      assert JsonLogicXL.resolve(logic) == 0
    end
  end

  describe "range_lookup" do
    test "happy path" do
      logic = %{
        "range_lookup" => [
          %{ "var" => "num_servers" },
          [
            %{ "min" => nil, "max" => 500, "result" => 45 },
            %{ "min" => 500, "max" => 1500, "result" => 75 },
            %{ "min" => 1500, "max" => 5000, "result" => 170 },
            %{ "min" => 5000, "max" => nil, "result" => "custom" }
          ],
          nil
        ]
      }
      data = %{"num_servers" => 70}
      assert JsonLogicXL.resolve(logic, data) == 45
    end
    test "default value when out of range" do
      logic = %{
        "range_lookup" => [12345,
          [
            %{ "min" => 0, "max" => 500, "result" => 45 },
            %{ "min" => 500, "max" => 1500, "result" => 75 },
          ],
          "unknown"
        ]
      }
      assert JsonLogicXL.resolve(logic) == "unknown"
    end
    test "no default val provided" do
      logic = %{
        "range_lookup" => [
          %{ "var" => "num_servers" },
          [
            %{ "min" => nil, "max" => 500, "result" => 45 },
            %{ "min" => 500, "max" => 1500, "result" => 75 },
            %{ "min" => 1500, "max" => 5000, "result" => 170 },
            %{ "min" => 5000, "max" => nil, "result" => "custom" }
          ]
        ]
      }
      data = %{"num_servers" => 70}
      assert JsonLogicXL.resolve(logic, data) == 45
    end
  end

  describe "eulers exponent 'exp'" do
    test "get eulers constant" do
      assert_approx_eq(JsonLogicXL.resolve(%{"exp" => 1}), 2.7182818284590)
    end

    test "eulers squared divided by 1.5" do
      assert_approx_eq(JsonLogicXL.resolve(%{"/" => [%{"exp" => 2}, 1.5]}), 4.9260373992871)
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
