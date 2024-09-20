defmodule Extensions.EncodeJsonObjTest do
  use ExUnit.Case, async: true

  defmodule Logic do
    use JsonLogic.Base,
      extensions: [
        JsonLogic.Extensions.EncodeJsonObj,
        JsonLogic.Extensions.Obj
      ]
  end

  doctest JsonLogic.Extensions.EncodeJsonObj, import: Logic
  describe "operation encode json obj" do

    test "builds json obj from simple list" do
      assert "{\"key1\":\"foo\"}" ==
               Logic.apply(%{
                 "encode_json_obj" => [
                   ["key1", "foo"]
                 ]
               })
    end
    test "builds json object from nested list" do
      assert "{\"key1\":\"foo\",\"key2\":42}" ==
               Logic.apply(%{
                 "encode_json_obj" => [
                   ["key1", "foo"],
                   ["key2", 42],

                 ]
               })

    end
    test "builds json object from double nested lists" do
      assert "{\"key1\":\"foo\",\"key2\":42,\"key3\":\"bar\"}" ==
               Logic.apply(%{
                 "encode_json_obj" => [

                     ["key1", "foo"],
                     ["key2", 42],
                     ["key3", "bar"]

                 ]
               })
    end

    test "builds json object from list that includes complete object resolved from data" do
      assert "{\"key1\":\"foo\",\"key2\":\"bar\"}" ==
               Logic.apply(
                 %{
                   "encode_json_obj" => [
                     %{"var" => "sub_object"},
                     ["key2", "bar"]
                   ]
                 },
                 %{"sub_object" => %{"key1" => "foo"}}
               )
    end


end
end
