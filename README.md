# JsonLogic with Exponent Operator

[JsonLogic](http://jsonlogic.com/) implementation in Elixir forked, added support for exponential operation

## Installation

This package can be installed by adding `json_logic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_logic_exponent, ">= 0.0.0"}
  ]
end
```

## Examples

```elixir
JsonLogic.resolve(nil)
#=> nil

JsonLogic.resolve(%{})
#=> %{}

JsonLogic.resolve(%{"var" => "key"}, %{"key" => "value"})
#=> "value"

JsonLogic.resolve(%{"var" => "nested.key"}, %{"nested" => %{"key" => "value"}})
#=> "value"

JsonLogic.resolve(%{"var" => ["none", "default"]}, %{"key" => "value"})
#=> "default"

JsonLogic.resolve(%{"var" => 0}, ~w{a b})
#=> "a"

JsonLogic.resolve(%{"==" => [1, 1]})
#=> true

JsonLogic.resolve(%{"==" => [0, 1]})
#=> false

JsonLogic.resolve(%{"!=" => [1, 1]})
#=> false

JsonLogic.resolve(%{"!=" => [0, 1]})
#=> true

JsonLogic.resolve(%{"===" => [1, 1]})
#=> true

JsonLogic.resolve(%{"===" => [1, 1.0]})
#=> false

JsonLogic.resolve(%{"===" => [1, %{"var" => "key"}]}, %{"key" => 1})
#=> true

JsonLogic.resolve(%{"!==" => [1, 1.0]})
#=> true

JsonLogic.resolve(%{"!==" => [1, 1]})
#=> false

JsonLogic.resolve(%{"!" => true})
#=> false

JsonLogic.resolve(%{"!" => false})
#=> true

JsonLogic.resolve(%{"if" => [true, "yes", "no" ]})
#=> "yes"

JsonLogic.resolve(%{"if" => [false, "yes", "no" ]})
#=> "no"

JsonLogic.resolve(%{"if" => [false, "unexpected", false, "unexpected", "default" ]})
#=> "default"

JsonLogic.resolve(%{"or" => [false, nil, "truthy"]})
#=> "truthy"

JsonLogic.resolve(%{"or" => ["first", "truthy"]})
#=> "first"

JsonLogic.resolve(%{"and" => [false, "falsy"]})
#=> false

JsonLogic.resolve(%{"and" => [true, 1, "truthy"]})
#=> "truthy"

JsonLogic.resolve(%{"max" => [1,2,3]})
#=> 3

JsonLogic.resolve(%{"min" => [1,2,3]})
#=> 1

JsonLogic.resolve(%{"<" => [0, 1]})
#=> true

JsonLogic.resolve(%{"<" => [1, 0]})
#=> false

JsonLogic.resolve(%{"<" => [0, 1, 2]})
#=> true

JsonLogic.resolve(%{"<" => [0, 2, 1]})
#=> false

JsonLogic.resolve(%{">" => [1, 0]})
#=> true

JsonLogic.resolve(%{">" => [0, 1]})
#=> false

JsonLogic.resolve(%{">" => [2, 1, 0]})
#=> true

JsonLogic.resolve(%{">" => [2, 0, 1]})
#=> false

JsonLogic.resolve(%{"<=" => [1, 1]})
#=> true

JsonLogic.resolve(%{"<=" => [1, 0]})
#=> false

JsonLogic.resolve(%{"<=" => [1, 1, 2]})
#=> true

JsonLogic.resolve(%{"<=" => [1, 0, 2]})
#=> false

JsonLogic.resolve(%{">=" => [1, 1]})
#=> true

JsonLogic.resolve(%{">=" => [0, 1]})
#=> false

JsonLogic.resolve(%{">=" => [1, 1, 0]})
#=> true

JsonLogic.resolve(%{">=" => [0, 1, 2]})
#=> false

JsonLogic.resolve(%{"+" => [1,2,3]})
#=> 6

JsonLogic.resolve(%{"+" => [2]})
#=> 2

JsonLogic.resolve(%{"-" => [7,4]})
#=> 3

JsonLogic.resolve(%{"-" => [2]})
#=> -2

JsonLogic.resolve(%{"*" => [2,3,4]})
#=> 24

JsonLogic.resolve(%{"^" => [2,7]})
#=> 128.0

JsonLogic.resolve(%{"^" => [0.97,7]})
#=> 0.8079828447811298

JsonLogic.resolve(%{"^" => [5,-6]})
#=> 6.4e-5

JsonLogic.resolve(%{"^" => [2,3,4]})
#=> 128.0

JsonLogic.resolve(%{"^" => [0.97,3,4]})
#=> 0.8079828447811298

JsonLogic.resolve(%{"^" => [5,-2, -4]})
#=> 6.4e-5

JsonLogic.resolve(%{"/" => [5,2]})
#=> 2.5

JsonLogic.resolve(%{"%" => [7, 3]})
#=> 1

JsonLogic.resolve(%{"map" => [[1,2,3,4,5], %{"*" => [%{"var" => ""}, 2]}]})
#=> [2,4,6,8,10]

JsonLogic.resolve(%{"map" => [[1,2,3,4,5], %{"^" => [%{"var" => ""}, 2]}]})
#=> [1.0, 4.0, 9.0, 16.0, 25.0]

JsonLogic.resolve(%{"filter" => [[1,2,3,4,5], %{">" => [%{"var" => ""}, 2]}]})
#=> [3,4,5]

JsonLogic.resolve(%{"reduce" => [[1,2,3,4,5], %{"+" => [%{"var" => "current"}, %{"var" => "accumulator"}]}, 0]})
#=> 15

JsonLogic.resolve(%{"all" => [[1,2,3], %{">" => [%{"var" => ""}, 0]}]})
#=> true

JsonLogic.resolve(%{"all" => [[-1,2,3], %{">" => [%{"var" => ""}, 0]}]})
#=> false

JsonLogic.resolve(%{"none" => [[1,2,3], %{"<" => [%{"var" => ""}, 0 ]}]})
#=> true

JsonLogic.resolve(%{"none" => [[-1,2,3], %{"<" => [%{"var" => ""}, 0 ]}]})
#=> false

JsonLogic.resolve(%{"some" => [[-1,2,3], %{"<" => [%{"var" => ""}, 0 ]}]})
#=> true

JsonLogic.resolve(%{"some" => [[1,2,3], %{"<" => [%{"var" => ""}, 0 ]}]})
#=> false

JsonLogic.resolve(%{"in" => ["sub", "substring"]})
#=> true

JsonLogic.resolve(%{"in" => ["na", "substring"]})
#=> false

JsonLogic.resolve(%{"in" => ["a", ["a", "b", "c"]]})
#=> true

JsonLogic.resolve(%{"in" => ["z", ["a", "b", "c"]]})
#=> false

JsonLogic.resolve(%{"cat" => ["a", "b", "c"]})
#=> "abc"

JsonLogic.resolve(%{"log" => "string"})
#=> "string"
```

Detailed documentation can be found at [https://hexdocs.pm/json_logic](https://hexdocs.pm/json_logic).

