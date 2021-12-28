defmodule Life.Server do
  @moduledoc """
  This is the server that handles the mutations of the board.

  Grid state will be a matrix represented as a dictionary of the given grid size with a boolean state denoting if it is
  on/off.
  """

  use GenServer

  def start_link(opts) do
    IO.puts("Starting evolution server")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(%{size: {_, height}, cell_size: cell_size}) do
    IO.puts("Initializing evolution server")

    cells = for row <- 0..height//cell_size, col <- 0..height//cell_size, do: {row, col}
    server_state = cells |> Map.new(fn pos -> {pos, false} end)
    Agent.start_link(fn -> server_state end, name: :server_state)

    {:ok, MapSet.new()}
  end

  def subscribe(pid) do
    IO.puts("#{pid} subscribed to #{__MODULE__}")
    GenServer.cast(__MODULE__, {:subscribe, pid})
  end

  def unsubscribe(pid) do
    IO.puts("#{pid} unsubscribed from #{__MODULE__}")
    GenServer.cast(__MODULE__, {:unsubscribe, pid})
  end

  def publish() do
    IO.puts("Publishing evolution from server #{__MODULE__}")
    Process.alive?(self()) |> IO.inspect()

    s = Agent.get(:server_state, fn s -> s end)
    GenServer.call(__MODULE__, {:notify_subscribers, :evolution, s})
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    MapSet.put(state, pid) |> IO.inspect()
    {:noreply, MapSet.put(state, pid)}
  end

  @impl true
  def handle_cast({:unsubscribe, pid}, state) do
    {:noreply, MapSet.delete(state, pid)}
  end

  @impl true
  def handle_call({:notify_subscribers, event, data}, _from, state) do
    IO.puts("Notifying all subscribers in #{__MODULE__}")

    state |> IO.inspect() |> Enum.each(&GenServer.cast(&1, {event, data}))

    {:reply, state, state}
  end
end
