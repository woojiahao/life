defmodule Life.Server.PatternGenerator do
  def create_pattern(cells, :blinker) do
    # blinker is a type of oscillator
    IO.puts("Creating blinker pattern")

    alive = [
      {3, 2},
      {3, 3},
      {3, 4}
    ]

    cells |> load_alive(alive)
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

    cells |> load_alive(alive)
  end

  def create_pattern(cells, :toad) do
    IO.puts("Creating toad pattern")

    alive = [
      {3, 3},
      {3, 4},
      {3, 5},
      {4, 2},
      {4, 3},
      {4, 4}
    ]

    cells |> load_alive(alive)
  end

  def create_pattern(cells, :pulsar) do
    IO.puts("Creating pulsar pattern")

    alive = [
      {2, 4},
      {2, 5},
      {2, 6},
      {2, 10},
      {2, 11},
      {2, 12},
      {4, 2},
      {4, 7},
      {4, 9},
      {4, 14},
      {5, 2},
      {5, 7},
      {5, 9},
      {5, 14},
      {6, 2},
      {6, 7},
      {6, 9},
      {6, 14},
      {7, 4},
      {7, 5},
      {7, 6},
      {7, 10},
      {7, 11},
      {7, 12},
      {9, 4},
      {9, 5},
      {9, 6},
      {9, 10},
      {9, 11},
      {9, 12},
      {10, 2},
      {10, 7},
      {10, 9},
      {10, 14},
      {11, 2},
      {11, 7},
      {11, 9},
      {11, 14},
      {12, 2},
      {12, 7},
      {12, 9},
      {12, 14},
      {14, 4},
      {14, 5},
      {14, 6},
      {14, 10},
      {14, 11},
      {14, 12}
    ]

    cells |> load_alive(alive)
  end

  def create_pattern(cells, _), do: cells

  def load_alive(cells, alive) do
    cells
    |> Map.new(fn {{row, col}, _} ->
      state = if {row, col} in alive, do: true, else: false
      {{row, col}, state}
    end)
  end
end
