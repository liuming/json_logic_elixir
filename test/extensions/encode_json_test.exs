defmodule Extension.EncodeJsonTest do
  use ExUnit.Case, async: true

  defmodule Logic do
    use JsonLogic.Base,
      extensions: [
        JsonLogic.Extensions.EncodeJson
      ]
  end

  doctest JsonLogic.Extensions.EncodeJson, import: Logic
  describe "operation encode json" do


    test "builds json from simple list" do
      assert "[\"key1\",\"foo\"]" ==
               Logic.apply(%{
                 "encode_json" => [
                   "key1", "foo"
                 ]
               })
    end

    test "builds json from nested list" do
      assert "[\"key1\",\"foo\",\"key2\",42]" ==
               Logic.apply(%{
                 "encode_json" => [
                   ["key1", "foo", "key2", 42],
                 ]
               })

    end
    test "builds json from double nested lists" do
      assert "[\"key1\",\"foo\",\"key2\",42,\"key3\",\"bar\"]" ==
               Logic.apply(%{
                 "encode_json" => [
                   [
                     ["key1", "foo", "key2", 42],
                     ["key3", "bar"]
                   ]
                 ]
               })
    end

    test "builds json from list that includes complete object resolved from data" do
      assert "[{\"key1\":\"foo\"},\"key2\",\"bar\"]"==
               Logic.apply(
                 %{
                   "encode_json" => [
                     %{"var" => "sub_object"},
                     ["key2", "bar"]
                   ]
                 },
                 %{"sub_object" => %{"key1" => "foo"}}
               )
    end
end
end
