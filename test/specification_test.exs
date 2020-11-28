defmodule SpecificationTest do
  use ExUnit.Case, async: true

  defp specification() do
    {:ok, content} = File.read("test/specification.json")
    {:ok, specification} = Jason.decode(content)
    specification
  end

  def dump_json(title, data) do
    {:ok, content} = Jason.encode(data, pretty: true)
    json = String.replace(content, "\n", "\n\t", global: true)
    "#{title}:\n\t#{json}"
  end

  def assert_specification(specification), do: assert_specification(specification, "", 0)

  def assert_specification([desc | rest], _, _) when is_binary(desc) do
    assert_specification(rest, desc, 1)
  end

  def assert_specification([], _, _), do: nil

  def assert_specification([[logic, data, expectation] | rest], desc, num) when is_binary(desc) do
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
