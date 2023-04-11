defmodule JsonLogic.Extension do
  @moduledoc """
  Defines the necessary methods for a module to implement in order to provide additional logic operations as a JsonLogic
  Extension.
  """

  @doc """
  Returns map of (binary) operation names to (atom) function name implementing the action.

  ## Example

      %{
        "obj" => :operation_obj
      }
  """
  @callback operations() :: %{required(binary()) => atom()}

  @doc """
  Returns AST of the functions needed to implement the extension. The returned functions will be defined on the
  JsonLogic module.

  ## Example

      def gen_code do
        quote do
          def operation_obj(args, data) do
            __MODULE__.apply(args)
          end
        end
      end
  """
  @callback gen_code() :: Macro.t()
end
