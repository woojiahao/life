defmodule Life.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  @text_size 24

  defp generate_grid(graph, width, height, cell_size \\ 50) do
    Enum.reduce(0..width//cell_size, graph, fn x, acc ->
      line(acc, {{x, 0}, {x, height}}, stroke: {2, :white})
    end)
    |> then(fn g ->
      Enum.reduce(0..height//cell_size, g, fn y, acc ->
        line(acc, {{0, y}, {width, y}}, stroke: {2, :white})
      end)
    end)
  end

  def init(_, opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> generate_grid(width, height)

    {:ok, graph, push: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end
end
