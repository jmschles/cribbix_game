defmodule CribbixGame.Deck do
  alias CribbixGame.Card

  @suits ~w(Spades Hearts Clubs Diamonds)

  def fresh_deck do
    populate_cards() |> Enum.shuffle
  end

  defp populate_cards do
    Enum.flat_map(@suits, fn suit ->
      Enum.map(~w(2 3 4 5 6 7 8 9 10 Jack Queen King Ace), fn kind ->
        %Card{
          suit: suit,
          kind: kind,
          value: get_value(kind),
          run_value: get_run_value(kind)
        }
      end)
    end)
  end

  defp get_value(kind) when kind in ~w(Jack Queen King), do: 10
  defp get_value("Ace"), do: 1
  defp get_value(kind), do: Integer.parse(kind) |> elem(0)

  defp get_run_value("Ace"), do: 1
  defp get_run_value("Jack"), do: 11
  defp get_run_value("Queen"), do: 12
  defp get_run_value("King"), do: 13
  defp get_run_value(kind), do: Integer.parse(kind) |> elem(0)
end
