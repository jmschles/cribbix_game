# Is this even necessary? Probably not...

defmodule CribbixGame.Game do
  alias CribbixGame.Player
  alias CribbixGame.Round

  def create_game(name1, name2) do
    [dealer, player] = [Player.create_player(name1), Player.create_player(name2)]
    %{
      players: [dealer, player],
      current_round: Round.create_initial_round(dealer, player)
    }
  end
end
