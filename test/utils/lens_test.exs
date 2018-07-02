defmodule Utils.LensTest do
  use ExUnit.Case
  doctest Elixirdo.Base.Utils.Lens

  alias Elixirdo.Base.Utils.Lens

  test "compose" do
    user_a = %{name: {"john", "smith"}, gender: "male"}
    user_b = %{name: {"mary", "jane"}, gender: "female"}

    lens_name = Lens.map_lens(:name)
    lens_last_name = Lens.tuple_lens(2)

    lens = Lens.compose(lens_name, lens_last_name)

    assert Lens.view(lens, user_a) == "smith"
    assert Lens.view(lens, user_b) == "jane"

  end

  test "rcompose" do
    user_a = %{name: {"john", "smith"}, gender: "male"}
    user_b = %{name: {"mary", "jane"}, gender: "female"}

    lens_name = Lens.map_lens(:name)
    lens_first = Lens.tuple_lens(1)
    lens_first_name = Lens.compose(lens_name, lens_first)

    r_lens_first_name = Lens.tuple_lens(1)

    lens = Lens.rcompose(lens_first_name, r_lens_first_name, {nil, nil})

    ca = {"john", nil}
    cb = {"mary", nil}

    assert Lens.view(lens, user_a) == ca
    assert Lens.view(lens, user_b) == cb
  end

  test "rcomposes" do
    user_a = %{name: {"john", "smith"}, gender: "male"}
    user_b = %{name: {"mary", "jane"}, gender: "female"}

    lens_name = Lens.map_lens(:name)
    lens_first = Lens.tuple_lens(1)
    lens_first_name = Lens.compose(lens_name, lens_first)
    lens_gender = Lens.map_lens(:gender)

    r_lens_first_name = Lens.tuple_lens(1)
    r_lens_gender = Lens.tuple_lens(2)

    lens = Lens.rcomposes([lens_first_name, lens_gender], [r_lens_first_name, r_lens_gender], {nil, nil})

    ca = {"john", "male"}
    cb = {"mary", "female"}

    assert Lens.view(lens, user_a) == ca
    assert Lens.view(lens, user_b) == cb
  end
end
