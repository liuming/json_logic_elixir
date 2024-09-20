defmodule JsonLogic.Extensions.EncodeJson do
  @moduledoc """
  This module provides the `encode_json` operation for JsonLogic.

  ## Examples

      iex> Logic.apply(%{
      ...>   "encode_json" => [
      ...>     ["key1", "foo", "key2", 42],
      ...>   ]
      ...> })
      ~s'["key1","foo","key2",42]'
  """

  @behaviour JsonLogic.Extension

  require Logger


  def operations,
    do: %{
      "encode_json" => :operation_encode_json
    }


  def gen_code do
    quote do
      require Logger

      def operation_encode_json(args, data) when is_list(args) do
        args
        |> __MODULE__.apply(data)
        |> Jason.encode!()
      end
    end
  end
end
