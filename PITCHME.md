---?color=#ffffff

---?color=#3DED20

---?color=#F62020

---?color=#ffffff

---

## Мета-програмиране
(Metaprogramming)

---

### Или код, който пише код.
(Добре де - това не е добра дефиниция)

---?image=assets/meta.jpeg&size=auto 90%

---

### Нека видим първо малко приложения, за да видим за какво става въпрос!

---

#### Можем автоматично да дефинираме функции

---

```
defmodule QuickMathz do
  @values [{:one, 1}, {two: two}, {:three, 3}]

  Enum.each(@values, fn {name, value} ->
    def unquote(name)(), do: unquote(value)
  end)
end

QuickMathz.three # => 3
```

---

#### Ако сме готини, можем да направим нещо такова:

---

```
html do
  head do
    title do
      text "Hello To Our HTML DSL"
    end
  end
  body do
    h1 class: "title" do
      text "Introduction to metaprogramming"
    end
    p do
      text "Metaprogramming with Elixir is really awesome!"
    end
  end
end
```

---

### Може да дефинираме DSL-и
(Domain specific language)

---

##### Ecto(Elixir's ORM)

---

```
from o in Order,
where: o.created_at > ^Timex.shift(DateTime.utc_now(), days: -2)
join: i in OrderItems, on: i.order_id == o.id
```

---

##### Plug(Elixir's ~~http library~~ web specification)

---

##### ExUnit

---

```
defmodule Blogit.ComponentTest do
  use ExUnit.Case, async: true

  describe "when a module uses it with `use Blogit.Component`" do
    test "injects a function base_name/0, which returns the name of " <>
           "the module in underscore case" do
      assert TestComponent.base_name() == "test_component"
    end
  end

  # ... блогът има повече от 1 тест, вярвайте!
end
```

~~PS: Никола в бъдещето - коментирай тук къде е DSL-ът и не забравяй за assert~~

---

#### В други езици в тестовете пишем:

```
assert true
assert_equal 5, 4
assert_operator 5, :< 4
```

---

#### В Elixir можем само така:

```
assert true
assert 5 == 4
assert 5 < 4
```

---

### Или `plug`:

```
get "/hello" do
  send_resp(conn, 200, "world")
end

match _ do
  send_resp(conn, 404, "oops")
end
```
---

### Ако това не ви е надъхало, спокойно имам още:

---

---?image=assets/elixir.png&size=auto 90%

---

### Добре, вече като сте надъхани, можем да продължим

---

## Въведение в мета-програмирането в еликсир

---

### Elixir по нежен и удобен начин ни дава достъп до неговото AST.

---

### Позволявайки ни да манипулираме (времето и пространството) AST-то чрез макроси.

---

## Elixir AST
(quote/unquote)

–--

Макросоти са нищо повече от функции, които взимат дадено AST и връщат друго.

---

Всъщност, можем да видим абстрактното синтактично дърво(много е дълго) на всеки
израз, чрез `quote`.

---

```
iex(1)> quote do: 1 + 1
{:+, [context: Elixir, import: Kernel], [1, 1]}
```
PS: Покажи други изрази в конзолата

---

Малко по-дълъг пример:

```
iex> quote do
...> html do
...>   head do
...>     title do
...>       text "Hello To Our HTML DSL"
...>     end
...>   end
...> end
...> end``
{:html, [],
 [
   [
     do: {:head, [],
      [
        [
          do: {:title, [],
           [
             [
               do: {:text, [],
                ["Hello to our HTML DSL\n      end\n    end\n  end\nend\nend\nend\nend\nend\n"]}
             ]
           ]}
        ]
      ]}
   ]
 ]}
# Това го откраднах от миналата година!
```

---

Видяхме, че са в следния формат:
```
{<име на функция>, <контекст>, <списък от аргументи>}
# ^ важно
#                               ^ важно
#                  ^ няма да говорим за това
```

---

Това са единствените неща, чийто AST е самият израз.

```
:sum         #=> Atoms
1.0          #=> Numbers
[1, 2]       #=> Lists
"strings"    #=> Strings
{key, value} #=> Tuples with two elements
```


---?image=assets/thinking.png&size=auto 90%

---

Добре, какво става с променливите в тези изрази?

---

```
iex(3)> x = 1
1
iex(4)> quote do: x + 1
{:+, [context: Elixir, import: Kernel], [{:x, [], Elixir}, 1]}
#                                          ^ ЗАЩОООО!?!?!?!
```

---

#### unquote

---

```
iex(5)> quote do: unquote(x) + 1
{:+, [context: Elixir, import: Kernel], [1, 1]}
```

---

Всъщност `unquote` взе AST и я интерпретира в текущия контекст.

---

Добре, вече разбираме от AST, можем да го четем, всичко е точно!

---

Забелязахте ли, че AST-то прилича на LISP, ами то даже е [инспирирано от там](https://www.youtube.com/watch?v=IZvpKhA6t8A&feature=youtu.be&t=12m10s)


---

## Макроси

---

Всъщност това са просто функции, които взимат AST и връщат ново AST.
С други думи - можем да правим каквото си искаме.

---

Дефинираме ги с `defmacro`:

---

```
defmacro if(condition, do: do_clause, else: else_clause) do
  quote do
    case unquote(condition) do
      x when x, [false, nil] -> unquote(else_clause)
      _ -> unquote(do_clause)
    end
  end
end
```

---


```
iex(1)> require FMI
# => FMI
iex(2)> FMI.if true do
...(2)>   1
...(2)> else
...(2)>   2
...(2)> end
# => 1
```
---

Всъщност if-ът ни прие като аргументи:
```
FMI.if(true, [do: 1, else: 2])
```

---

Пример `unless/if`

---

Можем на една стъпка да "разгъваме" AST-та `&Macro.expand_once/2`

```
iex(1)> ast = quote do
...(1)>   FMI.unless true do
...(1)>     IO.puts "Hello"
...(1)>   end
...(1)> end
{{:., [], [{:__aliases__, [alias: false], [:FMI]}, :unless]}, [],
 [
   true,
   [
     do: {{:., [], [{:__aliases__, [alias: false], [:IO]}, :puts]}, [],
      ["Hello"]}
   ]
 ]}
```

---

След това:

```
iex(2)> require FMI # Иначе РИП
iex(3)> Macro.expand_once(ast, __ENV__)
{:if, [context: FMI, import: Kernel],
 [
   {:!, [context: FMI, import: Kernel], [true]},
   [
     do: {{:., [],
       [
         {:__aliases__, [alias: false, counter: -576460752303423390], [:IO]},
         :puts
       ]}, [], ["Hello"]},
     else: nil
   ]
 ]}
```
PS: Обясни как да си структурираме макросите.

---

Чакай малко!

---

Q: Какво е __ENV__?
A: Текущият контекст.

---

`__ENV__` е структура от `Macro.Env.t`, която съдържа информация за текущия контекст - import/require и т.н.

---

## [Macro](https://hexdocs.pm/elixir/Macro.html) модулът има доста удобни функции, повечето приемат за втори аргумент някакъв контекст.
PS: Цъкни го.

---

Шега: `Macro.expand` е пълното затваряне на операцията `Macro.expand_once` върху дадено AST.

---

[Не можем да използваме така наречените специални форми за имена на макроси](https://hexdocs.pm/elixir/Kernel.SpecialForms.html)

---

Имам няколко предизвикателства за вас:

---

Макро, което дефинира макрото `def` просто да връща линията, на който е дефиниран даден файл.

---

Макро, което ни дава да имаме повече от 255 аргумента.
PS: какво би било ast-то на `quote do: sum all 1, -1`

---

Демо html DSL
