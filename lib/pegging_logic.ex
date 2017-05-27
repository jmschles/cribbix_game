defmodule CribbixGame.PeggingLogic do
  def play_attempt(round, card) do
    with {:ok, round, card} <- legal_play(round, card),
         {:ok, round} <- play_card({:ok, round, card}) do
      {:ok, round}
    else
      {:error, error} -> "error: #{error}"
    end

    # old implementation
    # round |> legal_play(card) |> play_card
  end

  # Round => Round
  def play_card({:ok, round, card}) do
    round = round
      |> add_card_to_played_list(card)
      |> check_and_add_scores

    cond do
      round |> round_over? ->
        # send some kinda signal back up, like a :done flag?
        {:ok, %{round | done: true}}
      round |> inactive_player_can_play? ->
        {:ok, round |> toggle_active_player}
      round |> nobody_can_play? ->
        # give active player a point for go, reset played stack
        round = round |> add_score(1) |> update_score
        {:ok, %{round | played: []}}
      true ->
        # inactive player can't play but active one still can
        {:ok, round}
    end
  end

  def play_card({:error, _}) do
    raise "some great error handling here"
  end

  # Round => Round
  defp check_and_add_scores(round = %{played: played}) do
    round
    |> fifteen_check
    |> run_check
    |> pairs_check
    |> thirty_one_check
    |> update_score
  end

  # TODO: we don't actually care who played them, do we?
  # played = [
  #   {%{name: "Bob"}, %{run_value: 9}},
  #   {%{name: "Sally"}, %{run_value: 6}},
  #   {%{name: "Bob"}, %{run_value: 8}},
  #   {%{name: "Sally"}, %{run_value: 10}}
  # ]

  defp fifteen_check(round) do
    if count(round) == 15, do: add_score(round, 2), else: round
  end

  defp thirty_one_check(round) do
    if count(round) == 31, do: add_score(round, 2), else: round
  end

  defp pairs_check(round = %{played: played_list}) do
    reversed_card_kinds = played_list
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&(&1.kind))
      |> Enum.reverse
    pair_score = check_for_pairs(reversed_card_kinds)
    if pair_score, do: add_score(round, pair_score), else: round
  end

  defp check_for_pairs(card_kind_list, size \\ 2, pair_found \\ false) do
    cond do
      size > length(card_kind_list) ->
        if (pair_found), do: pair_score(size - 1), else: false
      card_kind_list |> Enum.take(size) |> is_pairy? ->
        check_for_pairs(card_kind_list, size + 1, true)
      true ->
        if (pair_found), do: pair_score(size - 1), else: false
    end
  end

  defp is_pairy?(hand_segment) do
    length(hand_segment |> Enum.uniq) == length(hand_segment)
  end

  defp pair_score(2), do: 2
  defp pair_score(3), do: 6
  defp pair_score(4), do: 12

  defp run_check(round = %{played: played_list}) do
    reversed_card_values = played_list
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&(&1.run_value))
      |> Enum.reverse
    run_score = check_for_runs(reversed_card_values)
    if run_score, do: add_score(round, run_score), else: round
  end

  defp check_for_runs(card_value_list, size \\ 3, run_found \\ false) do
    cond do
      size > length(card_value_list) ->
        if (run_found), do: size - 1, else: false
      card_value_list |> Enum.take(size) |> is_a_run? ->
        check_for_runs(card_value_list, size + 1, true)
      true ->
        if (run_found), do: size - 1, else: false
    end
  end

  defp is_a_run?(list_segment) do
    list_segment
    |> Enum.sort
    |> Enum.with_index
    |> Enum.map(fn({value, i}) -> (Enum.at(list_segment, i + 1) || 0) - value end)
    |> Enum.drop(-1)
    |> Enum.all?(fn n -> n == 1 end)
  end

  # Round => Integer
  defp count(%{played: played_list}) do
    played_list
    |> Enum.map(&elem(&1, 1))
    |> Enum.reduce(0, fn(card, sum) -> sum + card.value end)
  end

  # Round => Round
  defp add_score(round = %{active_player: active_player}, points) do
    active_player = %{
      active_player |
        old_score: active_player.current_score,
        current_score: active_player.current_score + points
    }
    %{round | active_player: active_player}
  end

  # Round => Round
  defp update_score(round = %{active_player: active_player, dealer: dealer}) when active_player == dealer do
    new_dealer = %{ dealer | old_score: active_player.old_score, current_score: active_player.current_score }
    %{ round | dealer: new_dealer }
  end

  defp update_score(round = %{active_player: active_player, player: player}) when active_player == player do
    new_player = %{ player | old_score: active_player.old_score, current_score: active_player.current_score }
    %{ round | player: new_player }
  end

  # Round => Round
  defp toggle_active_player(round = %{active_player: active_player, inactive_player: inactive_player}) do
    %{
      round |
        active_player: inactive_player,
        inactive_player: active_player
    }
  end

  # Round => Boolean
  defp inactive_player_can_play?(round = %{played: played_list, inactive_player: inactive_player}) do
    inactive_player.hand |> Enum.any?(fn card -> count(round) + card.value <= 31 end)
  end

  # Round => Boolean
  defp nobody_can_play?(round = %{played: played_list}) do
    (round |> count == 31) ||
    !(round |> combined_hands |> Enum.any?(fn card -> count(round) + card.value <= 31 end))
  end

  # Round => Boolean
  defp round_over?(round) do
    round |> combined_hands |> Enum.empty?
  end

  defp combined_hands(%{active_player: active_player, inactive_player: inactive_player}) do
    inactive_player.hand ++ active_player.hand
  end

  defp legal_play(round = %{active_player: %{hand: hand}}, card) do
    cond do
      !(hand |> Enum.member?(card)) ->
        {:error, "that... where did that card come from?"}
      (count(round) + card.value <= 31) ->
        {:ok, round, card}
      true ->
        {:error, "can't play that card"}
    end
  end

  defp add_card_to_played_list(round = %{played: played_list, active_player: active_player}, card) do
    active_player = %{active_player | hand: active_player.hand -- [card]}
    %{round | played_list: played_list ++ [{active_player, card}], active_player: active_player}
  end
end
