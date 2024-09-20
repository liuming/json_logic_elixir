# extention of the JSONLogic module to encode objects
defmodule JsonLogic.Extensions.EncodeJsonObj do
  @moduledoc """
  This module provides the `encode_json_obj` operation for JsonLogic.
  It encodes a list of key-value pairs into a JSON object.
  The operation accepts a list of key-value pairs as an argument.

  ## Examples

      iex> Logic.apply(%{
      ...>   "encode_json_obj" => [
      ...>     ["key1", "foo"],
      ...>     ["key2", 42],
      ...>   ]
      ...> })
      ~s'{"key1":"foo","key2":42}'
  """

  @behaviour JsonLogic.Extension




  require Logger



  def operations,
    do: %{
      "encode_json_obj" => :operation_encode_json_obj
    }


  def gen_code do
    quote do
      require Logger

      def operation_encode_json_obj(args, data) when is_list(args) do

        args = %{"obj" => args}
        args
        |> __MODULE__.apply(data)
        |> Jason.encode!()
      end
    end
  end
end
