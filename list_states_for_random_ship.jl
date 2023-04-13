#this function returns possible states based on player move if there is hunting ship

function list_states_for_random_ship(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done)

    random_prob = 0.25

    random_ship_neighbors = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done), # up
            ] 

    no_move_state = GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done)

#     repeated_list_of_possible_states = []

#     for a_state in random_ship_neighbors
#         if !inbounds(a_state.s_x, a_state.s_y)
#             #if we uncomment this there is possiblity that ship stays in the same spot
#             #push!(repeated_list_of_possible_states, no_move_state)
#         else
#             push!(repeated_list_of_possible_states, a_state)
#         end
#     end
#     list_of_possible_states = unique(repeated_list_of_possible_states)
#     return list_of_possible_states



    #random right
    s_updated_x_1_r = random_ship_neighbors[1].s_x
    s_updated_y_1_r = random_ship_neighbors[1].s_y
    if !inbounds(s_updated_x_1_r, s_updated_y_1_r)
        s_updated_x_1_r = hs_x
        s_updated_y_1_r = hs_y
    end

    random_updated_right_x = s_updated_x_1_r
    random_updated_right_y = s_updated_y_1_r


    #random_left
    s_updated_x_1_l = random_ship_neighbors[2].s_x
    s_updated_y_1_l = random_ship_neighbors[2].s_y
    if !inbounds(s_updated_x_1_l, s_updated_y_1_l)
        s_updated_x_1_l = hs_x
        s_updated_y_1_l = hs_y
    end

    random_updated_left_x = s_updated_x_1_l
    random_updated_left_y = s_updated_y_1_l



    #random_down
    s_updated_x_1_d = random_ship_neighbors[3].s_x
    s_updated_y_1_d = random_ship_neighbors[3].s_y
    if !inbounds(s_updated_x_1_d, s_updated_y_1_d)
        s_updated_x_1_d = hs_x
        s_updated_y_1_d = hs_y
    end

    random_updated_down_x = s_updated_x_1_d
    random_updated_down_y = s_updated_y_1_d

    #random up
    s_updated_x_1_u = random_ship_neighbors[4].s_x
    s_updated_y_1_u = random_ship_neighbors[4].s_y
    if !inbounds(s_updated_x_1_u, s_updated_y_1_u)
        s_updated_x_1_u = hs_x
        s_updated_y_1_u = hs_y
    end

    random_updated_up_x = s_updated_x_1_u
    random_updated_up_y = s_updated_y_1_u




    #1. check right and down moves
    if [random_updated_right_x, random_updated_right_y] == [random_updated_down_x, random_updated_down_y]

        #right_and_down / left / up
        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_up_x, random_updated_up_y, ship_type, game_is_done)]

        prob_list=[2*random_prob,random_prob, random_prob ]


    #2. check right and up moves
    elseif [random_updated_right_x, random_updated_right_y] == [random_updated_up_x, random_updated_up_y]

        #right_and_up/ left / down
        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done)]


        prob_list=[2*random_prob,random_prob, random_prob ]



    #3. check left and down moves
    elseif [random_updated_left_x, random_updated_left_y] == [random_updated_down_x, random_updated_down_y]

        #right/ left_and_down / up

        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_up_x, random_updated_up_y, ship_type, game_is_done)]



        prob_list=[random_prob ,2*random_prob, random_prob ]




    #4. check left and up moves
    elseif [random_updated_left_x, random_updated_left_y] == [random_updated_up_x, random_updated_up_y]

        #right/ left_and_up / down
        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done)]



        prob_list=[random_prob ,2*random_prob, random_prob ]



    else
        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_up_x, random_updated_up_y, ship_type, game_is_done)]                                           

        prob_list=[random_prob , random_prob, random_prob, random_prob]

    end

    #right, []


    return list_of_all_states, prob_list 


end