defmodule Life do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:life, :viewport)

    %{
      cell_size: cell_size,
      evolution_rate: evolution_rate
    } = Application.get_env(:life, :attrs)

    %{size: size} = main_viewport_config

    server_opts = %{
      size: size,
      cell_size: cell_size,
      evolution_rate: evolution_rate
    }

    # start the application with the viewport
    children = [
      {Life.Server, server_opts},
      {Scenic, viewports: [main_viewport_config]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
