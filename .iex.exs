alias DerbyLive.Repo

alias DerbyLive.Account
alias DerbyLive.Account.User
alias DerbyLive.Racing
alias DerbyLive.Racing.{Event, Racer, RacerHeat}

IEx.configure(
  inspect: [limit: :infinity, pretty: true],
  history_size: 1000
)
