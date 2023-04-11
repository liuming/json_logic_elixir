# JsonLogic

[JsonLogic](http://jsonlogic.com/) implementation in Elixir.

Forked from [liuming/json_logic_elixir](https://github.com/liuming/json_logic_elixir) and modified by Box ID to allow
for project-specific extensions (custom operations) at compile-time.

## Installation

This package can be installed by adding `json_logic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_logic, github: "box-id/json_logic_elixir"}
  ]
end
```

```elixir
iex> JsonLogic.apply(%{"log" => "value"})
"value"
```

Detailed documentation can be found at [https://hexdocs.pm/json_logic](https://hexdocs.pm/json_logic).

## Custom Operators

To add custom operators to JsonLogic, implement them like in the following example:

```elixir
defmodule MyApp.JsonLogic do
  use JsonLogic.Base,
    operations: %{
      "regex" => :regex_match
    }

  def regex_match([pattern, field], data) do
    string = if is_map(field), do: __MODULE__.apply(field, data), else: field
    regex = compile_regex(pattern)

    Regex.match?(regex, string)
  end

  defp compile_regex(pattern) when is_binary(pattern), do: Regex.compile!(pattern)

  defp compile_regex(%{"pattern" => pattern, "options" => options}),
    do: Regex.compile!(pattern, options)
end
```

## Extensions

Extensions can be used like this:

```elixir
defmodule MyApp.JsonLogic do
  use JsonLogic.Base,
    extensions: [JsonLogic.Extension.Obj]
```

Extensions can bring one or multiple operators. Using extensions is compatible with custom operators.

See the [JsonLogic.Extension](lib/json_logic/extension.ex) for how to implement an extension.
