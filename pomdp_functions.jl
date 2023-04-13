#Terminal States
function isterminal_func(s::GridWorldState)
    if s.done==true
        return true
    else
        return false
    end
end

function observation_function(a, sp)


    possible_actions = Dict(:right=>1, :left=>2, :down=>3, :up=>4, :predict=>5)
    selected_action = possible_actions[a]

    p_x = sp.p_x
    p_y = sp.p_y
    s_x = sp.s_x
    s_y = sp.s_y
    ship_type = sp.s_type
    game_is_done = sp.done 

    #return SparseCat, otherwise solver doesn't work -- maybe Uniform does work also?
    return SparseCat([GridWorldObs(p_x, p_y, s_x, s_y, game_is_done)], [1.0])

end

function reward_function(s, a)
    possible_actions = Dict(:right=>1, :left=>2, :down=>3, :up=>4, :predict=>5)
    selected_action = possible_actions[a]
    if selected_action == 5
        if s.s_type == "hunt" || s.s_type == "shadow"
            return 50
        else
            return -100
        end
    else
        return -1
    end
end

function transition_function(state::GridWorldState, action::Symbol)

    ##Current state info
    a = action

    p_x = state.p_x
    p_y = state.p_y

    s_x = state.s_x
    s_y = state.s_y
    ship_type = state.s_type

    game_is_done = state.done


    #player position updates based on selected action/move
    player_neighbors = [
        GridWorldState(p_x+1, p_y, s_x, s_y, ship_type,  game_is_done), # right
        GridWorldState(p_x-1, p_y, s_x, s_y, ship_type,  game_is_done), # left
        GridWorldState(p_x, p_y-1, s_x, s_y, ship_type,  game_is_done), # down
        GridWorldState(p_x, p_y+1, s_x, s_y, ship_type,  game_is_done), # up
        ] 



    possible_actions = Dict(:right=>1, :left=>2, :down=>3, :up=>4, :predict=>5)
    selected_action = possible_actions[a]

    # probability = fill(0.0, 4)

    #if action is not predict, in other words, if acton is move up,down,right or left    
    if selected_action == 1 || selected_action == 2 || selected_action == 3 || selected_action == 4 

        p_updated_x = player_neighbors[selected_action].p_x
        p_updated_y = player_neighbors[selected_action].p_y

        is_player_inbounds = inbounds(p_updated_x, p_updated_y )

        if !is_player_inbounds
            p_updated_x = p_x
            p_updated_y = p_y

        end



        if ship_type == "shadow" #shadowing

            list_of_all_possible_states, list_of_probas = list_states_for_shadowing_ship(p_updated_x, p_updated_y, 
                                                        s_x, s_y, ship_type,
                                                        game_is_done, selected_action)
        elseif ship_type == "hunt" #hunting

            list_of_all_possible_states, list_of_probas = list_states_for_hunting_ship(p_updated_x, p_updated_y, 
                                                        s_x, s_y, ship_type,
                                                        game_is_done)
        else #random
            list_of_all_possible_states, list_of_probas = list_states_for_random_ship(p_updated_x, p_updated_y, 
                                                        s_x, s_y, ship_type,
                                                        game_is_done)

        end





        return SparseCat(list_of_all_possible_states, list_of_probas)


    else #if action is predict
        return SparseCat([GridWorldState(p_x, p_y, s_x, s_y, ship_type, true)], [1.0])

    end

end