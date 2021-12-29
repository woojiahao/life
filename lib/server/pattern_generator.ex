defmodule Life.Server.PatternGenerator do
  def create_pattern(cells, :blinker) do
    # blinker is a type of oscillator
    IO.puts("Creating blinker pattern")

    alive = [
      {3, 1},
      {3, 2},
      {3, 3}
    ]

    cells |> load_pattern(alive)
  end

  def create_pattern(cells, :beacon) do
    IO.puts("Creating beacon pattern")

    alive = [
      {2, 2},
      {2, 3},
      {3, 2},
      {3, 3},
      {4, 4},
      {4, 5},
      {5, 4},
      {5, 5}
    ]

    cells |> load_pattern(alive)
  end

  def create_pattern(cells, :toad) do
    IO.puts("Creating toad pattern")

    alive = [
      {3, 3},
      {3, 4},
      {3, 5},
      {4, 2},
      {4, 3},
      {4, 4},
    ]

    cells |> load_pattern(alive)
  end

  def create_pattern(cells, _), do: cells

  defp load_pattern(cells, alive) do
    cells
    |> Map.new(fn {{row, col}, _} ->
      state = if {row, col} in alive, do: true, else: false
      {{row, col}, state}
    end)
  end
end
