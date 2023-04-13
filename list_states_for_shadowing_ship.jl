#this function returns possible states based on player move if there is shadowing ship
#Inputs are updated position of player with taken action AND non-updated position of the ship
function list_states_for_shadowing_ship(p_updated_x, p_updated_y, hs_x, hs_y, ship_type,
        game_is_done, selected_action)


    #right_down, right_up, left_down, left_up
    same_move = ["no", "no", "no", "no"]


    random_prob = 0.25/4


    #right, left, down, up
    counter =[1, 1, 1, 1]
    prob_list = [0, 0, 0, 0]


    shadowing_ship_neighbors = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done), # up
            ] 

    options =[
            get_distance(p_updated_x, p_updated_y, hs_x+1, hs_y), #right
            get_distance(p_updated_x, p_updated_y, hs_x-1, hs_y), #left
            get_distance(p_updated_x, p_updated_y, hs_x, hs_y-1), #down
            get_distance(p_updated_x, p_updated_y, hs_x, hs_y+1) #up
        ]


    s_updated_x_1 = shadowing_ship_neighbors[selected_action].s_x
    s_updated_y_1 = shadowing_ship_neighbors[selected_action].s_y
    if !inbounds(s_updated_x_1, s_updated_y_1)
        s_updated_x_1 = hs_x
        s_updated_y_1 = hs_y
    end

    #random right
    s_updated_x_1_r = shadowing_ship_neighbors[1].s_x
    s_updated_y_1_r = shadowing_ship_neighbors[1].s_y
    if !inbounds(s_updated_x_1_r, s_updated_y_1_r)
        s_updated_x_1_r = hs_x
        s_updated_y_1_r = hs_y
    end

    random_updated_right_x = s_updated_x_1_r
    random_updated_right_y = s_updated_y_1_r


    #random_left
    s_updated_x_1_l = shadowing_ship_neighbors[2].s_x
    s_updated_y_1_l = shadowing_ship_neighbors[2].s_y
    if !inbounds(s_updated_x_1_l, s_updated_y_1_l)
        s_updated_x_1_l = hs_x
        s_updated_y_1_l = hs_y
    end

    random_updated_left_x = s_updated_x_1_l
    random_updated_left_y = s_updated_y_1_l



    #random_down
    s_updated_x_1_d = shadowing_ship_neighbors[3].s_x
    s_updated_y_1_d = shadowing_ship_neighbors[3].s_y
    if !inbounds(s_updated_x_1_d, s_updated_y_1_d)
        s_updated_x_1_d = hs_x
        s_updated_y_1_d = hs_y
    end

    random_updated_down_x = s_updated_x_1_d
    random_updated_down_y = s_updated_y_1_d

    #random up
    s_updated_x_1_u = shadowing_ship_neighbors[4].s_x
    s_updated_y_1_u = shadowing_ship_neighbors[4].s_y
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

        if selected_action == 1 || selected_action == 3 #right and down

            prob_list=[0.75+(2*random_prob),random_prob, random_prob ]

        elseif selected_action == 2 #left
            prob_list=[2*random_prob, 0.75 + random_prob, random_prob]
        else #elseif selected_action == 4 #up
            prob_list=[2*random_prob, random_prob, 0.75 + random_prob]
        end




    #2. check right and up moves
    elseif [random_updated_right_x, random_updated_right_y] == [random_updated_up_x, random_updated_up_y]

        #right_and_up/ left / down
        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done)]

        if selected_action == 1 || selected_action == 4 #right and up

            prob_list=[0.75+(2*random_prob),random_prob, random_prob ]

        elseif selected_action == 2 #left
            prob_list=[2*(0.25/4), 0.75 + (0.25/4), 0.25/4]
        else #selected_action == 3 #down
            prob_list=[2*(0.25/4), 0.25/4, 0.75 + (0.25/4)]
        end


    #3. check left and down moves
    elseif [random_updated_left_x, random_updated_left_y] == [random_updated_down_x, random_updated_down_y]

        #right/ left_and_down / up

        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_up_x, random_updated_up_y, ship_type, game_is_done)]

        if selected_action == 1  #right

            prob_list=[0.75+random_prob ,2*random_prob, random_prob ]

        elseif selected_action == 2 || selected_action == 3 #left and down
            prob_list=[random_prob, 0.75 + 2*random_prob, random_prob]
        else # selected_action == 4 #up
            prob_list=[random_prob, 2*random_prob, 0.75 + random_prob]   
        end


    #4. check left and up moves
    elseif [random_updated_left_x, random_updated_left_y] == [random_updated_up_x, random_updated_up_y]

        #right/ left_and_up / down
        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done)]

        if selected_action == 1  #right

            prob_list=[0.75+random_prob ,2*random_prob, random_prob ]

        elseif selected_action == 2 || selected_action == 4 #left and up
            prob_list=[random_prob, 0.75 + 2*random_prob, random_prob]
        else #elseif selected_action == 3 #down
            prob_list=[random_prob, 2*random_prob, 0.75 + random_prob] 
        end

    else
        list_of_all_states = 
        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_up_x, random_updated_up_y, ship_type, game_is_done)]                                           

        prob_list=[random_prob , random_prob, random_prob, random_prob]
        prob_list[selected_action] = prob_list[selected_action]+0.75
    end

    #right, []


    return list_of_all_states, prob_list 
    # return [GridWorldState(p_updated_x, p_updated_y, 
    #                         s_updated_x_1, s_updated_y_1, ship_type,
    #                         game_is_done)]



end