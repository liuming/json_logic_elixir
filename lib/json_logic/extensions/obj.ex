defmodule JsonLogic.Extensions.Obj do
  @moduledoc """
  Extension that provides the `obj` operator which builds an object from key-value pairs or by merging existing objects.

  The operator accepts a list of (mixed) entries, each of which can be either:

  - a list-based `[key, value]` tuple where `key` is a binary.
  - a map with exactly one key. The operator will try to evaluate it as a logic expression but will fall back to
    returning it as-is if evaluation fails.
  - a map with an arbitrary number of keys which will be merged upon the previous entries

  Entries that do not conform to one of the above formats will be ignored. Later entries overwrite values from earlier
  entries.

  Similar to the `var` operator, `obj` has a shorthand where the argument(s) will be wrapped in a list if they aren't
  already.

  ## Examples

      iex> Logic.apply(%{"obj" => [
      ...>  ["key1", "foo"],
      ...>  ["key2", "bar"]
      ...> ]})
      %{"key1" => "foo", "key2" => "bar"}

      iex> Logic.apply(%{
      ...>   "obj" => [
      ...>     %{
      ...>       "map" => [
      ...>         [1, 2],
      ...>         [
      ...>           %{"cat" => ["key_", %{"var" => ""}]},
      ...>           "foo"
      ...>         ]
      ...>       ]
      ...>     },
      ...>     ["static", "foo"]
      ...>   ]
      ...> })
      %{"key_1" => "foo", "key_2" => "foo", "static" => "foo"}
  """
  @behaviour JsonLogic.Extension

  require Logger

  @impl true
  def operations,
    do: %{
      "obj" => :operation_obj
    }

  @impl true
  def gen_code do
    quote do
      require Logger

      def operation_obj(args, data) when is_list(args) do
        Enum.map(args, fn
          # Special case of a list-as-tuple entry that allows us to build lists (which would otherwise get flattened by
          # JsonLogic) by keeping them wrapped in a list.
          [key, args] ->
            [__MODULE__.apply(key, data), __MODULE__.apply(args, data)]

          # arg when is_list(arg) ->
          #   __MODULE__.apply(arg, data)

          # Allow & execute operations, but ignore failure if there is no operation with that name.
          maybe_op when is_map(maybe_op) ->
            try do
              __MODULE__.apply(maybe_op, data)
            rescue
              ArgumentError ->
                maybe_op
            end

          unsupported ->
            Logger.warning(
              "JsonLogic: Unsupported argument for operator 'obj' #{inspect(unsupported)} in logic #{inspect(args, charlists: :as_lists)}}"
            )

            []
        end)
        |> Enum.flat_map(&JsonLogic.Extensions.Obj.convert_to_tuples/1)
        |> Map.new()
      end

      def operation_obj(args, data), do: operation_obj([args], data)
    end
  end

  def convert_to_tuples([key, value]) when is_binary(key), do: [{key, value}]
  def convert_to_tuples({key, value}), do: [{key, value}]

  def convert_to_tuples(list) when is_list(list),
    do: Enum.flat_map(list, &convert_to_tuples/1)

  def convert_to_tuples(map) when is_map(map), do: map

  def convert_to_tuples(unsupported) do
    Logger.warning("JsonLogic: Unsupported argument for operator 'obj': #{inspect(unsupported)}")

    []
  end
end
