defmodule CribbixGame.Round do
  alias CribbixGame.Deck
  alias CribbixGame.Player
  alias CribbixGame.PeggingLogic
  alias CribbixGame.ScoringLogic

  def play_card(round, card) do
    cond round |> PeggingLogic.play_attempt(card) do
      {:ok, round = %{done: true}} ->
        round |> ScoringLogic.score_hands
      {:ok, round} ->
        round
      {:error, error} ->
        error
    end
  end

  def handle_discard(round, discard_list) do
    round
    |> build_crib(discard_list)
    |> set_initial_active_player
    |> flip
  end

  # {String, String} => Round
  def create_initial_round(p1_name, p2_name) do
    [dealer, player] = create_players(p1_name, p2_name)
    %{
      deck: Deck.fresh_deck(),
      dealer: dealer,
      player: player,
      crib: nil,
      flipped: nil,
      played: [],
      active_player: player,
      inactive_player: dealer
    }
    |> assign_hands
  end

  def create_subsequent_round(round = %{dealer: dealer, player: player}) do
    new_dealer = %{player |> score_data: nil}
    new_player = %{dealer |> score_data: nil}
    %{
      round |
        dealer: new_dealer,
        player: new_player,
        deck: Deck.fresh_deck()
        crib: nil,
        flipped: nil,
        played: [],
        active_player: new_player,
        inactive_player: new_dealer
    } |> assign_hands
  end

  defp create_players(p1_name, p2_name) do
    [
      Player.create_player(p1_name),
      Player.create_player(p2_name)
    ] |> Enum.shuffle
  end

  #Round, List<Cards> => Round
  defp build_crib(round = %{dealer: dealer, player: player}, discard_list) do
    %{
      round |
        dealer: dealer |> Player.discard(discard_list),
        player: player |> Player.discard(discard_list),
        crib: discard_list
     }
  end

  defp flip(round = %{deck: [flipped | _]}) do
    %{
      round |
        deck: nil, # we shouldn't need it anymore
        flipped: flipped
    }
  end

  # Round => {List<Cards>, Round}
  defp create_hand(round = %{deck: deck}) do
    {hand, new_deck} = deck |> Enum.split(6)
    {hand, %{round | deck: new_deck}}
  end

  defp set_initial_active_player(round = %{dealer: dealer, player: player}) do
    %{ round | active_player: player, inactive_player: dealer }
  end

  defp check_for_jack_flip(round = %{dealer: dealer, flipped: flipped}) do
    cond do
      flipped.kind == "Jack" ->
        happier_dealer = %{dealer |
          old_score: dealer.current_score,
          current_score: dealer.current_score + 2
        }
        %{round | dealer: happier_dealer}
      true ->
        round
    end
  end

  # Round => Round
  defp assign_hands(round = %{dealer: dealer, player: player}) do
    {player_hand, round} = create_hand(round)
    {dealer_hand, round} = create_hand(round)
    %{
      round |
        dealer: %{dealer | hand: dealer_hand},
        player: %{player | hand: player_hand},
    }
  end
end
