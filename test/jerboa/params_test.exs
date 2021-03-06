defmodule Jerboa.ParamsTest do
  use ExUnit.Case

  alias Jerboa.Params
  alias Jerboa.Format.Body.Attribute
  alias Attribute.XORMappedAddress

  test "new/0 returns fresh params struct with ID set" do
    p = Params.new

    assert p.identifier != nil
    assert byte_size(p.identifier) == 12
  end

  test "put_class/2 sets class field" do
    class = :request

    p = Params.new() |> Params.put_class(class)

    assert p.class == class
  end

  test "get_class/1 retrieves class field" do
    class = :request
    p = Params.new() |> Params.put_class(class)

    assert class == Params.get_class(p)
  end

  test "put_method/2 sets method field" do
    method = :binding

    p = Params.new() |> Params.put_method(method)

    assert p.method == method
  end

  test "get_method/1 retrieves method field" do
    method = :binding
    p = Params.new() |> Params.put_method(method)

    assert method == Params.get_method(p)
  end

  test "put_id/2 sets identifier field" do
    id = Params.generate_id()
    p = Params.new() |> Params.put_id(id)

    assert p.identifier == id
  end

  test "get_id/1 retrieves identifier field" do
    id = Params.generate_id()
    p = Params.new() |> Params.put_id(id)

    assert id == Params.get_id(p)
  end

  test "put_attrs/1 sets whole attributes list" do
    attrs = List.duplicate(%XORMappedAddress{}, 3)

    p = Params.new() |> Params.put_attrs(attrs)

    assert p.attributes == attrs
  end

  test "get_attrs/1 retrieves whole attributes list" do
    attrs = List.duplicate(%XORMappedAddress{}, 3)
    p = Params.new |> Params.put_attrs(attrs)

    assert attrs == Params.get_attrs(p)
  end

  describe "put_attr/2" do
    test "adds attribute to attributes list in params struct" do
      attr = %XORMappedAddress{family: :ipv4,
                               address: {127, 0, 0, 1},
                               port: 3333}

      p = Params.new() |> Params.put_attr(attr)

      assert [attr] == Params.get_attrs(p)
    end

    test "overrides existing attribute with the same name" do
      attr1 = %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 3333}
      attr2 = %XORMappedAddress{family: :ipv, address: {0, 0, 0, 0, 0, 0, 0, 1},
                                port: 3333}

      p = Params.new() |> Params.put_attr(attr1) |> Params.put_attr(attr2)

      assert [attr2] == Params.get_attrs(p)
    end
  end

  describe "get_attr/2" do
    test "retrieves attribute by its name" do
      attr = %XORMappedAddress{family: :ipv4, address: {127, 0, 0, 1}, port: 3333}

      p = Params.new() |> Params.put_attr(attr)

      assert attr == Params.get_attr(p, XORMappedAddress)
    end

    test "returns nil if attribute is not present" do
      p = Params.new

      assert nil == Params.get_attr(p, XORMappedAddress)
    end
  end
end
