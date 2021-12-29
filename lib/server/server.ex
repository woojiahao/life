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
    # TODO: Add rate of evolution to attrs
    IO.puts("Initializing evolution server")

    Agent.start_link(fn -> MapSet.new() end, name: :subscribers)

    cells = for row <- 0..height//cell_size, col <- 0..height//cell_size, do: {row, col}
    cur = cells |> Map.new(fn pos -> {pos, false} end)

    state = %{
      cur: cur,
      iteration: 0,
      timer: nil
    }

    {:ok, state}
  end

  def subscribe(pid) do
    IO.puts("Subscribed to #{__MODULE__}")
    GenServer.cast(__MODULE__, {:subscribe, pid})
  end

  def unsubscribe(pid) do
    IO.puts("Unsubscribed from #{__MODULE__}")
    GenServer.cast(__MODULE__, {:unsubscribe, pid})
  end

  def start() do
    IO.puts("Starting evolution")
    GenServer.cast(__MODULE__, {:evolve, :start})
  end

  def stop() do
    IO.puts("Stopping evolution")
    GenServer.cast(__MODULE__, {:evolve, :stop})
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    Agent.get_and_update(:subscribers, fn s -> {s, MapSet.put(s, pid)} end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:unsubscribe, pid}, state) do
    Agent.get_and_update(:subscribers, fn s -> {s, MapSet.delete(s, pid)} end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:evolve, :stop}, %{timer: timer} = state) do
    Process.cancel_timer(timer, async: false, info: true)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:evolve, :start}, state) do
    Process.send(self(), :evolve, [:noconnect])
    {:noreply, state}
  end

  @impl true
  def handle_cast({:notify_subscribers, event, data}, state) do
    IO.puts("Notifying all subscribers in #{__MODULE__}")

    Agent.get(:subscribers, fn s -> s end)
    |> Enum.each(&GenServer.cast(&1, {event, data}))

    {:noreply, state}
  end

  # This function is responsible for the evolution pattern
  @impl true
  def handle_info(:evolve, %{cur: cur, iteration: iteration} = state) do
    IO.puts("Evolving")

    # Based on the iteration, update the state differently

    evolved =
      cur
      |> Enum.reduce(cur, fn {{row, col}, s}, acc ->
        Map.update(acc, {row, col}, s, &(!&1))
      end)

    GenServer.cast(__MODULE__, {:notify_subscribers, :evolution, {evolved, iteration + 1}})

    timer = Process.send_after(self(), :evolve, 1_000)

    {:noreply, %{state | cur: evolved, timer: timer, iteration: iteration + 1}}
  end
end
