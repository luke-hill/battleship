module Helper
  def last_move_status(state, last_turn)
    column, row = last_turn
    state[row][column]
  end
  
  def turns_taken(history)
    history.length
  end
  
  def adjoin?(coord_one, coord_two)
    x, y = coord_one
    xx, yy = coord_two
    
    xx == x && ((yy - y).abs == 1) ||
      yy == y && ((xx - x).abs == 1)
  end
  
  def valid?(move)
    x, y = move
    x.between?(0, 9) && y.between?(0, 9)
  end
end
