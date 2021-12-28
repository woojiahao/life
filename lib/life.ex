defmodule Life do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:life, :viewport)
    %{cell_size: cell_size} = Application.get_env(:life, :attrs)

    %{size: size} = main_viewport_config

    # start the application with the viewport
    children = [
      {Life.Server, %{size: size, cell_size: cell_size}},
      {Scenic, viewports: [main_viewport_config]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
