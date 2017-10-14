# JsonLogic

[JsonLogic](http://jsonlogic.com/) implementation in Elixir

## Installation

This package can be installed by adding `json_logic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_logic, ">= 0.0.0"}
  ]
end
```

```elixir
iex> JsonLogic.apply(%{"log" => "value"})
"value"
```

Detailed documentation can be found at [https://hexdocs.pm/json_logic](https://hexdocs.pm/json_logic).

