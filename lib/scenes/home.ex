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

    self() |> IO.inspect()

    grid_size = height
    x_offset = grid_size + 100

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> group(&generate_grid(&1, grid_size, cell_size))
      |> group(fn g ->
        g
        |> text("Life Iterations: ", translate: {x_offset, 100}, id: :life_iteration)
        |> button("Start", translate: {x_offset, 150}, id: :start_btn)
        |> button("Stop", translate: {x_offset, 200}, id: :stop_btn)
      end)

    Server.subscribe(self())

    state = %{
      graph: graph,
      iteration: 0,
      cell_size: cell_size
    }

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_cast({:evolution, evolution}, %{graph: graph, cell_size: cell_size} = state) do
    updated_graph =
      evolution
      |> Enum.reduce(graph, fn {{row, col}, v}, acc ->
        id = String.to_atom("#{row}:#{col}")
        fill = if v, do: :blue, else: :clear
        acc |> Graph.modify(id, &rectangle(&1, {cell_size, cell_size}, fill: fill))
      end)

    {:noreply, state, push: updated_graph}
  end

  @impl Scenic.Scene
  def filter_event({:click, :start_btn} = event, _from, state) do
    IO.puts("Start clicked")
    Server.start()
    {:cont, event, state}
  end

  @impl Scenic.Scene
  def filter_event({:click, :stop_btn} = event, _from, state) do
    IO.puts("Stop clicked")
    Server.stop()
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
