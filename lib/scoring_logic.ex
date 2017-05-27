defmodule CribbixGame.ScoringLogic do
  alias CribbixGame.Utilities

  # Round => Round
  def score_hands(round = %{dealer: dealer, player: player, flipped: flipped_card}) do
    %{round |
      dealer: dealer |> score_hand(flipped_card),
      player: player |> score_hand(flipped_card)
    }
  end

  # Player, Card => Player
  def score_hand(player, flipped_card) do
    score_data = build_score_data(player.hand, flipped_card)
    %{player |
      score_data: score_data,
      old_score: current_score,
      current_score: current_score + score_data.total
    }
  end

  defp build_score_data(hand, flipped_card) do
    combined_cards = [flipped_card | hand] |> Enum.sort_by(&(&1.run_value))

    %{}
    |> add_fifteens_score(combined_cards)
    |> add_pairs_score(combined_cards)
    |> add_runs_score(combined_cards)
    |> add_flush_score(hand, flipped_card)
    |> add_nobs_score(hand, flipped_card)
    |> add_total
  end

  defp add_fifteens_score(score_map, cards) do
    %{score_map | fifteens: fifteens_score(cards)}
  end

  defp add_pairs_score(score_map, cards) do
    %{score_map | pairs: pairs_score(cards)}
  end

  defp add_runs_score(score_map, cards) do
    %{score_map | runs: runs_score(cards)}
  end

  defp add_flush_score(score_map, hand, flipped_card) do
    %{score_map | flush: flush_score(hand, flipped_card)}
  end

  defp add_nobs_score(score_map, hand, flipped_card) do
    %{score_map | nobs: nobs_score(hand, flipped_card)}
  end

  defp add_total(score_map) do
    %{score_map | total: score_map |> Map.values |> Enum.sum }
  end

  # the maths

  defp fifteens_score(cards) do
    cards
    |> Enum.map(&(&1.value))
    |> Utilities.range_combinate(2..5)
    |> Enum.filter(&(&1 |> Enum.sum == 15))
    |> Enum.count
    |> (fn x -> x * 2 end).()
  end

  defp pairs_score(cards) do
    cond do
      # maybe pointless optizmization?
      cards |> Enum.uniq_by(&(&1.kind)) == cards ->
        0
      true ->
        cards
        |> Enum.group_by(&(&1.kind))
        |> Map.values
        |> Enum.map(&length/1)
        |> Enum.filter(&(&1 > 1))
        |> Enum.map(&pair_score/1)
        |> Enum.sum
    end
  end

  defp pair_score(2), do: 2
  defp pair_score(3), do: 6
  defp pair_score(4), do: 12

  defp runs_score(cards) do
    card_run_values = cards |> Enum.map(&(&1.run_value))
    diff_set = card_run_values
      |> Enum.with_index
      |> Enum.map(fn({value, i}) -> (Enum.at(card_run_values, i + 1) || 0) - value end)
      |> Enum.drop(-1)

    scan_for_runs(diff_set)
  end

  defp scan_for_runs(list, score \\ 0, data \\ %{streak: 1, multiplier: 1, prev_zero: false}) do
    do_run_scan(list, score, data)
  end

  defp do_run_scan([], score, %{streak: streak, multiplier: multiplier, prev_zero: prev_zero}) do
    if streak >= 3, do: score + (streak * multiplier), else: score
  end

  defp do_run_scan([head|tail], score, data = %{streak: streak, multiplier: multiplier, prev_zero: prev_zero}) do
    case head do
      1 ->
        do_run_scan(tail, score, %{data | streak: streak + 1, prev_zero: false})
      0 ->
        if prev_zero, do: new_multiplier = multiplier + 1, else: new_multiplier = multiplier * 2
        do_run_scan(tail, score, %{data | multiplier: new_multiplier, prev_zero: true})
      _ ->
        if streak >= 3, do: score = score + (streak * multiplier)
        do_run_scan(tail, score, %{data | streak: 1, multiplier: 1, prev_zero: false})
    end
  end

  defp flush_score(hand, flipped_card, is_crib \\ false) do
    cond do
      four_flush(hand) && !is_crib ->
        4
      five_flush(hand, flipped_card) ->
        5
      true ->
        0
    end
  end

  defp four_flush(hand) do
    hand |> Enum.uniq_by(&(&1.suit)) == 1
  end

  defp five_flush(hand, flipped_card) do
    [flipped_card | hand] |> Enum.uniq_by(&(&1.suit)) == 1
  end

  defp nobs_score(hand, flipped_card) do
    if has_nob_jack?, do: 1, else: 0
  end

  defp has_nob_jack?(hand, flipped_card) do
    hand
    |> Enum.filter(&(&1.kind == "Jack"))
    |> Enum.map(&(&1.suit))
    |> Enum.member?(flipped_card.suit)
  end
end
