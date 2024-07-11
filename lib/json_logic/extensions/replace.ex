defmodule JsonLogic.Extensions.Replace do
  @moduledoc """
  Extension that provides the `replace` operator which replaces all occurrences of a substring in a string with another
  substring.

  The operator accepts three arguments:

  - `subject` (required): The string to search and replace in.
  - `search` (required): The substring to search for.
  - `replace` (required): The substring to replace `search` with.

  If `subject` is `null`, it will be treated as an empty string.
  If `search` is `null`, the `subject` will be returned unmodified.
  If `replace` is `null`, all occurrences of `search` will be removed from the `subject`.
  """
  @behaviour JsonLogic.Extension

  @impl true
  def operations do
    %{
      "replace" => :operation_replace
    }
  end

  @impl true
  def gen_code do
    quote do
      def operation_replace([subject, search, replace], data) do
        subject =
          JsonLogic.Extensions.Replace.maybe_resolve_binary(subject, data, __MODULE__) || ""

        search = JsonLogic.Extensions.Replace.maybe_resolve_binary(search, data, __MODULE__)

        replace =
          JsonLogic.Extensions.Replace.maybe_resolve_binary(replace, data, __MODULE__) || ""

        # If search is nil, the subject should be returned unmodified. Defaulting to "" would result in `replace` being
        # inserted into the subject between all original characters.
        if search == nil do
          subject
        else
          String.replace(subject, search, replace)
        end
      end
    end
  end

  def maybe_resolve_binary(value, data, logic_module) do
    case value do
      binary when is_binary(binary) -> binary
      _ -> logic_module.apply(value, data)
    end
  end
end
