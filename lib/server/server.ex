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
  def init(%{
        size: {_, height},
        cell_size: cell_size,
        evolution_rate: evolution_rate,
        pattern: pattern
      }) do
    IO.puts("Initializing evolution server")

    Agent.start_link(fn -> MapSet.new() end, name: :subscribers)

    cell_count = div(height, cell_size)

    cur =
      for(row <- 1..cell_count, col <- 1..cell_count, do: {{row, col}, false})
      |> Map.new()
      |> create_pattern(pattern)

    state = %{
      cur: cur,
      cell_count: cell_count,
      iteration: 0,
      evolution_rate: evolution_rate,
      timer: nil
    }

    {:ok, state}
  end

  # Adds target pid to subscriptions
  def subscribe(pid) do
    IO.puts("Subscribed to #{__MODULE__}")
    GenServer.cast(__MODULE__, {:subscribe, pid})
  end

  # Removes target pid from subscriptions
  def unsubscribe(pid) do
    IO.puts("Unsubscribed from #{__MODULE__}")
    GenServer.cast(__MODULE__, {:unsubscribe, pid})
  end

  # Starts evolution cycle
  def start() do
    IO.puts("Starting evolution")
    GenServer.cast(__MODULE__, {:evolve, :start})
  end

  def pause() do
    IO.puts("Pausing evolution")
    GenServer.cast(__MODULE__, {:evolve, :pause})
  end

  # Retrieves initial grid pattern
  def get_initial() do
    IO.puts("Retrieving initial grid pattern")
    GenServer.call(__MODULE__, :initial)
  end

  @impl true
  def handle_call(:initial, _, %{cur: cur} = state) do
    {:reply, cur, state}
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
  def handle_cast({:evolve, :pause}, %{timer: timer} = state) do
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
    Agent.get(:subscribers, fn s -> s end)
    |> Enum.each(&GenServer.cast(&1, {event, data}))

    {:noreply, state}
  end

  # This function is responsible for the evolution pattern
  @impl true
  def handle_info(
        :evolve,
        %{
          cur: cur,
          cell_count: cell_count,
          iteration: iteration,
          evolution_rate: evolution_rate
        } = state
      ) do
    # Based on the iteration, update the state differently

    updated_iteration = iteration + 1

    evolved =
      cur
      |> Enum.reduce(cur, fn {{row, col}, s}, acc ->
        Map.update(acc, {row, col}, s, fn _ ->
          r = rem(updated_iteration, cell_count)
          c = if r == 0, do: cell_count, else: r

          row == c or col == c
        end)
      end)

    GenServer.cast(__MODULE__, {:notify_subscribers, :evolution, {evolved, updated_iteration}})

    timer = Process.send_after(self(), :evolve, evolution_rate)

    {:noreply, %{state | cur: evolved, timer: timer, iteration: updated_iteration}}
  end

  defp create_pattern(cells, :blinker) do
    # blinker is a type of oscillator
    IO.puts("Creating blinker pattern")

    cells
    |> Map.new(fn {{row, col}, _} ->
      if row == 3 and col in 2..4,
        do: {{row, col}, true},
        else: {{row, col}, false}
    end)
  end

  defp create_pattern(cells, _), do: cells
end
