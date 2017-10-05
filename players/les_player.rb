require_relative '../players/logic'
require_relative '../players/helper'

class LESPlayer
  attr_accessor :turn, :last_turn, :pre_determined_moves, :move_history, :status_history, :ship_counter

  include Helper
  
  def initialize
    @turn = 0
    @last_turn = nil
    @pre_determined_moves = default_moves
    @move_history = []
    @status_history = []
    @ship_counter = [5, 4, 3, 3, 2]
  end

  def name
    'Luke, Elizabeth and Stephen'
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
    unless turn.zero?
      status_history << last_move_status(state, last_turn)
    end
    
    removed = ship_counter - ships_remaining
    
    # if carrier_alive?(ships_remaining)
    #   fallback_move = pre_determined_moves.sample
    #   index = pre_determined_moves.index(fallback_move)
    #   pre_determined_moves.delete_at(index) if index
    # else
    #   fallback_move = nil
    # end
    
    # if turn == 20
    #   p move_history
    #   p status_history
    #   p turns_taken(move_history)
    #   raise 'STOP'
    # end
    
    self.turn += 1
    move = Logic.new(state, last_turn.clone, nil, removed, status_history.clone, move_history.clone).make_a_move
    move_history << move
    self.ship_counter = ships_remaining
    
    self.last_turn = move
  end
  
  def carrier_alive?(ships_array)
    ships_array.include?(5)
  end
  
  def carrier_moves
    # [
    #   [0, 1], [0, 6],
    #   [1, 2], [1, 7],
    #   [2, 3], [2, 8],
    #   [3, 4], [3, 9],
    #   [4, 5], [4, 0],
    #   [5, 6], [5, 1],
    #   [6, 7], [6, 2],
    #   [7, 8], [7, 3],
    #   [8, 9], [8, 4],
    #   [9, 0], [9, 5],
    # ]
  end

  def default_moves
    [
      [0, 1], [0, 3], [0, 5], [0, 7], [0, 9],
      [1, 0], [1, 2], [1, 4], [1, 6], [1, 8],
      [2, 1], [2, 3], [2, 5], [2, 7], [2, 9],
      [3, 0], [3, 2], [3, 4], [3, 6], [3, 8],
      [4, 1], [4, 3], [4, 5], [4, 7], [4, 9],
      [5, 0], [5, 2],         [5, 6], [5, 8],
      [6, 1], [6, 3], [6, 5], [6, 7], [6, 9],
      [7, 0], [7, 2], [7, 4], [7, 6], [7, 8],
      [8, 1], [8, 3], [8, 5], [8, 7], [8, 9],
      [9, 0], [9, 2], [9, 4], [9, 6], [9, 8]
    ]
  end
end
