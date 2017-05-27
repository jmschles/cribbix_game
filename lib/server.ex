defmodule CribbixGame.Server do
  use GenServer
  alias CribbixGame.Round

  # Client API

  def start_link({p1_name, p2_name}, name) do
    GenServer.start_link(__MODULE__, {p1_name, p2_name}, name: name)
  end

  def discard(server, cards) do
    GenServer.call(server, {:discard, cards})
  end

  def play_card(server, card) do
    GenServer.call(server, {:play_card, card})
  end

  def check_state(server) do
    GenServer.call(server, :check_state)
  end

  # Server stuff

  def init({p1_name, p2_name}) do
    {:ok, Round.create_initial_round(p1_name, p2_name)}
  end

  def handle_call({:discard, cards}, _from, round) do
    new_round = round |> Round.handle_discard(cards)
    IO.inspect(new_round)
    {:reply, new_round, new_round}
  end

  def handle_call({:play_card, card}, _from, round) do
    IO.inspect(round)
    {:reply, card, round}
  end

  def handle_call(:check_state, _from, round) do
    IO.inspect(round)
    {:reply, round, round}
  end
end
