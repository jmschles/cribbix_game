defmodule CribbixGame.Supervisor do
  use Supervisor

  def start_link({p1_name, p2_name}) do
    Supervisor.start_link(__MODULE__, {p1_name, p2_name})
  end

  def init({p1_name, p2_name}) do
    children = [
      worker(CribbixGame.Server, [{p1_name, p2_name}, CribbixGame.Server])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
