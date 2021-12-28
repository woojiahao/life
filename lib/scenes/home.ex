defmodule Life.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  @text_size 24
  @cell_size 50

  defp generate_grid(graph, grid_size) do
    cells =
      for row <- 0..grid_size//@cell_size,
          col <- 0..grid_size//@cell_size,
          do: {row, col}

    # TODO: Fix bug where we are generating an entirely new row and column

    Enum.reduce(cells, graph, fn {row, col}, acc ->
      id = String.to_atom("#{row}:#{col}")

      rectangle(acc, {@cell_size, @cell_size},
        translate: {row, col},
        stroke: {2, :white},
        id: id
      )
    end)
  end

  @impl Scenic.Scene
  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {_, height}}} = ViewPort.info(opts[:viewport])

    grid_size = height
    x_offset = grid_size + 100

    # Grid state will be a matrix represented as a dictionary of the given grid size with a boolean state denoting if
    # it is on/off
    cells = for row <- 0..height//@cell_size, col <- 0..height//@cell_size, do: {row, col}
    grid_state = cells |> Map.new(fn pos -> {pos, false} end)

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> group(&generate_grid(&1, grid_size))
      |> group(fn g ->
        g
        |> text("Life Iterations: ", translate: {x_offset, 100}, id: :life_iteration)
        |> button("Start", translate: {x_offset, 150}, id: :pause)
      end)

    state = %{
      graph: graph,
      grid_state: grid_state,
      is_started?: false,
      iteration: 0
    }

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def filter_event(
        {:click, :pause} = event,
        _from,
        %{
          graph: graph,
          grid_state: grid_state,
          is_started?: is_started?
        } = state
      ) do
    IO.inspect("Button clicked, board state is #{is_started?}")

    updated_grid_state = grid_state |> Map.new(fn {pos, v} -> {pos, !v} end)

    updated_graph =
      updated_grid_state
      |> Enum.reduce(graph, fn {{row, col}, v}, acc ->
        id = String.to_atom("#{row}:#{col}")
        fill = if v, do: :blue, else: :clear
        acc |> Graph.modify(id, &rectangle(&1, {@cell_size, @cell_size}, fill: fill))
      end)

    {:cont, event,
     %{
       state
       | graph: updated_graph,
         is_started?: !is_started?,
         grid_state: updated_grid_state
     }, push: updated_graph}
  end
end
