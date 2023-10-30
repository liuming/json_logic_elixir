defmodule Extensions.ObjTest do
  use ExUnit.Case, async: true

  defmodule Logic do
    use JsonLogic.Base,
      extensions: [
        JsonLogic.Extensions.Obj
      ]
  end

  doctest JsonLogic.Extensions.Obj, import: Logic

  describe "operation obj" do
    test "builds object from list of hardcoded key-value pairs" do
      assert %{"key1" => "foo", "key2" => 42} ==
               Logic.apply(%{
                 "obj" => [
                   ["key1", "foo"],
                   ["key2", 42]
                 ]
               })
    end

    test "builds object from nested list of hardcoded key-value pairs" do
      assert %{"key1" => "foo", "key2" => 42, "key3" => "bar"} ==
               Logic.apply(%{
                 "obj" => [
                   %{
                     "obj" => [
                       ["key1", "foo"],
                       ["key2", 42]
                     ]
                   },
                   ["key3", "bar"]
                 ]
               })
    end

    test "builds object from list of objects" do
      assert %{"key1" => "foo", "key2" => 42} ==
               Logic.apply(%{
                 "obj" => [
                   %{"key1" => "bar"},
                   %{"key2" => 42, "key1" => "foo"}
                 ]
               })
    end

    test "builds object from mixed list that includes var value" do
      assert %{"key1" => "foo", "key2" => 42} ==
               Logic.apply(
                 %{
                   "obj" => [
                     %{"key1" => "foo", "key2" => "bar"},
                     ["key2", %{"var" => "key2_val"}]
                   ]
                 },
                 %{"key2_val" => 42}
               )
    end

    test "builds object from list that includes var key" do
      assert %{"key1" => "foo"} ==
               Logic.apply(
                 %{
                   "obj" => [
                     [%{"var" => "key1_name"}, "foo"]
                   ]
                 },
                 %{"key1_name" => "key1"}
               )
    end

    test "builds object from list that includes complete object resolved from data" do
      assert %{"key1" => "foo", "key2" => "bar"} ==
               Logic.apply(
                 %{
                   "obj" => [
                     %{"var" => "sub_object"},
                     ["key2", "bar"]
                   ]
                 },
                 %{"sub_object" => %{"key1" => "foo"}}
               )
    end

    test "builds object from list that has computed keys" do
      assert %{"key_1" => "foo", "key_2" => "foo", "static" => "foo"} ==
               Logic.apply(%{
                 "obj" => [
                   %{
                     "map" => [
                       [1, 2],
                       [
                         %{"cat" => ["key_", %{"var" => ""}]},
                         "foo"
                       ]
                     ]
                   },
                   ["static", "foo"]
                 ]
               })
    end

    test "returns empty object when given incompatible inputs" do
      assert %{} == Logic.apply(%{"obj" => "foo"})
      assert %{} == Logic.apply(%{"obj" => ["foo"]})
      assert %{} == Logic.apply(%{"obj" => [["foo", "bar", "baz"]]})
      assert %{} == Logic.apply(%{"obj" => [42]})
      assert %{} == Logic.apply(%{"obj" => 42})

      assert %{"ok" => "some_value"} ==
               Logic.apply(%{
                 "obj" => [
                   # Next line will be ignored
                   42,
                   # This will not
                   ["ok", "some_value"],
                   # But this will be again
                   ["foo", "bar", "baz"]
                 ]
               })
    end

    test "passing an object acts as shorthand, equals list-wrapped version" do
      assert %{"key_1" => "foo", "key_2" => "foo"} ==
               Logic.apply(%{
                 "obj" => %{
                   "map" => [
                     [1, 2],
                     [
                       %{"cat" => ["key_", %{"var" => ""}]},
                       "foo"
                     ]
                   ]
                 }
               })

      assert %{"some_object_that" => "should_be_resolved"} ==
               Logic.apply(%{"obj" => %{"var" => "foo"}}, %{
                 "foo" => %{"some_object_that" => "should_be_resolved"}
               })

      assert %{"verbatim" => true} == Logic.apply(%{"obj" => %{"verbatim" => true}})
    end

    test "builds object with list values" do
      assert %{"labels" => ["foo1", "foo2"]} =
               Logic.apply(%{
                 "obj" => [
                   ["labels", ["foo1", "foo2"]]
                 ]
               })
    end

    test "builds object with list values from var" do
      assert %{"labels" => ["foo1", "foo2"]} =
               Logic.apply(
                 %{
                   "obj" => [
                     ["labels", %{"var" => "asset_labels"}]
                   ]
                 },
                 %{
                   "asset_labels" => ["foo1", "foo2"]
                 }
               )
    end
  end
end
