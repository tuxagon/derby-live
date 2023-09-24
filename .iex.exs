import Ecto.Query

alias DerbyLive.Repo

alias DerbyLive.Account
alias DerbyLive.Account.User
alias DerbyLive.Racing
alias DerbyLive.Racing.{Event, Racer, RacerHeat, Heat, Lane}

IEx.configure(
  inspect: [limit: :infinity, pretty: true],
  history_size: 1000
)
