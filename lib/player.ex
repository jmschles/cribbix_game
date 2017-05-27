defmodule CribbixGame.Player do
  def remove_card(player = %{hand: hand}, card) do
    %{player | hand: hand -- [card]}
  end

  # TODO: This needs to be validated (i.e. has to be 2 cards)
  def discard(player = %{hand: hand}, discard_list) do
    new_hand = hand -- discard_list
    %{player | hand: new_hand, original_hand: new_hand}
  end

  def assign_hand(player, hand) do
    %{player | hand: hand, original_hand: hand}
  end

  def create_player(name) do
    %{name: name, hand: [], original_hand: [], old_score: 0, current_score: 0, score_data: nil}
  end
end
