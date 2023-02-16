defmodule JsonLogicTest do
  use ExUnit.Case, async: true

  describe "non rules" do
    test "nil" do
      assert JsonLogic.resolve(nil) == nil
    end

    test "empty map" do
      assert JsonLogic.resolve(%{}) == %{}
    end

    test "true" do
      assert JsonLogic.resolve(true) == true
    end

    test "false" do
      assert JsonLogic.resolve(false) == false
    end

    test "integer" do
      assert JsonLogic.resolve(17) == 17
    end

    test "float" do
      assert JsonLogic.resolve(3.14) == 3.14
    end

    test "string" do
      assert JsonLogic.resolve("apple") == "apple"
    end

    test "null" do
      assert JsonLogic.resolve(nil) == nil
    end

    test "list of strings" do
      assert JsonLogic.resolve(["a", "b"]) == ["a", "b"]
    end
  end

  describe "var" do
    test "returns from array inside hash" do
      logic = %{"var" => "key.1"}
      data = %{"key" => %{"1" => "a"}}
      assert JsonLogic.resolve(logic, data) == "a"

      logic = %{"var" => "key.1"}
      data = %{"key" => ~w{a b}}
      assert JsonLogic.resolve(logic, data) == "b"
    end
  end

  describe "==" do
    test "nested true" do
      logic = %{"==" => [true, %{"==" => [1, 1]}]}
      assert JsonLogic.resolve(logic) == true
    end

    test "nested false" do
      logic = %{"==" => [false, %{"==" => [0, 1]}]}
      assert JsonLogic.resolve(logic) == true
    end

    test "specification" do
      assert JsonLogic.resolve(%{"==" => [1, 1]}) == true
      assert JsonLogic.resolve(%{"==" => [1, "1"]}) == true
      assert JsonLogic.resolve(%{"==" => ["1", "1"]}) == true
      assert JsonLogic.resolve(%{"==" => ["1", 1]}) == true

      assert JsonLogic.resolve(%{"==" => [1, 2]}) == false
      assert JsonLogic.resolve(%{"==" => [1, "2"]}) == false
      assert JsonLogic.resolve(%{"==" => ["1", "2"]}) == false
      assert JsonLogic.resolve(%{"==" => ["1", 2]}) == false
    end
  end

  describe "!=" do
    test "nested true" do
      logic = %{"!=" => [false, %{"!=" => [0, 1]}]}
      assert JsonLogic.resolve(logic) == true
    end

    test "nested false" do
      logic = %{"!=" => [true, %{"!=" => [1, 1]}]}
      assert JsonLogic.resolve(logic) == true
    end

    test "specification" do
      assert JsonLogic.resolve(%{"!=" => [1, 1]}) == false
      assert JsonLogic.resolve(%{"!=" => [1, 2]}) == true
      assert JsonLogic.resolve(%{"!=" => [1, "1"]}) == false
      assert JsonLogic.resolve(%{"!=" => ["1", "1"]}) == false
      assert JsonLogic.resolve(%{"!=" => ["1", 1]}) == false
    end
  end

  describe "===" do
    test "nested true" do
      logic = %{"===" => [true, %{"===" => [1, 1]}]}
      assert JsonLogic.resolve(logic)
    end

    test "nested false" do
      logic = %{"===" => [false, %{"===" => [1, 1.0]}]}
      assert JsonLogic.resolve(logic) == true
    end

    test "specification" do
      assert JsonLogic.resolve(%{"===" => [1, 1]}) == true
      assert JsonLogic.resolve(%{"===" => [1, "1"]}) == false
      assert JsonLogic.resolve(%{"===" => ["1", "1"]}) == true
      assert JsonLogic.resolve(%{"===" => ["1", 1]}) == false

      assert JsonLogic.resolve(%{"===" => [1, 2]}) == false
      assert JsonLogic.resolve(%{"===" => [1, "2"]}) == false
      assert JsonLogic.resolve(%{"===" => ["1", "2"]}) == false
      assert JsonLogic.resolve(%{"===" => ["1", 2]}) == false
    end
  end

  describe "!==" do
    test "nested true" do
      logic = %{"!==" => [false, %{"!==" => [1, 1.0]}]}
      assert JsonLogic.resolve(logic) == true
    end

    test "nested false" do
      logic = %{"!==" => [true, %{"!==" => [1, 1]}]}
      assert JsonLogic.resolve(logic) == true
    end

    test "specification" do
      assert JsonLogic.resolve(%{"!==" => [1, 1]}) == false
      assert JsonLogic.resolve(%{"!==" => [1, 2]}) == true
      assert JsonLogic.resolve(%{"!==" => [1, "1"]}) == true
      assert JsonLogic.resolve(%{"!==" => ["1", "1"]}) == false
      assert JsonLogic.resolve(%{"!==" => ["1", 1]}) == true
    end
  end

  describe "!" do
    test "returns true with [false]" do
      assert JsonLogic.resolve(%{"!" => [false]}) == true
    end

    test "returns false with [true]" do
      assert JsonLogic.resolve(%{"!" => [true]}) == false
    end

    test "returns true with [false] from data" do
      logic = %{"!" => [%{"var" => "key"}]}
      data = %{"key" => false}
      assert JsonLogic.resolve(logic, data) == true
    end

    test "specification" do
      assert JsonLogic.resolve(%{"!" => [false]}) == true
      assert JsonLogic.resolve(%{"!" => false}) == true

      assert JsonLogic.resolve(%{"!" => nil}) == true

      assert JsonLogic.resolve(%{"!" => [true]}) == false
      assert JsonLogic.resolve(%{"!" => true}) == false

      assert JsonLogic.resolve(%{"!" => 0}) == true
      assert JsonLogic.resolve(%{"!" => 1}) == false
      assert JsonLogic.resolve(%{"!" => -1}) == false
      assert JsonLogic.resolve(%{"!" => 100}) == false
    end
  end

  describe "if" do
    test "returns var when true" do
      logic = %{"if" => [true, %{"var" => "key"}, "unexpected"]}
      data = %{"key" => "yes"}
      assert JsonLogic.resolve(logic, data) == "yes"
    end

    test "returns var when false" do
      logic = %{"if" => [false, "unexpected", %{"var" => "key"}]}
      data = %{"key" => "no"}
      assert JsonLogic.resolve(logic, data) == "no"
    end

    test "returns var with multiple branches" do
      logic = %{"if" => [false, "unexpected", false, "unexpected", %{"var" => "key"}]}
      data = %{"key" => "default"}

      assert JsonLogic.resolve(logic, data) == "default"
    end

    test "returns nil when else is not present" do
      assert JsonLogic.resolve(%{"if" => [false, "unexpected"]}) == nil
    end

    test "too few args" do
      assert JsonLogic.resolve(%{"if" => []}) == nil
      assert JsonLogic.resolve(%{"if" => [true]}) == true
      assert JsonLogic.resolve(%{"if" => [false]}) == false
      assert JsonLogic.resolve(%{"if" => ["apple"]}) == "apple"
    end

    test "simple if then else cases" do
      assert JsonLogic.resolve(%{"if" => [true, "apple"]}) == "apple"
      assert JsonLogic.resolve(%{"if" => [false, "apple"]}) == nil
      assert JsonLogic.resolve(%{"if" => [true, "apple", "banana"]}) == "apple"
      assert JsonLogic.resolve(%{"if" => [false, "apple", "banana"]}) == "banana"
    end

    test "empty arrays are falsey" do
      assert JsonLogic.resolve(%{"if" => [[], "apple", "banana"]}) == "banana"
      assert JsonLogic.resolve(%{"if" => [[1], "apple", "banana"]}) == "apple"
      assert JsonLogic.resolve(%{"if" => [[1, 2, 3, 4], "apple", "banana"]}) == "apple"
    end

    test "empty strings are falsey, all other strings are truthy" do
      assert JsonLogic.resolve(%{"if" => ["", "apple", "banana"]}) == "banana"
      assert JsonLogic.resolve(%{"if" => ["zucchini", "apple", "banana"]}) == "apple"
      assert JsonLogic.resolve(%{"if" => ["0", "apple", "banana"]}) == "apple"
    end

    test "you can cast a string to numeric with a unary + " do
      assert JsonLogic.resolve(%{"===" => [0, "0"]}) == false
      assert JsonLogic.resolve(%{"===" => [0, %{"+" => "0"}]}) == true
      assert JsonLogic.resolve(%{"if" => ["", "apple", "banana"]}) == "banana"
      assert JsonLogic.resolve(%{"if" => [%{"+" => "0"}, "apple", "banana"]}) == "banana"
      assert JsonLogic.resolve(%{"if" => [%{"+" => "1"}, "apple", "banana"]}) == "apple"
    end

    test "zero is falsy, all other numbers are truthy" do
      assert JsonLogic.resolve(%{"if" => [0, "apple", "banana"]}) == "banana"
      assert JsonLogic.resolve(%{"if" => [1, "apple", "banana"]}) == "apple"
      assert JsonLogic.resolve(%{"if" => [3.1416, "apple", "banana"]}) == "apple"
      assert JsonLogic.resolve(%{"if" => [-1, "apple", "banana"]}) == "apple"
    end

    test "truthy and falsy definitions matter in boolean operations" do
      assert JsonLogic.resolve(%{"!" => [[]]}) == true
      assert JsonLogic.resolve(%{"!!" => [[]]}) == false
      assert JsonLogic.resolve(%{"and" => [[], true]}) == []
      assert JsonLogic.resolve(%{"or" => [[], true]}) == true
      assert JsonLogic.resolve(%{"!" => [0]}) == true
      assert JsonLogic.resolve(%{"!!" => [0]}) == false
      assert JsonLogic.resolve(%{"and" => [0, true]}) == 0
      assert JsonLogic.resolve(%{"or" => [0, true]}) == true
      assert JsonLogic.resolve(%{"!" => [""]}) == true
      assert JsonLogic.resolve(%{"!!" => [""]}) == false
      assert JsonLogic.resolve(%{"and" => ["", true]}) == ""
      assert JsonLogic.resolve(%{"or" => ["", true]}) == true
      assert JsonLogic.resolve(%{"!" => ["0"]}) == false
      assert JsonLogic.resolve(%{"!!" => ["0"]}) == true
      assert JsonLogic.resolve(%{"and" => ["0", true]}) == true
      assert JsonLogic.resolve(%{"or" => ["0", true]}) == "0"
    end

    test "if the conditional is logic, it gets evaluated" do
      logic = %{"if" => [%{">" => [2, 1]}, "apple", "banana"]}
      assert JsonLogic.resolve(logic) == "apple"

      logic = %{"if" => [%{">" => [1, 2]}, "apple", "banana"]}
      assert JsonLogic.resolve(logic) == "banana"
    end

    test "if the consequents are logic, they get evaluated" do
      logic = %{
        "if" => [
          true,
          %{"cat" => ["ap", "ple"]},
          %{"cat" => ["ba", "na", "na"]}
        ]
      }

      assert JsonLogic.resolve(logic) == "apple"

      logic = %{
        "if" => [
          false,
          %{"cat" => ["ap", "ple"]},
          %{"cat" => ["ba", "na", "na"]}
        ]
      }

      assert JsonLogic.resolve(logic) == "banana"
    end

    test "if / then / elseif / then cases" do
      logic = %{"if" => [true, "apple", true, "banana"]}
      assert JsonLogic.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana"]}
      assert JsonLogic.resolve(logic) == "apple"

      logic = %{"if" => [false, "apple", true, "banana"]}
      assert JsonLogic.resolve(logic) == "banana"

      logic = %{"if" => [false, "apple", false, "banana"]}
      assert JsonLogic.resolve(logic) == nil

      logic = %{"if" => [true, "apple", true, "banana", "carrot"]}
      assert JsonLogic.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana", "carrot"]}
      assert JsonLogic.resolve(logic) == "apple"

      logic = %{"if" => [false, "apple", true, "banana", "carrot"]}
      assert JsonLogic.resolve(logic) == "banana"

      logic = %{"if" => [false, "apple", false, "banana", "carrot"]}
      assert JsonLogic.resolve(logic) == "carrot"

      logic = %{"if" => [false, "apple", false, "banana", false, "carrot"]}
      assert JsonLogic.resolve(logic) == nil

      logic = %{"if" => [false, "apple", false, "banana", false, "carrot", "date"]}
      assert JsonLogic.resolve(logic) == "date"

      logic = %{"if" => [false, "apple", false, "banana", true, "carrot", "date"]}
      assert JsonLogic.resolve(logic) == "carrot"

      logic = %{"if" => [false, "apple", true, "banana", false, "carrot", "date"]}
      assert JsonLogic.resolve(logic) == "banana"

      logic = %{"if" => [false, "apple", true, "banana", true, "carrot", "date"]}
      assert JsonLogic.resolve(logic) == "banana"

      logic = %{"if" => [true, "apple", false, "banana", false, "carrot", "date"]}
      assert JsonLogic.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", false, "banana", true, "carrot", "date"]}
      assert JsonLogic.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", true, "banana", false, "carrot", "date"]}
      assert JsonLogic.resolve(logic) == "apple"

      logic = %{"if" => [true, "apple", true, "banana", true, "carrot", "date"]}
      assert JsonLogic.resolve(logic) == "apple"
    end
  end

  describe "max" do
    test "returns max from vars" do
      logic = %{"max" => [%{"var" => "three"}, %{"var" => "one"}, %{"var" => "two"}]}
      data = %{"one" => 1, "two" => 2, "three" => 3}
      assert JsonLogic.resolve(logic, data) == 3
    end

    test "specification" do
      assert JsonLogic.resolve(%{"max" => [1, 2, 3]}) == 3
      assert JsonLogic.resolve(%{"max" => [1, 3, 3]}) == 3
      assert JsonLogic.resolve(%{"max" => [3, 2, 1]}) == 3
      assert JsonLogic.resolve(%{"max" => [3, 2]}) == 3
      assert JsonLogic.resolve(%{"max" => [1]}) == 1

      assert JsonLogic.resolve(%{"max" => ["1", "2", "3"]}) == "3"
      assert JsonLogic.resolve(%{"max" => ["1", "3", "3"]}) == "3"
      assert JsonLogic.resolve(%{"max" => ["3", "2", "1"]}) == "3"
      assert JsonLogic.resolve(%{"max" => ["3", "2"]}) == "3"
      assert JsonLogic.resolve(%{"max" => ["1"]}) == "1"

      assert JsonLogic.resolve(%{"max" => ["1", "2", 3]}) == 3
      assert JsonLogic.resolve(%{"max" => [3, "2", "1"]}) == 3
      assert JsonLogic.resolve(%{"max" => [3, "2"]}) == 3
      assert JsonLogic.resolve(%{"max" => [1]}) == 1

      assert JsonLogic.resolve(%{"max" => [1.1, 2.1, 3.1]}) == 3.1
      assert JsonLogic.resolve(%{"max" => [1.1, 3.1, 3.1]}) == 3.1
      assert JsonLogic.resolve(%{"max" => [3.1, 2.1, 1.1]}) == 3.1
      assert JsonLogic.resolve(%{"max" => [3.1, 2.1]}) == 3.1
      assert JsonLogic.resolve(%{"max" => [1.1]}) == 1.1

      assert JsonLogic.resolve(%{"max" => ["1.1", "2.1", "3.1"]}) == "3.1"
      assert JsonLogic.resolve(%{"max" => ["1.1", "3.1", "3.1"]}) == "3.1"
      assert JsonLogic.resolve(%{"max" => ["3.1", "2.1", "1.1"]}) == "3.1"
      assert JsonLogic.resolve(%{"max" => ["3.", "2.1", "1.1"]}) == nil
      assert JsonLogic.resolve(%{"max" => ["3.1", "2.1"]}) == "3.1"
      assert JsonLogic.resolve(%{"max" => ["1.1"]}) == "1.1"
      assert JsonLogic.resolve(%{"max" => ["1."]}) == nil

      assert JsonLogic.resolve(%{"max" => ["1.1", "2.1", 3.1]}) == 3.1
      assert JsonLogic.resolve(%{"max" => [3.1, "2.1", "1.1"]}) == 3.1
      assert JsonLogic.resolve(%{"max" => [3.1, "2.1"]}) == 3.1

      assert JsonLogic.resolve(%{"max" => ["1", "2", "foo"]}) == nil
      assert JsonLogic.resolve(%{"max" => []}) == nil
    end
  end

  describe "min" do
    test "returns min from vars" do
      logic = %{"min" => [%{"var" => "three"}, %{"var" => "one"}, %{"var" => "two"}]}
      data = %{"one" => 1, "two" => 2, "three" => 3}

      assert JsonLogic.resolve(logic, data) == 1
    end

    test "specification" do
      assert JsonLogic.resolve(%{"min" => [1, 2, 3]}) == 1
      assert JsonLogic.resolve(%{"min" => [1, 3, 3]}) == 1
      assert JsonLogic.resolve(%{"min" => [3, 2, 1]}) == 1
      assert JsonLogic.resolve(%{"min" => [3, 2]}) == 2
      assert JsonLogic.resolve(%{"min" => [1]}) == 1

      assert JsonLogic.resolve(%{"min" => ["1", "2", "3"]}) == "1"
      assert JsonLogic.resolve(%{"min" => ["1", "3", "3"]}) == "1"
      assert JsonLogic.resolve(%{"min" => ["3", "2", "1"]}) == "1"
      assert JsonLogic.resolve(%{"min" => ["3", "2"]}) == "2"
      assert JsonLogic.resolve(%{"min" => ["1"]}) == "1"

      assert JsonLogic.resolve(%{"min" => [1, "2", "3"]}) == 1
      assert JsonLogic.resolve(%{"min" => [1, "3", "3"]}) == 1
      assert JsonLogic.resolve(%{"min" => ["3", "2", 1]}) == 1
      assert JsonLogic.resolve(%{"min" => ["3", 2]}) == 2

      assert JsonLogic.resolve(%{"min" => [1.1, 2.1, 3.1]}) == 1.1
      assert JsonLogic.resolve(%{"min" => [1.1, 3.1, 3.1]}) == 1.1
      assert JsonLogic.resolve(%{"min" => [3.1, 2.1, 1.1]}) == 1.1
      assert JsonLogic.resolve(%{"min" => [3.1, 2.1]}) == 2.1
      assert JsonLogic.resolve(%{"min" => [1.1]}) == 1.1

      assert JsonLogic.resolve(%{"min" => ["1.1", "2.1", "3.1"]}) == "1.1"
      assert JsonLogic.resolve(%{"min" => ["1.1", "3.1", "3.1"]}) == "1.1"
      assert JsonLogic.resolve(%{"min" => ["3.1", "2.1", "1.1"]}) == "1.1"
      assert JsonLogic.resolve(%{"min" => ["3.1", "2.1"]}) == "2.1"
      assert JsonLogic.resolve(%{"min" => ["1.1"]}) == "1.1"

      assert JsonLogic.resolve(%{"min" => ["1.", "2.1", "3.1"]}) == nil
      assert JsonLogic.resolve(%{"min" => ["1."]}) == nil

      assert JsonLogic.resolve(%{"min" => ["1", "2", "foo"]}) == nil
      assert JsonLogic.resolve(%{"min" => []}) == nil
    end
  end

  describe "+" do
    test "returns added result of vars" do
      logic = %{"+" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogic.resolve(logic, data) == 7
    end

    test "handles empty list" do
      assert JsonLogic.resolve(%{"+" => []}) == 0
    end

    test "specification" do
      assert JsonLogic.resolve(%{"+" => [1, 2]}) == 3
      assert JsonLogic.resolve(%{"+" => [1, 2, 3]}) == 6
      assert JsonLogic.resolve(%{"+" => [1, 2, 3, 4]}) == 10
      assert JsonLogic.resolve(%{"+" => [1]}) == 1
      assert JsonLogic.resolve(%{"+" => ["3.14"]}) == 3.14

      assert JsonLogic.resolve(%{"+" => [1, "2"]}) == 3
      assert JsonLogic.resolve(%{"+" => [1, 2, "3"]}) == 6
      assert JsonLogic.resolve(%{"+" => [1, "2", "3", 4]}) == 10
      assert JsonLogic.resolve(%{"+" => ["1"]}) == 1
      assert JsonLogic.resolve(%{"+" => ["1", 1]}) == 2
    end
  end

  describe "-" do
    test "returns subtraced result of vars" do
      logic = %{"-" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogic.resolve(logic, data) == 3
    end

    test "returns negative of a var" do
      assert JsonLogic.resolve(%{"-" => [%{"var" => "key"}]}, %{"key" => 2}) == -2
    end

    test "handles empty list" do
      assert JsonLogic.resolve(%{"-" => []}) == nil
    end

    test "floating point handles" do
      assert JsonLogic.resolve(%{"-" => [1.1, 2.2]}) == -1.1
      assert JsonLogic.resolve(%{"-" => ["1.", 2.2]}) == -1.2000000000000002
      assert JsonLogic.resolve(%{"-" => ["1.0e1", 2.2]}) == 7.8
      assert JsonLogic.resolve(%{"-" => ["1.0E1", 2.2]}) == 7.8
      assert JsonLogic.resolve(%{"-" => ["1.0E+1", 2.2]}) == 7.8

      assert_raise(ArgumentError, fn ->
        JsonLogic.resolve(%{"-" => ["1.0F+1", 2.2]}) == 7.8
      end)
    end

    test "specification" do
      assert JsonLogic.resolve(%{"-" => [1, 2]}) == -1
      assert JsonLogic.resolve(%{"-" => [3, 2]}) == 1
      assert JsonLogic.resolve(%{"-" => [3]}) == -3
      assert JsonLogic.resolve(%{"-" => [-3]}) == 3

      assert JsonLogic.resolve(%{"-" => ["1", "2"]}) == -1
      assert JsonLogic.resolve(%{"-" => ["3", "2"]}) == 1
      assert JsonLogic.resolve(%{"-" => ["3"]}) == -3
      assert JsonLogic.resolve(%{"-" => ["-3"]}) == 3

      assert JsonLogic.resolve(%{"-" => ["1", 2]}) == -1
      assert JsonLogic.resolve(%{"-" => ["3", 2]}) == 1

      assert JsonLogic.resolve(%{"-" => ["-1", 2]}) == -3
      assert JsonLogic.resolve(%{"-" => ["-3", 2]}) == -5

      assert JsonLogic.resolve(%{"-" => [1, "2"]}) == -1
      assert JsonLogic.resolve(%{"-" => [3, "2"]}) == 1
    end
  end

  describe "*" do
    test "returns multiplied result of vars" do
      logic = %{"*" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogic.resolve(logic, data) == 10
    end

    test "specification" do
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
  end

  describe "/" do
    test "returns multiplied result of vars" do
      logic = %{"/" => [%{"var" => "left"}, %{"var" => "right"}]}
      data = %{"left" => 5, "right" => 2}
      assert JsonLogic.resolve(logic, data) == 2.5
    end

    test "specification" do
      assert JsonLogic.resolve(%{"/" => [4, 2]}) == 2
      assert JsonLogic.resolve(%{"/" => [4, "2"]}) == 2
      assert JsonLogic.resolve(%{"/" => ["4", "2"]}) == 2
      assert JsonLogic.resolve(%{"/" => ["4", 2]}) == 2

      assert JsonLogic.resolve(%{"/" => [2, 4]}) == 0.5
      assert JsonLogic.resolve(%{"/" => ["2", 4]}) == 0.5
      assert JsonLogic.resolve(%{"/" => ["2", "4"]}) == 0.5
      assert JsonLogic.resolve(%{"/" => [2, "4"]}) == 0.5

      assert JsonLogic.resolve(%{"/" => ["1", 1]}) == 1
      assert JsonLogic.resolve(%{"/" => ["1", "1"]}) == 1
      assert JsonLogic.resolve(%{"/" => [1, "1"]}) == 1
    end
  end

  describe "%" do
    test "specification" do
      assert JsonLogic.resolve(%{"%" => [1, 2]}) == 1
      assert JsonLogic.resolve(%{"%" => [2, 2]}) == 0
      assert JsonLogic.resolve(%{"%" => [3, 2]}) == 1
    end
  end

  describe ">" do
    test "specification" do
      assert JsonLogic.resolve(%{">" => [1, 1]}) == false
      assert JsonLogic.resolve(%{">" => [2, 1]}) == true
      assert JsonLogic.resolve(%{">" => [1, 2]}) == false

      assert JsonLogic.resolve(%{">" => ["1", 1]}) == false
      assert JsonLogic.resolve(%{">" => ["2", 1]}) == true
      assert JsonLogic.resolve(%{">" => ["1", 2]}) == false

      assert JsonLogic.resolve(%{">" => ["1", "1"]}) == false
      assert JsonLogic.resolve(%{">" => ["2", "1"]}) == true
      assert JsonLogic.resolve(%{">" => ["1", "2"]}) == false

      assert JsonLogic.resolve(%{">" => [1, "1"]}) == false
      assert JsonLogic.resolve(%{">" => [2, "1"]}) == true
      assert JsonLogic.resolve(%{">" => [1, "2"]}) == false

      assert JsonLogic.resolve(%{">" => [1.1, 1.1]}) == false
      assert JsonLogic.resolve(%{">" => [2.1, 1.1]}) == true
      assert JsonLogic.resolve(%{">" => [1.1, 2.1]}) == false

      assert JsonLogic.resolve(%{">" => ["1.1", 1.1]}) == false
      assert JsonLogic.resolve(%{">" => ["2.1", 1.1]}) == true
      assert JsonLogic.resolve(%{">" => ["1.1", 2.1]}) == false

      assert JsonLogic.resolve(%{">" => ["1.1", "1.1"]}) == false
      assert JsonLogic.resolve(%{">" => ["2.1", "1.1"]}) == true
      assert JsonLogic.resolve(%{">" => ["1.1", "2.1"]}) == false

      assert JsonLogic.resolve(%{">" => [1.1, "1.1"]}) == false
      assert JsonLogic.resolve(%{">" => [2.1, "1.1"]}) == true
      assert JsonLogic.resolve(%{">" => [1.1, "2.1"]}) == false
    end
  end

  describe ">=" do
    test "specification" do
      assert JsonLogic.resolve(%{">=" => [1, 1]}) == true
      assert JsonLogic.resolve(%{">=" => [2, 1]}) == true
      assert JsonLogic.resolve(%{">=" => [1, 2]}) == false

      assert JsonLogic.resolve(%{">=" => ["1", 1]}) == true
      assert JsonLogic.resolve(%{">=" => ["2", 1]}) == true
      assert JsonLogic.resolve(%{">=" => ["1", 2]}) == false

      assert JsonLogic.resolve(%{">=" => ["1", "1"]}) == true
      assert JsonLogic.resolve(%{">=" => ["2", "1"]}) == true
      assert JsonLogic.resolve(%{">=" => ["1", "2"]}) == false

      assert JsonLogic.resolve(%{">=" => [1, "1"]}) == true
      assert JsonLogic.resolve(%{">=" => [2, "1"]}) == true
      assert JsonLogic.resolve(%{">=" => [1, "2"]}) == false

      assert JsonLogic.resolve(%{">=" => [1.1, 1.1]}) == true
      assert JsonLogic.resolve(%{">=" => [2.1, 1.1]}) == true
      assert JsonLogic.resolve(%{">=" => [1.1, 2.1]}) == false

      assert JsonLogic.resolve(%{">=" => [1.1, "1.1"]}) == true
      assert JsonLogic.resolve(%{">=" => [2.1, "1.1"]}) == true
      assert JsonLogic.resolve(%{">=" => [1.1, "2.1"]}) == false

      assert JsonLogic.resolve(%{">=" => ["1.1", 1.1]}) == true
      assert JsonLogic.resolve(%{">=" => ["2.1", 1.1]}) == true
      assert JsonLogic.resolve(%{">=" => ["1.1", 2.1]}) == false

      assert JsonLogic.resolve(%{">=" => ["1.1", "1.1"]}) == true
      assert JsonLogic.resolve(%{">=" => ["2.1", "1.1"]}) == true
      assert JsonLogic.resolve(%{">=" => ["1.1", "2.1"]}) == false
    end
  end

  describe "<" do
    test "specification" do
      assert JsonLogic.resolve(%{"<" => [1, 1]}) == false
      assert JsonLogic.resolve(%{"<" => [2, 1]}) == false
      assert JsonLogic.resolve(%{"<" => [1, 2]}) == true

      assert JsonLogic.resolve(%{"<" => ["1", 1]}) == false
      assert JsonLogic.resolve(%{"<" => ["2", 1]}) == false
      assert JsonLogic.resolve(%{"<" => ["1", 2]}) == true

      assert JsonLogic.resolve(%{"<" => ["1", "1"]}) == false
      assert JsonLogic.resolve(%{"<" => ["2", "1"]}) == false
      assert JsonLogic.resolve(%{"<" => ["1", "2"]}) == true

      assert JsonLogic.resolve(%{"<" => [1, "1"]}) == false
      assert JsonLogic.resolve(%{"<" => [2, "1"]}) == false
      assert JsonLogic.resolve(%{"<" => [1, "2"]}) == true

      assert JsonLogic.resolve(%{"<" => [1.1, 1.1]}) == false
      assert JsonLogic.resolve(%{"<" => [2.1, 1.1]}) == false
      assert JsonLogic.resolve(%{"<" => [1.1, 2.1]}) == true

      assert JsonLogic.resolve(%{"<" => ["1.1", 1.1]}) == false
      assert JsonLogic.resolve(%{"<" => ["2.1", 1.1]}) == false
      assert JsonLogic.resolve(%{"<" => ["1.1", 2.1]}) == true

      assert JsonLogic.resolve(%{"<" => ["1.1", "1.1"]}) == false
      assert JsonLogic.resolve(%{"<" => ["2.1", "1.1"]}) == false
      assert JsonLogic.resolve(%{"<" => ["1.1", "2.1"]}) == true

      assert JsonLogic.resolve(%{"<" => [1.1, "1.1"]}) == false
      assert JsonLogic.resolve(%{"<" => [2.1, "1.1"]}) == false
      assert JsonLogic.resolve(%{"<" => [1.1, "2.1"]}) == true
    end
  end

  describe "<=" do
    test "specification" do
      assert JsonLogic.resolve(%{"<=" => [1, 1]}) == true
      assert JsonLogic.resolve(%{"<=" => [2, 1]}) == false
      assert JsonLogic.resolve(%{"<=" => [1, 2]}) == true

      assert JsonLogic.resolve(%{"<=" => ["1", 1]}) == true
      assert JsonLogic.resolve(%{"<=" => ["2", 1]}) == false
      assert JsonLogic.resolve(%{"<=" => ["1", 2]}) == true

      assert JsonLogic.resolve(%{"<=" => ["1", "1"]}) == true
      assert JsonLogic.resolve(%{"<=" => ["2", "1"]}) == false
      assert JsonLogic.resolve(%{"<=" => ["1", "2"]}) == true

      assert JsonLogic.resolve(%{"<=" => [1, "1"]}) == true
      assert JsonLogic.resolve(%{"<=" => [2, "1"]}) == false
      assert JsonLogic.resolve(%{"<=" => [1, "2"]}) == true

      assert JsonLogic.resolve(%{"<=" => [1.1, 1.1]}) == true
      assert JsonLogic.resolve(%{"<=" => [2.1, 1.1]}) == false
      assert JsonLogic.resolve(%{"<=" => [1.1, 2.1]}) == true

      assert JsonLogic.resolve(%{"<=" => [1.1, "1.1"]}) == true
      assert JsonLogic.resolve(%{"<=" => [2.1, "1.1"]}) == false
      assert JsonLogic.resolve(%{"<=" => [1.1, "2.1"]}) == true

      assert JsonLogic.resolve(%{"<=" => ["1.1", 1.1]}) == true
      assert JsonLogic.resolve(%{"<=" => ["2.1", 1.1]}) == false
      assert JsonLogic.resolve(%{"<=" => ["1.1", 2.1]}) == true

      assert JsonLogic.resolve(%{"<=" => ["1.1", "1.1"]}) == true
      assert JsonLogic.resolve(%{"<=" => ["2.1", "1.1"]}) == false
      assert JsonLogic.resolve(%{"<=" => ["1.1", "2.1"]}) == true
    end
  end

  describe "between" do
    test "exclusive" do
      assert JsonLogic.resolve(%{"<" => [1, 2, 3]}) == true
      assert JsonLogic.resolve(%{"<" => [1, 1, 3]}) == false
      assert JsonLogic.resolve(%{"<" => [1, 3, 3]}) == false
      assert JsonLogic.resolve(%{"<" => [1, 4, 3]}) == false
    end

    test "inclusive" do
      assert JsonLogic.resolve(%{"<=" => [1, 2, 3]}) == true
      assert JsonLogic.resolve(%{"<=" => [1, 1, 3]}) == true
      assert JsonLogic.resolve(%{"<=" => [1, 3, 3]}) == true
      assert JsonLogic.resolve(%{"<=" => [1, 4, 3]}) == false
    end
  end

  describe "map" do
    test "returns mapped integers" do
      logic = %{"map" => [%{"var" => "integers"}, %{"*" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3, 4, 5]}

      assert JsonLogic.resolve(logic, data) == [2, 4, 6, 8, 10]
    end
  end

  describe "filter" do
    test "returns filtered integers" do
      logic = %{"filter" => [%{"var" => "integers"}, %{">" => [%{"var" => ""}, 2]}]}
      data = %{"integers" => [1, 2, 3, 4, 5]}

      assert JsonLogic.resolve(logic, data) == [3, 4, 5]
    end

    test "returns filtered objects" do
      logic = %{"filter" => [%{"var" => "objects"}, %{"==" => [%{"var" => "uid"}, "A"]}]}
      data = %{"objects" => [%{"uid" => "A"}, %{"uid" => "B"}]}

      assert JsonLogic.resolve(logic, data) == [%{"uid" => "A"}]
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

      assert JsonLogic.resolve(logic, data) == 6
    end
  end

  describe "in" do
    test "returns true from vars" do
      logic = %{"in" => [%{"var" => "find"}, %{"var" => "from"}]}
      data = %{"find" => "sub", "from" => "substring"}

      assert JsonLogic.resolve(logic, data) == true
    end

    test "returns true from var list" do
      logic = %{"in" => [%{"var" => "find"}, %{"var" => "from"}]}

      data = %{
        "find" => "sub",
        "from" => ["sub", "string"]
      }

      assert JsonLogic.resolve(logic, data) == true
    end

    test "returns false from nil" do
      logic = %{"in" => [%{"var" => "find"}, %{"var" => "from"}]}

      data = %{
        "find" => "sub",
        "from" => nil
      }

      assert JsonLogic.resolve(logic, data) == false
    end

    test "returns false from var list" do
      logic = %{"in" => [%{"var" => "find"}, %{"var" => "from"}]}

      data = %{
        "find" => "sub",
        "from" => ["A", "B"]
      }

      assert JsonLogic.resolve(logic, data) == false
    end

    test "Bart is found in the list" do
      logic = %{"in" => ["Bart", ["Bart", "Homer", "Lisa", "Marge", "Maggie"]]}

      assert JsonLogic.resolve(logic) == true
    end

    test "Milhouse is not found in the list" do
      logic = %{
        "in" => ["Milhouse", ["Bart", "Homer", "Lisa", "Marge", "Maggie"]]
      }

      assert JsonLogic.resolve(logic) == false
    end

    test "finding a string in a string" do
      assert JsonLogic.resolve(%{"in" => ["Spring", "Springfield"]}) == true
      assert JsonLogic.resolve(%{"in" => ["i", "team"]}) == false
    end

    test "raises on non-enumerable list" do
      assert_raise(ArgumentError, fn ->
        logic = %{"in" => [%{"var" => "users.id"}, 1]}
        JsonLogic.resolve(logic, nil)
      end)
    end
  end

  describe "merge" do
    test "empty array" do
      assert JsonLogic.resolve(%{"merge" => []}) == []
    end

    test "flattens arrays" do
      assert JsonLogic.resolve(%{"merge" => [[1]]}) == [1]
      assert JsonLogic.resolve(%{"merge" => [[1], []]}) == [1]
      assert JsonLogic.resolve(%{"merge" => [[1], [2]]}) == [1, 2]
      assert JsonLogic.resolve(%{"merge" => [[1], [2], [3]]}) == [1, 2, 3]
      assert JsonLogic.resolve(%{"merge" => [[1, 2], [3]]}) == [1, 2, 3]
      assert JsonLogic.resolve(%{"merge" => [[1], [2, 3]]}) == [1, 2, 3]
      assert JsonLogic.resolve(%{"merge" => [[1, 2], [3, 4]]}) == [1, 2, 3, 4]
    end

    test "non array argumnets" do
      assert JsonLogic.resolve(%{"merge" => nil}) == [nil]
      assert JsonLogic.resolve(%{"merge" => 1}, nil) == [1]
      assert JsonLogic.resolve(%{"merge" => [1, 2]}) == [1, 2]
      assert JsonLogic.resolve(%{"merge" => [1, [2]]}) == [1, 2]
    end
  end

  describe "or" do
    test "specification" do
      assert JsonLogic.resolve(%{"or" => [true, true]}) == true
      assert JsonLogic.resolve(%{"or" => [false, true]}) == true
      assert JsonLogic.resolve(%{"or" => [true, false]}) == true
      assert JsonLogic.resolve(%{"or" => [false, false]}) == false

      assert JsonLogic.resolve(%{"or" => [true, nil]}) == true
      assert JsonLogic.resolve(%{"or" => [nil, nil]}) == nil
      assert JsonLogic.resolve(%{"or" => [nil, 1]}) == 1
      assert JsonLogic.resolve(%{"or" => [nil, 3]}) == 3
      assert JsonLogic.resolve(%{"or" => [1, 3]}) == 1
      assert JsonLogic.resolve(%{"or" => [true, 3]}) == true

      assert JsonLogic.resolve(%{"or" => [true, true, true]}) == true
      assert JsonLogic.resolve(%{"or" => [false, true, true]}) == true
      assert JsonLogic.resolve(%{"or" => [true, false, true]}) == true
      assert JsonLogic.resolve(%{"or" => [true, false, false]}) == true
      assert JsonLogic.resolve(%{"or" => [false, false, false]}) == false

      assert JsonLogic.resolve(%{"or" => [false, false, false, 1]}) == 1
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

      assert JsonLogic.resolve(logic) == true
    end

    test "specification" do
      assert JsonLogic.resolve(%{"and" => [true]}) == true
      assert JsonLogic.resolve(%{"and" => [false]}) == false

      assert JsonLogic.resolve(%{"and" => [true, true]})
      assert JsonLogic.resolve(%{"and" => [false, true]}) == false
      assert JsonLogic.resolve(%{"and" => [true, false]}) == false
      assert JsonLogic.resolve(%{"and" => [false, false]}) == false

      assert JsonLogic.resolve(%{"and" => [true, true, true]}) == true
      assert JsonLogic.resolve(%{"and" => [true, true, false]}) == false

      assert JsonLogic.resolve(%{"and" => [1, 3]}) == 3
      assert JsonLogic.resolve(%{"and" => [1, 2, 3]}) == 3
      assert JsonLogic.resolve(%{"and" => [1, false]}) == false
      assert JsonLogic.resolve(%{"and" => [false, 1]}) == false
    end
  end

  describe "?:" do
    test "specification" do
      assert JsonLogic.resolve(%{"?:" => [true, 1, 2]}) == 1
      assert JsonLogic.resolve(%{"?:" => [false, 1, 2]}) == 2
    end
  end

  describe "cat" do
    test "specification" do
      assert JsonLogic.resolve(%{"cat" => "ice"}) == "ice"
      assert JsonLogic.resolve(%{"cat" => ["ice"]}) == "ice"
      assert JsonLogic.resolve(%{"cat" => ["ice", "cream"]}) == "icecream"
      assert JsonLogic.resolve(%{"cat" => [1, 2]}) == "12"
      assert JsonLogic.resolve(%{"cat" => [1.0, 2.0]}) == "1.02.0"
      assert JsonLogic.resolve(%{"cat" => [1.1, 2.1]}) == "1.12.1"
      assert JsonLogic.resolve(%{"cat" => ["Robocop", 2]}) == "Robocop2"

      logic = %{"cat" => ["we all scream for ", "ice", "cream"]}
      assert JsonLogic.resolve(logic) == "we all scream for icecream"

      logic = %{"cat" => [%{"var" => "x"}, %{"var" => "y"}]}
      data = %{"x" => "foo", "y" => "bar"}
      assert JsonLogic.resolve(logic, data) == "foobar"
    end
  end

  describe "substr" do
    test "substr with only start" do
      assert JsonLogic.resolve(%{"substr" => ["jsonlogic", 4]}) == "logic"
      assert JsonLogic.resolve(%{"substr" => ["jsonlogic", -5]}) == "logic"
      assert JsonLogic.resolve(%{"substr" => ["jsonlögic", -5]}) == "lögic"
      assert JsonLogic.resolve(%{"substr" => ["jsönlögic", -5]}) == "lögic"

      assert JsonLogic.resolve(%{"substr" => ["", 4]}) == ""
      assert JsonLogic.resolve(%{"substr" => ["", -4]}) == ""

      assert JsonLogic.resolve(%{"substr" => ["Göödnight", 4]}) == "night"
      assert JsonLogic.resolve(%{"substr" => ["Göödnight", 2]}) == "ödnight"
    end

    test "substr with start and character count" do
      assert JsonLogic.resolve(%{"substr" => ["jsonlogic", 0, 1]}) == "j"
      assert JsonLogic.resolve(%{"substr" => ["jsonlogic", -1, 1]}) == "c"
      assert JsonLogic.resolve(%{"substr" => ["jsonlogic", 4, 5]}) == "logic"
      assert JsonLogic.resolve(%{"substr" => ["jsonlögic", 4, 5]}) == "lögic"
      assert JsonLogic.resolve(%{"substr" => ["jsönlögic", 4, 5]}) == "lögic"

      assert JsonLogic.resolve(%{"substr" => ["jsonlogic", -5, 5]}) == "logic"
      assert JsonLogic.resolve(%{"substr" => ["jsonlögic", -5, 5]}) == "lögic"
      assert JsonLogic.resolve(%{"substr" => ["jsönlögic", -5, 5]}) == "lögic"

      assert JsonLogic.resolve(%{"substr" => ["jsönlögic", -5, -2]}) == "lög"
      assert JsonLogic.resolve(%{"substr" => ["jsönlogic", -5, -2]}) == "log"

      assert JsonLogic.resolve(%{"substr" => ["jsonlogic", 1, -5]}) == "son"
      assert JsonLogic.resolve(%{"substr" => ["jsönlogic", 1, -5]}) == "sön"
    end
  end

  describe "arrays with logic" do
    test "using a variable" do
      logic = [1, %{"var" => "x"}, 3]
      data = %{"x" => 2}
      assert JsonLogic.resolve(logic, data) == [1, 2, 3]
    end

    test "using a variable in an if" do
      logic = %{"if" => [%{"var" => "x"}, %{"var" => "y"}, 99]}
      data = %{"x" => true, "y" => 2}
      assert JsonLogic.resolve(logic, data) == 2

      logic = %{"if" => [%{"var" => "x"}, [%{"var" => "y"}], [99]]}
      data = %{"x" => true, "y" => 2}
      assert JsonLogic.resolve(logic, data) == [2]

      logic = %{"if" => [%{"var" => "x"}, %{"var" => "y"}, 99]}
      data = %{"x" => false, "y" => 2}
      assert JsonLogic.resolve(logic, data) == 99

      logic = %{"if" => [%{"var" => "x"}, [%{"var" => "y"}], [99]]}
      data = %{"x" => false, "y" => 2}
      assert JsonLogic.resolve(logic, data) == [99]
    end

    test "compount test" do
      logic = %{"and" => [%{">" => [3, 1]}, true]}
      assert JsonLogic.resolve(logic, %{}) == true

      logic = %{"and" => [%{">" => [3, 1]}, false]}
      assert JsonLogic.resolve(logic, %{}) == false

      logic = %{"and" => [%{">" => [3, 1]}, %{"!" => true}]}
      assert JsonLogic.resolve(logic, %{}) == false

      logic = %{"and" => [%{">" => [3, 1]}, %{"<" => [1, 3]}]}
      assert JsonLogic.resolve(logic, %{}) == true

      logic = %{"?:" => [%{">" => [3, 1]}, "visible", "hidden"]}
      assert JsonLogic.resolve(logic, %{}) == "visible"
    end

    test "data driven" do
      logic = %{"var" => ["a"]}
      data = %{"a" => 1}
      assert JsonLogic.resolve(logic, data) == 1

      logic = %{"var" => ["b"]}
      data = %{"a" => 1}
      assert JsonLogic.resolve(logic, data) == nil

      logic = %{"var" => ["a"]}
      assert JsonLogic.resolve(logic, nil) == nil

      logic = %{"var" => "a"}
      data = %{"a" => 1}
      assert JsonLogic.resolve(logic, data) == 1

      logic = %{"var" => "b"}
      data = %{"a" => 1}
      assert JsonLogic.resolve(logic, data) == nil

      logic = %{"var" => "a"}
      assert JsonLogic.resolve(logic, nil) == nil

      logic = %{"var" => ["a", 1]}
      assert JsonLogic.resolve(logic, nil) == 1

      logic = %{"var" => ["b", 2]}
      data = %{"a" => 1}
      assert JsonLogic.resolve(logic, data) == 2

      logic = %{"var" => "a.b"}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogic.resolve(logic, data) == "c"

      logic = %{"var" => "a.q"}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogic.resolve(logic, data) == nil

      logic = %{"var" => ["a.q", 9]}
      data = %{"a" => %{"b" => "c"}}
      assert JsonLogic.resolve(logic, data) == 9

      logic = %{"var" => 1}
      data = ["apple", "banana"]
      assert JsonLogic.resolve(logic, data) == "banana"

      logic = %{"var" => "1"}
      data = ["apple", "banana"]
      assert JsonLogic.resolve(logic, data) == "banana"

      logic = %{"var" => "1.1"}
      data = ["apple", ["banana", "beer"]]
      assert JsonLogic.resolve(logic, data) == "beer"

      logic = %{
        "and" => [
          %{"<" => [%{"var" => "temp"}, 110]},
          %{"==" => [%{"var" => "pie.filling"}, "apple"]}
        ]
      }

      data = %{"pie" => %{"filling" => "apple"}, "temp" => 100}
      assert JsonLogic.resolve(logic, data) == true

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
      assert JsonLogic.resolve(logic, data) == "apple"

      logic = %{"in" => [%{"var" => "filling"}, ["apple", "cherry"]]}
      data = %{"filling" => "apple"}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{"var" => "a.b.c"}
      assert JsonLogic.resolve(logic, nil) == nil

      logic = %{"var" => "a.b.c"}
      data = %{"a" => nil}
      assert JsonLogic.resolve(logic, data) == nil

      logic = %{"var" => "a.b.c"}
      data = %{"a" => %{"b" => nil}}
      assert JsonLogic.resolve(logic, data) == nil

      logic = %{"var" => ""}
      assert JsonLogic.resolve(logic, 1) == 1

      logic = %{"var" => nil}
      assert JsonLogic.resolve(logic, 1) == 1

      logic = %{"var" => []}
      assert JsonLogic.resolve(logic, 1) == 1
    end
  end

  describe "missing" do
    test "specification" do
      logic = %{"missing" => []}
      assert JsonLogic.resolve(logic, nil) == []

      logic = %{"missing" => ["a"]}
      assert JsonLogic.resolve(logic, nil) == ["a"]

      logic = %{"missing" => "a"}
      assert JsonLogic.resolve(logic, nil) == ["a"]

      logic = %{"missing" => "a"}
      data = %{"a" => "apple"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing" => ["a"]}
      data = %{"a" => "apple"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing" => ["a", "b"]}
      data = %{"a" => "apple"}
      assert JsonLogic.resolve(logic, data) == ["b"]

      logic = %{"missing" => ["a", "b"]}
      data = %{"b" => "banana"}
      assert JsonLogic.resolve(logic, data) == ["a"]

      logic = %{"missing" => ["a", "b"]}
      data = %{"a" => "apple", "b" => "banana"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing" => ["a", "b"]}
      assert JsonLogic.resolve(logic, %{}) == ["a", "b"]

      logic = %{"missing" => ["a", "b"]}
      assert JsonLogic.resolve(logic, nil) == ["a", "b"]

      logic = %{"missing" => ["a.b"]}
      assert JsonLogic.resolve(logic, nil) == ["a.b"]

      logic = %{"missing" => ["a.b"]}
      data = %{"a" => "apple"}
      assert JsonLogic.resolve(logic, data) == ["a.b"]

      logic = %{"missing" => ["a.b"]}
      data = %{"a" => %{"c" => "apple cake"}}
      assert JsonLogic.resolve(logic, data) == ["a.b"]

      logic = %{"missing" => ["a.b"]}
      data = %{"a" => %{"b" => "apple brownie"}}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing" => ["a.b", "a.c"]}
      data = %{"a" => %{"b" => "apple brownie"}}
      assert JsonLogic.resolve(logic, data) == ["a.c"]
    end
  end

  describe "missing_some" do
    test "specification" do
      logic = %{"missing_some" => [1, ["a", "b"]]}
      data = %{"a" => "apple"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing_some" => [1, ["a", "b"]]}
      data = %{"b" => "banana"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing_some" => [1, ["a", "b"]]}
      data = %{"a" => "apple", "b" => "banana"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing_some" => [1, ["a", "b"]]}
      data = %{"c" => "carrot"}
      assert JsonLogic.resolve(logic, data) == ["a", "b"]

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"a" => "apple", "b" => "banana"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"a" => "apple", "c" => "carrot"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"a" => "apple", "b" => "banana", "c" => "carrot"}
      assert JsonLogic.resolve(logic, data) == []

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"a" => "apple", "d" => "durian"}
      assert JsonLogic.resolve(logic, data) == ["b", "c"]

      logic = %{"missing_some" => [2, ["a", "b", "c"]]}
      data = %{"d" => "durian", "e" => "eggplant"}
      assert JsonLogic.resolve(logic, data) == ["a", "b", "c"]
    end

    test "missing and If are friends, because empty arrays are falsey in JsonLogic" do
      logic = %{"if" => [%{"missing" => "a"}, "missed it", "found it"]}
      data = %{"a" => "apple"}
      assert JsonLogic.resolve(logic, data) == "found it"

      logic = %{"if" => [%{"missing" => "a"}, "missed it", "found it"]}
      data = %{"b" => "banana"}
      assert JsonLogic.resolve(logic, data) == "missed it"
    end

    test "missing, merge, and if are friends. VIN is always required, APR is only required if financing is true." do
      logic = %{
        "missing" => %{
          "merge" => ["vin", %{"if" => [%{"var" => "financing"}, ["apr"], []]}]
        }
      }

      data = %{"financing" => true}
      assert JsonLogic.resolve(logic, data) == ["vin", "apr"]

      logic = %{
        "missing" => %{
          "merge" => ["vin", %{"if" => [%{"var" => "financing"}, ["apr"], []]}]
        }
      }

      data = %{"financing" => false}
      assert JsonLogic.resolve(logic, data) == ["vin"]
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

      data = %{"integers" => [1, 2, 3, 4]}
      assert JsonLogic.resolve(logic, data) == 0

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

      assert JsonLogic.resolve(logic, data) == 6

      logic = %{"all" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{"all" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"all" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"all" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"all" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == true

      logic = %{"all" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == false

      logic = %{"all" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == false

      logic = %{"all" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"none" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"none" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"none" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{"none" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{"none" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == false

      logic = %{"none" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == false

      logic = %{"none" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == true

      logic = %{"none" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{"some" => [%{"var" => "integers"}, %{">=" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{"some" => [%{"var" => "integers"}, %{"==" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{"some" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => [1, 2, 3]}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"some" => [%{"var" => "integers"}, %{"<" => [%{"var" => ""}, 1]}]}
      data = %{"integers" => []}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"some" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == true

      logic = %{"some" => [%{"var" => "items"}, %{">" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == true

      logic = %{"some" => [%{"var" => "items"}, %{"<" => [%{"var" => "qty"}, 1]}]}

      data = %{
        "items" => [
          %{"qty" => 1, "sku" => "apple"},
          %{"qty" => 2, "sku" => "banana"}
        ]
      }

      assert JsonLogic.resolve(logic, data) == false

      logic = %{"some" => [%{"var" => "items"}, %{">=" => [%{"var" => "qty"}, 1]}]}
      data = %{"items" => []}
      assert JsonLogic.resolve(logic, data) == false
    end
  end

  describe "data does not contain the param specified in conditions" do
    test "cannot compare nil" do
      assert JsonLogic.resolve(%{"==" => [nil, nil]}) == true
      assert JsonLogic.resolve(%{"<" => [nil, nil]}) == true
      assert JsonLogic.resolve(%{">" => [nil, nil]}) == true
      assert JsonLogic.resolve(%{"<=" => [nil, nil]}) == true
      assert JsonLogic.resolve(%{">=" => [nil, nil]}) == true

      logic = %{"<=" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{">=" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogic.resolve(logic, data) == true

      logic = %{"==" => [%{"var" => "optional"}, nil]}
      data = %{"optional" => nil}
      assert JsonLogic.resolve(logic, data) == true

      assert JsonLogic.resolve(%{">" => [5, nil]}) == false
      assert JsonLogic.resolve(%{">" => [nil, 5]}) == false
      assert JsonLogic.resolve(%{">=" => [5, nil]}) == false
      assert JsonLogic.resolve(%{">=" => [nil, 5]}) == false

      assert JsonLogic.resolve(%{"<" => [5, nil]}) == false
      assert JsonLogic.resolve(%{"<" => [nil, 5]}) == false
      assert JsonLogic.resolve(%{"<=" => [5, nil]}) == false
      assert JsonLogic.resolve(%{"<=" => [nil, 5]}) == false

      logic = %{">" => [%{"var" => "quantity"}, 25]}
      data = %{"abc" => 1}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{"<" => [%{"var" => "quantity"}, 25]}
      data = %{"abc" => 1}
      assert JsonLogic.resolve(logic, data) == false

      logic = %{
        "and" => [
          %{">" => [%{"var" => "quantity"}, 25]},
          %{">" => [%{"var" => "durations"}, 23]}
        ]
      }

      data = %{"code" => "FUM", "occurence" => 15}
      assert JsonLogic.resolve(logic, data) == false

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
      assert JsonLogic.resolve(logic, data) == true

      data = %{"accessorial_service" => %{"code" => "FUM", "occurence" => 15}}
      assert JsonLogic.resolve(logic, data) == false
    end
  end

  describe "log" do
    test "that log is just a pass throug" do
      assert JsonLogic.resolve(%{"log" => [1]}) == [1]
    end
  end

  describe "unsupported operation" do
    test "raises exception" do
      assert_raise(ArgumentError, fn ->
        JsonLogic.resolve(%{"doesnotexist" => 1})
      end)
    end
  end

  describe "multi rule map" do
    test "raiese exception" do
      assert_raise(ArgumentError, fn ->
        JsonLogic.resolve(%{"-" => [1, 1], "+" => [1, 1]})
      end)
    end
  end
end
