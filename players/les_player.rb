require_relative '../players/logic'
require_relative '../players/helper'

class LESPlayer
  attr_accessor :turn, :last_turn, :move_history, :status_history, :ship_counter

  include Helper
  
  def initialize
    @turn = 0
    @last_turn = nil
    @move_history = []
    @status_history = []
    @ship_counter = [5, 4, 3, 3, 2]
    $nearby_tracker = []
    $point_of_truth = nil
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
    
    if carrier_alive?(ships_remaining)
      fallback_move = carrier_moves.sample
      carrier_moves.delete(fallback_move)
    elsif
      fallback_move = battleship_moves.sample
      battleship_moves.delete(fallback_move)
    else
      fallback_move = default_moves.sample
      default_moves.delete(fallback_move)
    end

    # if turn == 28
    #   p move_history
    #   p status_history
    #   p turns_taken(move_history)
    #   p move_history.sort
    #   raise 'STOP'
    # end
    
    self.turn += 1
    move = Logic.new(turn, state, last_turn.clone, fallback_move, removed, status_history.clone, move_history.clone).make_a_move
    
    if state[move.last][move.first] != :unknown
      move = Logic.new(turn, state, last_turn.clone, fallback_move, removed, status_history.clone, move_history.clone).when_all_else_fails
      p "I've changed my mind due to conflicts!"
    end
    
    move_history << move
    self.ship_counter = ships_remaining
    
    self.last_turn = move
  end
  
  def more_than_n_unknowns_together(state, n)
    state.each do |row|
      counter = 0
      row.each do |cell|
        if cell == :unknown
          counter += 1
        else
          counter = 0
        end
        return counter if counter > n
      end
    end
  end
  
  def carrier_alive?(ships_array)
    ships_array.include?(5)
  end
  
  def battleship_alive?(ships_array)
    ships_array.include?(4)
  end
  
  def carrier_moves
    [
      [0, 1], [0, 6],
      [1, 2], [1, 7],
      [2, 3], [2, 8],
      [3, 4], [3, 9],
      [4, 5], [4, 0],
      [5, 6], [5, 1],
      [6, 7], [6, 2],
      [7, 8], [7, 3],
      [8, 9], [8, 4],
      [9, 0], [9, 5],
    ]
  end

  def battleship_moves
    [
      [0, 0], [0, 5], [0, 9],
      [1, 2], [1, 6],
      [2, 0], [2, 7],
      [3, 1], [3, 4], [3, 8],
      [4, 2], [4, 5], [4, 9],
      [5, 3], [5, 6],
      [6, 0], [6, 4], [6, 8],
      [7, 1], [7, 5], [7, 9],
      [8, 3], [8, 7],
      [9, 0], [9, 4], [9, 8],
    ]
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
