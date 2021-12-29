defmodule Life.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Life.Server

  import Scenic.Primitives
  import Scenic.Components

  @text_size 24
  @fill :black

  defp generate_grid(graph, cell_size, initial) do
    initial
    |> Enum.reduce(graph, fn {{row, col}, v}, acc ->
      id = String.to_atom("#{row}:#{col}")
      fill = if v, do: @fill, else: :clear

      # translation prioritize x (col) then y (row)
      rectangle(acc, {cell_size, cell_size},
        translate: {(col - 1) * cell_size, (row - 1) * cell_size},
        stroke: {1, :black},
        id: id,
        fill: fill
      )
    end)
  end

  @impl Scenic.Scene
  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {_, height}}} = ViewPort.info(opts[:viewport])

    %{cell_size: cell_size} = Application.get_env(:life, :attrs)

    x_offset = height + 100

    Server.subscribe(self())
    initial = Server.get_initial()

    graph =
      Graph.build(font: :roboto, font_size: @text_size, clear_color: :white)
      |> group(&generate_grid(&1, cell_size, initial))
      |> group(fn g ->
        g
        |> text("Life Iterations: 0",
          translate: {x_offset, 100},
          id: :life_iteration,
          fill: :black
        )
        |> button("Start/Pause", translate: {x_offset, 150}, id: :action_btn)
      end)

    state = %{
      graph: graph,
      cell_size: cell_size,
      started?: false,
      x_offset: x_offset
    }

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_cast(
        {:evolution, {evolution, iteration}},
        %{graph: graph, cell_size: cell_size} = state
      ) do
    updated_graph =
      evolution
      |> Enum.reduce(graph, fn {{row, col}, v}, acc ->
        id = String.to_atom("#{row}:#{col}")
        fill = if v, do: @fill, else: :clear
        acc |> Graph.modify(id, &rectangle(&1, {cell_size, cell_size}, fill: fill))
      end)
      |> then(fn g ->
        g |> Graph.modify(:life_iteration, &text(&1, "Life iteration: #{iteration}"))
      end)

    {:noreply, state, push: updated_graph}
  end

  @impl Scenic.Scene
  def filter_event({:click, :action_btn} = event, _, %{started?: false} = state) do
    IO.puts("Starting...")
    Server.start()
    {:cont, event, %{state | started?: true}}
  end

  @impl Scenic.Scene
  def filter_event({:click, :action_btn} = event, _, %{started?: true} = state) do
    IO.puts("Pausing...")
    Server.pause()
    {:cont, event, %{state | started?: false}}
  end
end
