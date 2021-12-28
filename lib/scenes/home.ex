defmodule Life.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Life.Server

  import Scenic.Primitives
  import Scenic.Components

  @text_size 24

  defp generate_grid(graph, grid_size, cell_size) do
    cells =
      for row <- 0..grid_size//cell_size,
          col <- 0..grid_size//cell_size,
          do: {row, col}

    # TODO: Fix bug where we are generating an entirely new row and column

    Enum.reduce(cells, graph, fn {row, col}, acc ->
      id = String.to_atom("#{row}:#{col}")

      rectangle(acc, {cell_size, cell_size},
        translate: {row, col},
        stroke: {2, :white},
        id: id
      )
    end)
  end

  @impl Scenic.Scene
  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {_, height}}} = ViewPort.info(opts[:viewport])

    %{cell_size: cell_size} = Application.get_env(:life, :attrs)

    grid_size = height
    x_offset = grid_size + 100

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> group(&generate_grid(&1, grid_size, cell_size))
      |> group(fn g ->
        g
        |> text("Life Iterations: ", translate: {x_offset, 100}, id: :life_iteration)
        |> button("Start", translate: {x_offset, 150}, id: :start_btn)
      end)

    Server.subscribe(__MODULE__)

    state = %{
      graph: graph,
      is_started?: false,
      iteration: 0
    }

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_cast({:evolution, grid_state}, state) do
    grid_state |> IO.inspect()
    {:noreply, state}
  end

  @impl Scenic.Scene
  def filter_event({:click, :start_btn} = event, _from, state) do
    IO.puts("Start clicked")
    Server.publish()
    {:cont, event, state}
  end

  # @impl Scenic.Scene
  # def filter_event(
  #       {:click, :pause} = event,
  #       _from,
  #       %{
  #         graph: graph,
  #         grid_state: grid_state,
  #         is_started?: is_started?
  #       } = state
  #     ) do
  #   IO.inspect("Button clicked, board state is #{is_started?}")

  #   updated_grid_state = grid_state |> Map.new(fn {pos, v} -> {pos, !v} end)

  #   updated_graph =
  #     updated_grid_state
  #     |> Enum.reduce(graph, fn {{row, col}, v}, acc ->
  #       id = String.to_atom("#{row}:#{col}")
  #       fill = if v, do: :blue, else: :clear
  #       acc |> Graph.modify(id, &rectangle(&1, {@cell_size, @cell_size}, fill: fill))
  #     end)

  #   {:cont, event,
  #    %{
  #      state
  #      | graph: updated_graph,
  #        is_started?: !is_started?,
  #        grid_state: updated_grid_state
  #    }, push: updated_graph}
  # end
end
