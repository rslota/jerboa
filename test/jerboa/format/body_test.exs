defmodule Jerboa.Format.BodyTest do
  use ExUnit.Case, async: true

  alias Jerboa.Test.Helper.XORMappedAddress, as: XORMAHelper
  alias Jerboa.Test.Helper.Attribute, as: AHelper
  alias Jerboa.Format
  alias Jerboa.Format.Body
  alias Jerboa.Params
  alias Jerboa.Format.Body.Attribute.Data
  alias Jerboa.Format.Meta
  alias Jerboa.Format.MessageIntegrity, as: MI

  describe "Body.encode/2" do

    test "one (XORMappedAddress) attribute into one TLV field" do
      attr = XORMAHelper.struct(4)

      %Meta{body: bin} = Body.encode %Meta{params: %Params{attributes: [attr]}}

      assert bit_size(bin) === AHelper.total(type: 16, length: 16, value: 64)
    end

    test "appends padding to boundary of 4 bytes" do
      content = "Hello"
      attr = %Data{content: content}

      length = byte_size(content)
      padded_length = length + AHelper.padding_length(length)

      params = Params.new() |> Params.put_attr(attr)
      %Meta{body: body} = %Meta{params: params} |> Body.encode()

      assert <<_type::16, ^length::16, padded_value::binary>> = body
      assert byte_size(padded_value) == padded_length
    end
  end

  describe "Body.decode/1" do

    test "unknown comprehension required attribute results in :error tuple" do
      for type <- 0x0000..0x7FFF, not type in known_comprehension_required() do
        body = <<type::16, 0::16>>

        {:error, error} = Body.decode(%Meta{body: body})
        assert %Format.ComprehensionError{attribute: ^type} = error
      end
    end

    test "ignores unknown comprehension optional attributes" do
      for type <- 0x8000..0xFFFF, not type in known_comprehension_optional() do
        body = <<type::16, 0::16>>
        assert {:ok, %Meta{params: params}} = Body.decode(%Meta{body: body})
        assert %Params{attributes: []} = params
      end
    end

    test "strips value padding" do
      # DATA attribute with type, length and value with padding
      body = <<0x0013::16, 5::16, "Hello", 0, 0, 0>>

      assert {:ok, _} = Body.decode(%Meta{body: body})
    end

    test "attribute of invalid length results in error" do
      body = <<0x0008::16, 1::16>>

      assert {:error, error} = Body.decode(%Meta{body: body})
      assert %Format.AttributeFormatError{} = error
    end

    test "fails if message integrity has invalid length" do
      length = 19
      body = <<0x0008::16, length::16, 0::size(length)-unit(8)>>

      assert {:error, %MI.FormatError{}} = Body.decode(%Meta{body: body})
    end
  end

  defp known_comprehension_required do
    [0x0020, 0x000D, 0x0013, 0x0015, 0x0006, 0x0014, 0x0009, 0x0012, 0x0016,
     0x0008, 0x0019]
  end

  defp known_comprehension_optional do
    []
  end
end
