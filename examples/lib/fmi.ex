defmodule FMI do
  defmacro if(condition, do: do_clause) do
    build_if(condition, do_clause)
  end

  defmacro if(condition, do: do_clause, else: else_clause) do
    build_if(condition, do_clause, else_clause)
  end

  defp build_if(condition, do_clause, else_clause \\ nil) do
    quote do
      case unquote(condition) do
        x when x in [false, nil] -> unquote(else_clause)
        _ -> unquote(do_clause)
      end
    end
  end

  defmacro unless(condition, do: do_clause) do
    quote do
      FMI.if unquote(condition), do: nil, else: unquote(do_clause)
    end
  end
end
