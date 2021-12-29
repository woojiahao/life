import Config

# Configure the main viewport for the Scenic application
config :life, :viewport, %{
  name: :main_viewport,
  size: {1200, 800},
  default_scene: {Life.Scene.Home, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "life"]
    }
  ]
}

import_config "attrs.exs"
