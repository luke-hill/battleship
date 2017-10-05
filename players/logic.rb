class Logic
  attr_accessor :state, :last_turn
  attr_reader :fallback_move, :removed, :status_history, :move_history

  def initialize(state, last_turn, fallback_move, removed, status_history, move_history)
    @state = state
    @last_turn = last_turn
    @fallback_move = fallback_move
    @removed = removed
    @status_history = status_history
    @move_history = move_history
  end

  def make_a_move
    if turn_one?
      [5, 5]
    elsif !removed.empty? && fallback_move_unused?
      fallback_move
    elsif !removed.empty?
      [column_to_attack, least_used_row]
    elsif last_turn_hit? && valid_borders?
      attack_bordering_cell
    elsif first_rehunt?
      self.last_turn = move_history[-2]
      
      status_history.delete_at(-1)
      move_history.delete_at(-1)
      
      make_a_move
    elsif second_rehunt?
      self.last_turn = move_history[-3]
      
      2.times do
        status_history.delete_at(-1)
        move_history.delete_at(-1)
      end
      
      make_a_move
    elsif fallback_move_unused?
      fallback_move
    else
      [column_to_attack, least_used_row]
    end
  end
  
  def first_rehunt?
    status_history[-1] == :miss && status_history[-2] == :hit
  end
  
  def second_rehunt?
    status_history[-1] == :miss && status_history[-2] == :miss && status_history[-3] == :hit
  end

  def fallback_move_unused?
    fallback_move && state[fallback_move.last][fallback_move.first] == :unknown
  end

  def valid_borders?
    direction_statuses.detect { |d| d == :unknown }
  end

  def last_turn_row
    last_turn.last
  end

  def last_turn_column
    last_turn.first
  end
  
  def horizontal_statuses
    [west_of_hit_value, east_of_hit_value]
  end
  
  def horizontal_coords
    [west_of_hit, east_of_hit]
  end

  def vertical_statuses
    [north_of_hit_value, south_of_hit_value]
  end

  def vertical_coords
    [north_of_hit, south_of_hit]
  end

  def direction_statuses
    horizontal_statuses + vertical_statuses
  end

  def direction_coords
    horizontal_coords + vertical_coords
  end

  def attack_bordering_cell
    i = direction_statuses.index(:unknown)
    direction_coords[i]
  end

  def north_of_hit
    [last_turn_column, last_turn_row - 1]
  end

  def north_of_hit_value
    if north_of_hit.first.between?(0, 9) && north_of_hit.last.between?(0, 9)
      state[north_of_hit.last][north_of_hit.first]
    else
      :out_of_bounds
    end
  end

  def south_of_hit
    [last_turn_column, last_turn_row + 1]
  end

  def south_of_hit_value
    if south_of_hit.first.between?(0, 9) && south_of_hit.last.between?(0, 9)
      state[south_of_hit.last][south_of_hit.first]
    else
      :out_of_bounds
    end
  end

  def east_of_hit
    [last_turn_column + 1, last_turn_row]
  end

  def east_of_hit_value
    if east_of_hit.first.between?(0, 9) && east_of_hit.last.between?(0, 9)
      state[east_of_hit.last][east_of_hit.first]
    else
      :out_of_bounds
    end
  end

  def west_of_hit
    [last_turn_column - 1, last_turn_row]
  end

  def west_of_hit_value
    if west_of_hit.first.between?(0, 9) && west_of_hit.last.between?(0, 9)
      state[west_of_hit.last][west_of_hit.first]
    else
      :out_of_bounds
    end
  end

  def least_used_row
    counts = state.map { |rows| rows.count(:unknown) }

    counts.index(counts.max)
  end

  def column_to_attack
    row = state[least_used_row]
    # row.index(:unknown)
    row.each_index.select { |column| row[column] == :unknown }.sample
  end

  def last_turn_value
    state[last_turn_row][last_turn_column]
  end

  def last_turn_hit?
    last_turn_value == :hit
  end

  def turn_one?
    last_turn.nil?
  end
end
