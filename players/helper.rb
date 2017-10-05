module Helper
  def last_move_status(state, last_turn)
    column, row = last_turn
    state[row][column]
  end
  
  def turns_taken(history)
    history.length
  end
end
