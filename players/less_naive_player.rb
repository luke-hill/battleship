class LessNaivePlayer
  def initialize
    @plays = 10.times.map { |x| 10.times.map { |y| [x, y] } }.flatten(1)
  end

  def name
    "Slightly Less Naive Player"
  end

  def new_game
    [
        [5, 0, 5, :across],
        [9, 3, 4, :down],
        [5, 2, 3, :across],
        [1, 1, 3, :down],
        [5, 4, 2, :across]
    ]
  end

  def take_turn(state, ships_remaining)
    @plays.delete_at(rand(@plays.length))
  end
end
