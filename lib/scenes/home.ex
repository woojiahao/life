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

  @impl Scenic.Scene
  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {_, height}}} = ViewPort.info(opts[:viewport])

    %{cell_size: cell_size} = Application.get_env(:life, :attrs)

    x_offset = height + 100

    Server.subscribe(self())
    initial = Server.get_board()

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
        |> button("Reset", translate: {x_offset, 200}, id: :reset_btn)
      end)

    state = %{
      graph: graph,
      cell_size: cell_size,
      started?: false,
      x_offset: x_offset,
      alive: get_alive(initial)
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

    {:noreply, %{state | graph: updated_graph}, push: updated_graph}
  end

  @impl Scenic.Scene
  def filter_event({:click, :action_btn} = event, _, %{started?: false, alive: alive} = state) do
    IO.puts("Starting...")
    Server.set_board(alive)
    Server.start()
    {:cont, event, %{state | started?: true}}
  end

  @impl Scenic.Scene
  def filter_event({:click, :action_btn} = event, _, %{started?: true} = state) do
    IO.puts("Pausing...")
    Server.pause()
    alive = Server.get_board() |> get_alive()
    {:cont, event, %{state | started?: false, alive: alive}}
  end

  @impl Scenic.Scene
  def filter_event({:click, :reset_btn} = event, _, %{started?: started?, alive: alive} = state) do
    alive =
      unless started? do
        IO.puts("Resetting board...")
        Server.reset()
        Server.get_board() |> get_alive()
      else
        alive
      end

    {:cont, event, %{state | alive: alive}}
  end

  @impl Scenic.Scene
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        from,
        %{
          graph: graph,
          alive: alive,
          cell_size: cell_size
        } = state
      ) do
    %{id: id} = from
    %{styles: %{fill: fill}} = Graph.get!(graph, id)

    [row, col] =
      id
      |> Atom.to_string()
      |> String.split(":", trim: true)
      |> Enum.map(&String.to_integer/1)

    r = rectangle_spec({cell_size, cell_size}, fill: if(fill == @fill, do: :clear, else: @fill))
    updated_graph = Graph.modify(graph, id, &r.(&1))

    updated_alive =
      if fill == @fill do
        # If the current cell is filled, we want to unfill it and remove that from the alive list
        alive -- [{row, col}]
      else
        alive ++ [{row, col}]
      end

    {:noreply, %{state | graph: updated_graph, alive: updated_alive}, push: updated_graph}
  end

  @impl Scenic.Scene
  def handle_input(_, _, state) do
    {:noreply, state}
  end

  defp generate_grid(graph, cell_size, initial) do
    initial
    |> Enum.reduce(graph, fn {{row, col}, v}, acc ->
      id = String.to_atom("#{row}:#{col}")
      fill = if v, do: @fill, else: :clear

      # translation prioritize x (col) then y (row)
      rectangle(acc, {cell_size, cell_size},
        translate: {(col - 1) * cell_size, (row - 1) * cell_size},
        stroke: {1, :gray},
        id: id,
        fill: fill
      )
    end)
  end

  defp get_alive(board), do: board |> Enum.filter(&elem(&1, 1)) |> Enum.map(&elem(&1, 0))
end
