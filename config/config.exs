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

# Config to contain the additional configurations
# cell_size: size of the cells in the grid
# evolution_rate: rate at which the next evolution will propagate, useful for slowing down the speed of graphic (in ms)
# pattern: pre-determined patten to visualize such as :blinker, :beacon, :pulsar, :toad
# TODO: Allow for user customized patterns
config :life, :attrs, %{
  cell_size: 80,
  evolution_rate: 300,
  pattern: :toad
}

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "prod.exs"
