require_relative '../players/helper'

class Logic
  attr_accessor :state, :last_turn, :reassign_pot
  attr_reader :fallback_move, :removed, :status_history, :move_history, :turn

  include Helper
  
  def initialize(turn, state, last_turn, fallback_move, removed, status_history, move_history)
    @turn = turn
    @state = state
    @last_turn = last_turn
    @fallback_move = fallback_move
    @removed = removed
    @status_history = status_history
    @move_history = move_history
    @rehunt = false
    @reassign_pot = true
  end

  def make_a_move
    #$nearby_tracker = []
    if last_turn_hit?
      save_coords_of_bordering_unknowns
      
      sanitize_nearby_tracker
      $nearby_tracker = $nearby_tracker.uniq.sort #returns sanitized array (should always be shorter)
    elsif last_turn
      ($nearby_tracker - last_turn).uniq.sort
    end
    
    if !removed.empty?
      $point_of_truth = nil
    elsif last_turn_hit? && reassign_pot
      $point_of_truth ||= last_turn
    end

    if turn_one?
      [5, 4]
    elsif !removed.empty? && $nearby_tracker.any?
      $nearby_tracker.delete($nearby_tracker.sample)
    elsif !removed.empty? && fallback_move_unused? #If you kill, go random
      fallback_move
    elsif !removed.empty? #If you kill, go random
      when_all_else_fails
    # elsif two_hits_in_row_then_miss? && $point_of_truth #We have kept going in a line, we know where the ship is, so we're turning around now!
    #   x, y = $point_of_truth #turn around then continue in the opposite direction
    #   request =
    #   if go_right?
    #     [x - 1, y] # Go left this time! TRUST ME!
    #   elsif go_left?
    #     [x + 1, y] # Go right this time! TRUST ME!
    #   elsif go_down?
    #     [x, y - 1] # Go up this time! TRUST ME!
    #   else
    #     [x, y + 1] # Go down this time! TRUST ME!
    #   end
    #   if valid?(request)
    #     request
    #   else
    #     when_all_else_fails
    #   end
    elsif number_of_hits > 1 && go_right? && last_turn_hit? && !@rehunt #2 or more hits, last hit was RIGHT of one before, NOT IN REHUNT
      # p 'right rehunt'
      x, y = last_turn
      request = [x + 1, y]

      while valid?(request) && hit?(request)
        new_x, new_y = request
        request = [new_x + 1, new_y]
      end
      
      if valid?(request) && unknown?(request)
        request
      elsif $nearby_tracker.any?
        # p 'nearby tracker usage'
        $nearby_tracker.delete($nearby_tracker.sample)
      elsif fallback_move_unused?
        fallback_move
      else
        when_all_else_fails
      end
    elsif number_of_hits > 1 && go_left? && last_turn_hit? && !@rehunt #2 or more hits, last hit was LEFT of one before, NOT IN REHUNT
      # p 'left rehunt'
      x, y = last_turn
      request = [x - 1, y]

      while valid?(request) && hit?(request)
        new_x, new_y = request
        request = [new_x - 1, new_y]
      end
      
      if valid?(request) && unknown?(request)
        request
      elsif $nearby_tracker.any?
        # p 'nearby tracker usage'
        $nearby_tracker.delete($nearby_tracker.sample)
      elsif fallback_move_unused?
        fallback_move
      else
        when_all_else_fails
      end
    elsif number_of_hits > 1 && go_down? && last_turn_hit? && !@rehunt #2 or more hits, last hit was DOWN of one before, NOT IN REHUNT
      # p 'down rehunt'
      x, y = last_turn
      request = [x, y + 1]

      while valid?(request) && hit?(request)
        new_x, new_y = request
        request = [new_x, new_y + 1]
      end
      
      if valid?(request) && unknown?(request)
        request
      elsif $nearby_tracker.any?
        # p 'nearby tracker usage'
        $nearby_tracker.delete($nearby_tracker.sample)
      elsif fallback_move_unused?
        fallback_move
      else
        when_all_else_fails
      end
    elsif number_of_hits > 1 && go_up? && last_turn_hit? && !@rehunt #2 or more hits, last hit was UP of one before, NOT IN REHUNT
      # p 'up rehunt'
      x, y = last_turn
      request = [x, y - 1]
      
      while valid?(request) && hit?(request)
        new_x, new_y = request
        request = [new_x, new_y - 1]
      end
      
      if valid?(request) && unknown?(request)
        request
      elsif $nearby_tracker.any?
        # p 'nearby tracker usage'
        $nearby_tracker.delete($nearby_tracker.sample)
      elsif fallback_move_unused?
        fallback_move
      else
        when_all_else_fails
      end
    elsif last_turn_hit? && valid_borders? #Guess which cell to fire on
      # p 'border attack'
      attack_bordering_cell
    elsif first_rehunt? #Try again to guess which cell to fire on
      #p 'first rehunt'
      @rehunt = true
      self.last_turn = move_history[-2]
      
      status_history.delete_at(-1)
      move_history.delete_at(-1)
      
      self.reassign_pot = false
      make_a_move
    elsif second_rehunt? #Try again (3rd time lucky) to guess which cell to fire on
      # p 'second rehunt'
      @rehunt = true
      self.last_turn = move_history[-3]
      
      2.times do
        status_history.delete_at(-1)
        move_history.delete_at(-1)
      end
      
      self.reassign_pot = false
      make_a_move
    elsif third_rehunt? #Ok you suck, this time get it right
      # p 'third rehunt'
      @rehunt = true
      self.last_turn = move_history[-4]

      3.times do
        status_history.delete_at(-1)
        move_history.delete_at(-1)
      end

      self.reassign_pot = false
      make_a_move
    elsif late_game? && !$nearby_tracker.any?
      when_all_else_fails
    elsif $nearby_tracker.any?
      # p 'nearby tracker usage'
      $nearby_tracker.delete($nearby_tracker.sample)
    elsif fallback_move_unused? #If I have any pre-determined moves left, use them now
      # p 'fallback'
      fallback_move
    else #Random move based off Bayes Theorem
      # p 'random'
      when_all_else_fails
    end
  end
  
  def go_right?
    horizontal_difference_of_last_two_hits == -1 && vertical_difference_of_last_two_hits.zero?
  end
  
  def go_left?
    horizontal_difference_of_last_two_hits == +1 && vertical_difference_of_last_two_hits.zero?
  end
  
  def go_up?
    vertical_difference_of_last_two_hits == +1 && horizontal_difference_of_last_two_hits.zero?
  end
  
  def go_down?
    vertical_difference_of_last_two_hits == -1 && horizontal_difference_of_last_two_hits.zero?
  end
  
  def horizontal_difference_of_last_two_hits
    first_hit, second_hit = last_two_hits
    first_hit.first - second_hit.first
  end

  def vertical_difference_of_last_two_hits
    first_hit, second_hit = last_two_hits
    first_hit.last - second_hit.last
  end
  
  def last_two_hits
    second_to_last_hit_index = indices_of_each_hit[-2]
    last_hit_index = indices_of_each_hit[-1]
    second_to_last_coords = move_history[second_to_last_hit_index]
    last_coords = move_history[last_hit_index]
    [second_to_last_coords, last_coords]
  end
  
  def coords_of_each_hit
    indices_of_each_hit.map do |index|
      move_history[index]
    end
  end
  
  def number_of_hits
    status_history.count(:hit)
  end
  
  def indices_of_each_hit
    a = []
    status_history.each_index do |index|
      a << index if status_history[index] == :hit
    end
    a
  end
  
  def two_hits_in_row_then_miss?
    status_history[-1] == :miss && status_history[-2] == :hit && status_history[-3] == :hit
  end
  
  def first_rehunt?
    (status_history[-1] == :miss && status_history[-2] == :hit) &&
      adjoin?(move_history[-1], move_history[-2])
  end
  
  def second_rehunt?
    status_history[-1] == :miss && status_history[-2] == :miss && status_history[-3] == :hit &&
      adjoin?(move_history[-1], move_history[-3]) &&
      adjoin?(move_history[-2], move_history[-3])
  end
  
  def third_rehunt?
    status_history[-1] == :miss && status_history[-2] == :miss &&
      status_history[-3] == :miss && status_history[-4] == :hit &&
      adjoin?(move_history[-1], move_history[-4]) &&
      adjoin?(move_history[-2], move_history[-4]) &&
      adjoin?(move_history[-3], move_history[-4])
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
  
  def save_coords_of_bordering_unknowns
    direction_coords.each_with_index do |coord, index|
      if direction_statuses[index] == :unknown
        $nearby_tracker << coord
      end
    end
  end
  
  def sanitize_nearby_tracker
    $nearby_tracker.uniq.sort.each do |coord|
      $nearby_tracker.delete(coord) unless unknown?(coord)
    end
  end

  def north_of_hit
    [last_turn_column, last_turn_row - 1]
  end

  def north_of_hit_value
    if valid?(north_of_hit)
      state[north_of_hit.last][north_of_hit.first]
    else
      :out_of_bounds
    end
  end

  def south_of_hit
    [last_turn_column, last_turn_row + 1]
  end

  def south_of_hit_value
    if valid?(south_of_hit)
      state[south_of_hit.last][south_of_hit.first]
    else
      :out_of_bounds
    end
  end

  def east_of_hit
    [last_turn_column + 1, last_turn_row]
  end

  def east_of_hit_value
    if valid?(east_of_hit)
      state[east_of_hit.last][east_of_hit.first]
    else
      :out_of_bounds
    end
  end

  def west_of_hit
    [last_turn_column - 1, last_turn_row]
  end

  def west_of_hit_value
    if valid?(west_of_hit)
      state[west_of_hit.last][west_of_hit.first]
    else
      :out_of_bounds
    end
  end
  
  def unattacked_cells_per_row
    state.map { |rows| rows.count(:unknown) }
  end

  def least_used_row
    unattacked_cells_per_row.index(unattacked_cells_per_row.max)
  end

  def column_to_attack
    row = state[least_used_row]
    row.each_index.select { |column| row[column] == :unknown }.sample
  end

  def last_turn_value
    state[last_turn_row][last_turn_column]
  end

  def last_turn_hit?
    last_turn && last_turn_value == :hit
  end

  def turn_one?
    last_turn.nil?
  end
  
  def late_game?
    turn >= 25
  end
  
  def when_all_else_fails
    [column_to_attack, least_used_row]
  end
  
  def unknown?(coord)
    x, y = coord
    state[y][x] == :unknown
  end

  def hit?(coord)
    x, y = coord
    state[y][x] == :hit
  end
end
