defmodule CribbixGame.Utilities do

  @doc """
  Gets all combinations of a list whose lengths are within range
  ## Example
  CribbixGame.Utilities.range_combinate([1,2,3,4], 2..3)
  [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4],[1,2,3],[1,3,4],[1,2,4],[2,3,4]]
  """
  def range_combinate(list, range) do
    range |> Enum.flat_map(fn k -> combine(list, k) end)
  end

  # https://github.com/seantanly/elixir-combination/blob/master/lib/combination.ex
  defp combine(list, k) do
    do_combine(list, length(list), k, [], [])
  end

  defp do_combine(_list, _list_length, 0, _pick_acc, _acc), do: [[]]
  defp do_combine(list, _list_length, 1, _pick_acc, _acc), do: list |> Enum.map(&([&1]))
  defp do_combine(list, list_length, k, pick_acc, acc) do
    list
    |> Stream.unfold(fn [h | t] -> {{h, t}, t} end)
    |> Enum.take(list_length)
    |> Enum.reduce(acc, fn {x, sublist}, acc ->
      sublist_length = Enum.count(sublist)
      pick_acc_length = Enum.count(pick_acc)
      if k > pick_acc_length + 1 + sublist_length do
        acc # insufficient elements in sublist to generate new valid combinations
      else
        new_pick_acc = [x | pick_acc]
        new_pick_acc_length = pick_acc_length + 1
        case new_pick_acc_length do
          ^k -> [new_pick_acc | acc]
          _  -> do_combine(sublist, sublist_length, k, new_pick_acc, acc)
        end
      end
    end)
  end
end
