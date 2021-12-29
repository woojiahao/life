import Config

# Config to contain the additional configurations
# cell_size: size of the cells in the grid
# evolution_rate: rate at which the next evolution will propagate, useful for slowing down the speed of graphic (in ms)
# pattern: pre-determined patten to visualize such as :blinker, :beacon, :pulsar, :toad, and :empty
# TODO: Allow for user customized patterns
config :life, :attrs, %{
  cell_size: 20,
  evolution_rate: 100,
  pattern: :pulsar
}
