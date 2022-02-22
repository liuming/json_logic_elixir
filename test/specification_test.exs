defmodule SpecificationTest do
  use ExUnit.Case

  defp json_library do
    Application.get_env(:json_logic_elixir, :json_library, Poison)
  end

  defp encode_json(content, opts) do
    json_library().encode(content, opts)
  end

  defp decode_json(content, opts \\ []) do
    json_library().decode(content, opts)
  end

  defp specification() do
    {:ok, content} = File.read("test/specification.json")
    {:ok, specification} = decode_json(content)
    specification
  end

  def dump_json(title, data) do
    {:ok, content} = encode_json(data, pretty: true)
    json = String.replace(content, "\n", "\n\t", global: true)
    "#{title}:\n\t#{json}"
  end

  def assert_specification(specification), do: assert_specification(specification, "", 0)

  def assert_specification([desc | rest], _, _) when is_binary(desc) do
    assert_specification(rest, desc, 1)
  end

  def assert_specification([], _, _), do: nil

  def assert_specification([[logic, data, expectation] | rest], desc, num) when is_binary(desc) do
    # IO.puts """
    # #{desc} - #{num}

    # #{dump_json("Logic", logic)}

    # #{dump_json("Data", data)}

    # #{dump_json("Expectation", expectation)}
    # """

    assert JsonLogic.apply(logic, data) == expectation, """
    #{desc} - #{num}

    #{dump_json("Logic", logic)}

    #{dump_json("Data", data)}

    #{dump_json("Output", JsonLogic.apply(logic, data))}

    #{dump_json("Expectation", expectation)}
    """

    assert_specification(rest, desc, num + 1)
  end

  test "specification" do
    assert_specification(specification())
  end
end
