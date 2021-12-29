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

    cur = init_board(cell_count, pattern)

    state = %{
      cur: cur,
      cell_count: cell_count,
      iteration: 0,
      evolution_rate: evolution_rate,
      pattern: pattern,
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

  def reset() do
    GenServer.cast(__MODULE__, :reset)
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

  @impl true
  def handle_cast(:reset, %{cell_count: cell_count, pattern: pattern} = state) do
    cur = init_board(cell_count, pattern)
    GenServer.cast(__MODULE__, {:notify_subscribers, :evolution, {cur, 0}})
    {:noreply, %{state | cur: cur, iteration: 0, timer: nil}}
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

    # Evolution happens simultaneously, so we don't need to use the previous state to calculate
    evolved =
      cur
      |> Map.new(fn {{row, col}, s} ->
        alive =
          generate_neighbors(row, col, cell_count)
          |> Enum.map(fn {r, c} -> cur[{r, c}] end)
          |> Enum.filter(& &1)

        {{row, col}, determine_state(s, alive)}
      end)

    GenServer.cast(__MODULE__, {:notify_subscribers, :evolution, {evolved, updated_iteration}})

    timer = Process.send_after(self(), :evolve, evolution_rate)

    {:noreply, %{state | cur: evolved, timer: timer, iteration: updated_iteration}}
  end

  defp init_board(cell_count, pattern) do
    for(row <- 1..cell_count, col <- 1..cell_count, do: {{row, col}, false})
    |> Map.new()
    |> Life.Server.PatternGenerator.create_pattern(pattern)
  end

  defp in_board(row, col, max), do: row >= 1 and row <= max and col >= 1 and col <= max

  defp generate_neighbors(row, col, max) do
    [
      {row, col - 1},
      {row, col + 1},
      {row - 1, col},
      {row + 1, col},
      {row - 1, col - 1},
      {row - 1, col + 1},
      {row + 1, col - 1},
      {row + 1, col + 1}
    ]
    |> Enum.filter(fn {r, c} -> in_board(r, c, max) end)
  end

  defp determine_state(true, alive) when length(alive) in 2..3, do: true
  defp determine_state(true, _), do: false
  defp determine_state(false, alive) when length(alive) == 3, do: true
  defp determine_state(false, _), do: false
end
