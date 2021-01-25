defmodule JsonLogic do
  @moduledoc """
  An Elixir implementation of [JsonLogic](http://jsonlogic.com/).

  To extend JsonLogic with custom operations, see `JsonLogic.Base` for more information.

  ## Examples
      iex> JsonLogic.apply(nil)
      nil

      iex> JsonLogic.apply(%{})
      %{}

      iex> JsonLogic.apply(%{"var" => "key"}, %{"key" => "value"})
      "value"

      iex> JsonLogic.apply(%{"var" => "nested.key"}, %{"nested" => %{"key" => "value"}})
      "value"

      iex> JsonLogic.apply(%{"var" => ["none", "default"]}, %{"key" => "value"})
      "default"

      iex> JsonLogic.apply(%{"var" => 0}, ~w{a b})
      "a"

      iex> JsonLogic.apply(%{"==" => [1, 1]})
      true

      iex> JsonLogic.apply(%{"==" => [0, 1]})
      false

      iex> JsonLogic.apply(%{"!=" => [1, 1]})
      false

      iex> JsonLogic.apply(%{"!=" => [0, 1]})
      true

      iex> JsonLogic.apply(%{"===" => [1, 1]})
      true

      iex> JsonLogic.apply(%{"===" => [1, 1.0]})
      false

      iex> JsonLogic.apply(%{"===" => [1, %{"var" => "key"}]}, %{"key" => 1})
      true

      iex> JsonLogic.apply(%{"!==" => [1, 1.0]})
      true

      iex> JsonLogic.apply(%{"!==" => [1, 1]})
      false

      iex> JsonLogic.apply(%{"!" => true})
      false

      iex> JsonLogic.apply(%{"!" => false})
      true

      iex> JsonLogic.apply(%{"if" => [true, "yes", "no" ]})
      "yes"

      iex> JsonLogic.apply(%{"if" => [false, "yes", "no" ]})
      "no"

      iex> JsonLogic.apply(%{"if" => [false, "unexpected", false, "unexpected", "default" ]})
      "default"

      iex> JsonLogic.apply(%{"or" => [false, nil, "truthy"]})
      "truthy"

      iex> JsonLogic.apply(%{"or" => ["first", "truthy"]})
      "first"

      iex> JsonLogic.apply(%{"and" => [false, "falsy"]})
      false

      iex> JsonLogic.apply(%{"and" => [true, 1, "truthy"]})
      "truthy"

      iex> JsonLogic.apply(%{"max" => [1,2,3]})
      3

      iex> JsonLogic.apply(%{"min" => [1,2,3]})
      1

      iex> JsonLogic.apply(%{"<" => [0, 1]})
      true

      iex> JsonLogic.apply(%{"<" => [1, 0]})
      false

      iex> JsonLogic.apply(%{"<" => [0, 1, 2]})
      true

      iex> JsonLogic.apply(%{"<" => [0, 2, 1]})
      false

      iex> JsonLogic.apply(%{">" => [1, 0]})
      true

      iex> JsonLogic.apply(%{">" => [0, 1]})
      false

      iex> JsonLogic.apply(%{">" => [2, 1, 0]})
      true

      iex> JsonLogic.apply(%{">" => [2, 0, 1]})
      false

      iex> JsonLogic.apply(%{"<=" => [1, 1]})
      true

      iex> JsonLogic.apply(%{"<=" => [1, 0]})
      false

      iex> JsonLogic.apply(%{"<=" => [1, 1, 2]})
      true

      iex> JsonLogic.apply(%{"<=" => [1, 0, 2]})
      false

      iex> JsonLogic.apply(%{">=" => [1, 1]})
      true

      iex> JsonLogic.apply(%{">=" => [0, 1]})
      false

      iex> JsonLogic.apply(%{">=" => [1, 1, 0]})
      true

      iex> JsonLogic.apply(%{">=" => [0, 1, 2]})
      false

      iex> JsonLogic.apply(%{"+" => [1,2,3]})
      6

      iex> JsonLogic.apply(%{"+" => [2]})
      2

      iex> JsonLogic.apply(%{"-" => [7,4]})
      3

      iex> JsonLogic.apply(%{"-" => [2]})
      -2

      iex> JsonLogic.apply(%{"*" => [2,3,4]})
      24

      iex> JsonLogic.apply(%{"/" => [5,2]})
      2.5

      iex> JsonLogic.apply(%{"%" => [7, 3]})
      1

      iex> JsonLogic.apply(%{"map" => [ [1,2,3,4,5], %{"*" => [%{"var" => ""}, 2]} ]})
      [2,4,6,8,10]

      iex> JsonLogic.apply(%{"filter" => [ [1,2,3,4,5], %{">" => [%{"var" => ""}, 2]} ]})
      [3,4,5]

      iex> JsonLogic.apply(%{"reduce" => [ [1,2,3,4,5], %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]}, 0]})
      15

      iex> JsonLogic.apply(%{"all" => [ [1,2,3], %{">" => [ %{"var" => ""}, 0 ]} ]})
      true

      iex> JsonLogic.apply(%{"all" => [ [-1,2,3], %{">" => [ %{"var" => ""}, 0 ]} ]})
      false

      iex> JsonLogic.apply(%{"none" => [ [1,2,3], %{"<" => [ %{"var" => ""}, 0 ]} ]})
      true

      iex> JsonLogic.apply(%{"none" => [ [-1,2,3], %{"<" => [ %{"var" => ""}, 0 ]} ]})
      false

      iex> JsonLogic.apply(%{"some" => [ [-1,2,3], %{"<" => [ %{"var" => ""}, 0 ]} ]})
      true

      iex> JsonLogic.apply(%{"some" => [ [1,2,3], %{"<" => [ %{"var" => ""}, 0 ]} ]})
      false

      iex> JsonLogic.apply(%{"in" => ["sub", "substring"]})
      true

      iex> JsonLogic.apply(%{"in" => ["na", "substring"]})
      false

      iex> JsonLogic.apply(%{"in" => ["a", ["a", "b", "c"]]})
      true

      iex> JsonLogic.apply(%{"in" => ["z", ["a", "b", "c"]]})
      false

      iex> JsonLogic.apply(%{"cat" => ["a", "b", "c"]})
      "abc"

      iex> JsonLogic.apply(%{"log" => "string"})
      "string"
  """

  use JsonLogic.Base
end
