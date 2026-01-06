defmodule DerbyLive.Racing do
  @moduledoc """
  The Racing domain handles derby events, racers, and heat results.

  This domain uses Ash Framework for declarative resource management.
  """
  use Ash.Domain

  resources do
    resource(DerbyLive.Racing.Event)
    resource(DerbyLive.Racing.Racer)
    resource(DerbyLive.Racing.RacerHeat)
  end
end
