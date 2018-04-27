defmodule Adder do
  defmacro add(value) do
    name = :"add_#{value}"

    quote do
      def unquote(name)(x), do: x + unquote(value)
    end
  end
end

defmodule Test do
  require Adder

  Adder.add(5)
  Adder.add(1)
  Adder.add(:shit)

  def hello(x) do
    x + 1
    IO.inspect(add_5(3))
    IO.inspect(add_1(3))
  end
end
