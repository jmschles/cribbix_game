# Start the supervisor with player names
{:ok, pid} = CribbixGame.Supervisor.start_link({"Phil", "Sally"})

# Call the server to play a "card"
GenServer.call(CribbixGame.Server, {:play_card, card})

# Check state
GenServer.call(CribbixGame.Server, :check_state)

# Test a discard
GenServer.call(CribbixGame.Server, {:discard, cards})

# Stop the supervisor
Supervisor.stop(pid)


# Need cards? Got cards.
cards = [%{suit: "Hearts", value: 4, kind: "4"}, %{suit: "Spades", value: 2, kind: "2"}, %{suit: "Hearts", value: 8, kind: "8"}, %{suit: "Clubs", value: 3, kind: "3"}, %{suit: "Diamonds", value: 3, kind: "3"}]
cards = [%{suit: "Hearts", value: 8, kind: "8"}, %{suit: "Spades", value: 8, kind: "8"}, %{suit: "Hearts", value: 8, kind: "8"}, %{suit: "Clubs", value: 3, kind: "3"}, %{suit: "Diamonds", value: 3, kind: "3"}]
cards = [%{suit: "Hearts", run_value: 3, kind: "3"}, %{suit: "Spades", run_value: 4, kind: "4"}, %{suit: "Diamonds", run_value: 4, kind: "4"}, %{suit: "Hearts", run_value: 5, kind: "5"}, %{suit: "Clubs", run_value: 5, kind: "5"}]
