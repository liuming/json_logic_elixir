defmodule Extensions.ReplaceTest do
  use ExUnit.Case, async: true

  defmodule Logic do
    use JsonLogic.Base,
      extensions: [
        JsonLogic.Extensions.Replace
      ]
  end

  describe "operation replace" do
    test "replaces a string with all static arguments" do
      assert "hay-bar-ack" == Logic.apply(%{"replace" => ["haystack", "st", "-bar-"]})
    end

    test "replaces a string with a variable replacement value" do
      assert "hay-barVal-ack" ==
               Logic.apply(%{"replace" => ["haystack", "st", %{"var" => "bar"}]}, %{
                 "bar" => "-barVal-"
               })
    end

    test "replaces a string with a variable needle value" do
      assert "hay-bar-ack" ==
               Logic.apply(%{"replace" => ["haystack", %{"var" => "needle"}, "-bar-"]}, %{
                 "needle" => "st"
               })
    end

    test "replaces a variable haystack" do
      assert "hay-bar-ack" ==
               Logic.apply(%{"replace" => [%{"var" => "haystack"}, "st", "-bar-"]}, %{
                 "haystack" => "haystack"
               })
    end

    test "returns empty string for null haystack" do
      assert "" == Logic.apply(%{"replace" => [nil, "st", "-bar-"]})
    end

    test "removes needle from haystack for null replacer" do
      assert "hay" == Logic.apply(%{"replace" => ["haystack", "stack", nil]})
    end

    test "doesn't modify the haystack for null needle" do
      assert "haystack" == Logic.apply(%{"replace" => ["haystack", nil, "-bar-"]})
    end
  end
end
