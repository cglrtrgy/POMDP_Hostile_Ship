# first import the POMDPs.jl interface
using POMDPs
# POMDPModelTools has tools that help build the MDP definition
using POMDPModelTools
# POMDPPolicies provides functions to help define simple policies
using POMDPPolicies
# POMDPSimulators provide functions for running MDP simulations
using POMDPSimulators
using QuickPOMDPs, POMDPSimulators, QMDP
using SARSOP
using JLD2
using BeliefUpdaters
using Random
using FiniteHorizonPOMDPs


#list to create all combinations for the state list
state_combination_list = 
["shadow","hunt", "random"]

#empty list for states
s = GridWorldState[]

#size of the grids
size_x=11
size_y=11

# t=0 ---> shadowing, t =1 --> hunting
for ship_type in state_combination_list
    for d = 0:1, 
        p_x = 1:size_x, p_y = 1:size_y, 
        s_1_x = 1:size_x, s_1_y = 1:size_y
        push!(s, GridWorldState(p_x, p_y, 
                                s_1_x, s_1_y, ship_type,               
                                d))
    end
end


#Terminal States
function isterminal_func(s::GridWorldState)
    if s.done==true
        return true
    else
        return false
    end
end


#possible actions
actions = [:up, :down, :left, :right, :predict]


#Observation SPACE

o = GridWorldObs[]


for d = 0:1,  p_y = 1:size_y, p_x = 1:size_x, s_y = 1:size_y, s_x = 1:size_x
    push!(o, GridWorldObs(p_x, p_y, s_x, s_y,d))
end

observation_list = o

discount = 0.95

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

#     probability = fill(0.0, 4)

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





#this function returns possible states based on player move if there is hunting ship
#Inputs are updated position of player AND non-updated position of the ship
#No need to pass action bc hunting ship will try to get closer to player ship always

function list_states_for_hunting_ship(p_updated_x, p_updated_y, hs_x, hs_y, ship_type,
         game_is_done)


    random_prob = 0.25/4


    hunting_ship_neighbors = [
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

    available_neighbors = [
                            inbounds(hunting_ship_neighbors[1].s_x,hunting_ship_neighbors[1].s_y),
                            inbounds(hunting_ship_neighbors[2].s_x,hunting_ship_neighbors[2].s_y),
                            inbounds(hunting_ship_neighbors[3].s_x,hunting_ship_neighbors[3].s_y),
                            inbounds(hunting_ship_neighbors[4].s_x,hunting_ship_neighbors[4].s_y)
        ]

#     println(available_neighbors)

    min_direction = minimum(options)
    min_index_list = [i for (i, x) in enumerate(options) if x == min_direction]

#     println(min_index_list)

    # there can be maximum two direction which results the biggest distance reduction (cases: up/down-left/right)
    # if for length(min_index_list)
    if length(min_index_list) == 2

        #1. if min_distance happens with right and down
        if min_index_list[1] == 1 && min_index_list[2]==3
            if available_neighbors[2] == 1 && available_neighbors[4] == 1

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[(0.75/2) + random_prob, random_prob, (0.75/2) + random_prob, random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)

            elseif available_neighbors[2] == 1 && available_neighbors[4] == 0

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done)
            ] 
                prob_list=[(0.75/2) + random_prob, random_prob, (0.75/2) + random_prob, random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)

            elseif available_neighbors[2] == 0 && available_neighbors[4] == 1

                list_of_all_states = [ 
                    GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
                    GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
                    GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
                    GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
                    ] 
                prob_list=[(0.75/2) + random_prob, random_prob, (0.75/2) + random_prob, random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)


            elseif available_neighbors[2] == 0 && available_neighbors[4] == 0

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done) # down
            ] 
                prob_list=[(0.75/2) + random_prob, 2*random_prob, (0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            end




        #2. if min_distance happens with right and up
        elseif min_index_list[1] == 1 && min_index_list[2]==4

            #if both left and down are inbounds
            if available_neighbors[2] == 1 && available_neighbors[3] == 1

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[(0.75/2) + random_prob, random_prob,  random_prob, (0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            #if left is in bounds but not down
            elseif available_neighbors[2] == 1 && available_neighbors[3] == 0

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[(0.75/2) + random_prob, random_prob,  random_prob, (0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            #if left is not in bounds but down
            elseif available_neighbors[2] == 0 && available_neighbors[3] == 1

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[(0.75/2) + random_prob, random_prob, random_prob, (0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))


            #if both left and down are not in bounds
            elseif available_neighbors[2] == 0 && available_neighbors[3] == 0

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done), # up
            ] 
                prob_list=[(0.75/2) + random_prob, 2*random_prob, (0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))
            end

        #3. if min_distance happens with left and down
        elseif min_index_list[1] == 2 && min_index_list[2]==3

            #if both right and up are inbounds
            if available_neighbors[1] == 1 && available_neighbors[4] == 1

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[random_prob, (0.75/2) + random_prob, (0.75/2) + random_prob, random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            #if right is in bounds but not up
            elseif available_neighbors[1] == 1 && available_neighbors[4] == 0

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done) # stay
            ] 
                prob_list=[random_prob,(0.75/2) + random_prob, (0.75/2) + random_prob, random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            #if right is not in bounds but up
            elseif available_neighbors[1] == 0 && available_neighbors[4] == 1

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[random_prob, (0.75/2) + random_prob, (0.75/2) + random_prob,  random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))


            #if both right and up are not in bounds
            elseif available_neighbors[1] == 0 && available_neighbors[4] == 0

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            ] 


                prob_list=[2*random_prob, (0.75/2) + random_prob, (0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            end

        #4. if min_distance happens with left and up
        elseif min_index_list[1] == 2 && min_index_list[2]==4

            #if both right and down are inbounds
            if available_neighbors[1] == 1 && available_neighbors[3] == 1

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[random_prob, (0.75/2) + random_prob, random_prob,(0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            #if right is in bounds but not down
            elseif available_neighbors[1] == 1 && available_neighbors[3] == 0

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x+1, hs_y, ship_type, game_is_done), # right
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[random_prob,(0.75/2) + random_prob, random_prob,(0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            #if right is not in bounds but down
            elseif available_neighbors[1] == 0 && available_neighbors[3] == 1

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y-1, ship_type, game_is_done), # down
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 
                prob_list=[random_prob, (0.75/2) + random_prob, random_prob,(0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))


            #if both right and down are not in bounds
            elseif available_neighbors[1] == 0 && available_neighbors[3] == 0

                list_of_all_states = [
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y, ship_type, game_is_done), # stay
            GridWorldState(p_updated_x, p_updated_y, hs_x-1, hs_y, ship_type, game_is_done), # left
            GridWorldState(p_updated_x, p_updated_y, hs_x, hs_y+1, ship_type, game_is_done) # up
            ] 


                prob_list=[2*random_prob, (0.75/2) + random_prob, (0.75/2) + random_prob]

#                 println(list_of_all_states)
#                 println(prob_list)
#                 println(sum(prob_list))

            end


        end

        s_updated_x_1 = hunting_ship_neighbors[min_index_list[1]].s_x
        s_updated_y_1 = hunting_ship_neighbors[min_index_list[1]].s_y

        #if hunting ships goes beyond boundries, stay at the same location
        if !inbounds(s_updated_x_1, s_updated_y_1)
            s_updated_x_1 = hs_x
            s_updated_y_1 = hs_y
        end

        s_updated_x_2 = hunting_ship_neighbors[min_index_list[2]].s_x
        s_updated_y_2 = hunting_ship_neighbors[min_index_list[2]].s_y

        #if hunting ships goes beyond boundries, stay at the same location
        if !inbounds(s_updated_x_1, s_updated_y_1)
            s_updated_x_2 = hs_x
            s_updated_y_2 = hs_y
        end

#         return [GridWorldState(p_updated_x, p_updated_y, s_updated_x_1, s_updated_y_1, ship_type,
#                                                     game_is_done),
#                 GridWorldState(p_updated_x, p_updated_y, s_updated_x_2, s_updated_y_2, ship_type,
#                                                     game_is_done)]

    #if there is only one direction which result the biggest distance closure or 4
    else
        #random right
        s_updated_x_1_r = hunting_ship_neighbors[1].s_x
        s_updated_y_1_r = hunting_ship_neighbors[1].s_y
        if !inbounds(s_updated_x_1_r, s_updated_y_1_r)
            s_updated_x_1_r = hs_x
            s_updated_y_1_r = hs_y
        end

        random_updated_right_x = s_updated_x_1_r
        random_updated_right_y = s_updated_y_1_r


        #random_left
        s_updated_x_1_l = hunting_ship_neighbors[2].s_x
        s_updated_y_1_l = hunting_ship_neighbors[2].s_y
        if !inbounds(s_updated_x_1_l, s_updated_y_1_l)
            s_updated_x_1_l = hs_x
            s_updated_y_1_l = hs_y
        end

        random_updated_left_x = s_updated_x_1_l
        random_updated_left_y = s_updated_y_1_l



        #random_down
        s_updated_x_1_d = hunting_ship_neighbors[3].s_x
        s_updated_y_1_d = hunting_ship_neighbors[3].s_y
        if !inbounds(s_updated_x_1_d, s_updated_y_1_d)
            s_updated_x_1_d = hs_x
            s_updated_y_1_d = hs_y
        end

        random_updated_down_x = s_updated_x_1_d
        random_updated_down_y = s_updated_y_1_d

        #random up
        s_updated_x_1_u = hunting_ship_neighbors[4].s_x
        s_updated_y_1_u = hunting_ship_neighbors[4].s_y
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

            if length(min_index_list) == 1
                if min_index_list[1] == 1 || min_index_list[1] == 3 #right and down

                    prob_list=[0.75+(2*random_prob),random_prob, random_prob ]

                elseif min_index_list[1] == 2 #left
                    prob_list=[2*random_prob, 0.75 + random_prob, random_prob]
                else #elseif selected_action == 4 #up
                    prob_list=[2*random_prob, random_prob, 0.75 + random_prob]
                end
            else
                prob_list=[2*0.25, 0.25, 0.25]
            end

#             println(list_of_all_states)
#             println(prob_list)
#             println(sum(prob_list))


        [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
        GridWorldState(p_updated_x, p_updated_y, random_updated_up_x, random_updated_up_y, ship_type, game_is_done)]
                prob_list=[random_prob, 0.75+(2*random_prob), random_prob ]


        #2. check right and up moves
        elseif [random_updated_right_x, random_updated_right_y] == [random_updated_up_x, random_updated_up_y]

            #right_and_up/ left / down
            list_of_all_states = 
            [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done)]

            if length(min_index_list) == 1
                if min_index_list[1] == 1 || min_index_list[1] == 4 #right and up

                    prob_list=[0.75+(2*random_prob),random_prob, random_prob ]

                elseif min_index_list[1] == 2 #left
                    prob_list=[2*(0.25/4), 0.75 + (0.25/4), 0.25/4]
                else #selected_action == 3 #down
                    prob_list=[2*(0.25/4), 0.25/4, 0.75 + (0.25/4)]
                end
            else
                prob_list=[2*0.25,0.25, 0.25 ]

            end

#             println(list_of_all_states)
#             println(prob_list)
#             println(sum(prob_list))


        #3. check left and down moves
        elseif [random_updated_left_x, random_updated_left_y] == [random_updated_down_x, random_updated_down_y]

            #right/ left_and_down / up

            list_of_all_states = 
            [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_up_x, random_updated_up_y, ship_type, game_is_done)]

            if length(min_index_list) == 1
                if min_index_list[1] == 1  #right

                    prob_list=[0.75+random_prob ,2*random_prob, random_prob ]

                elseif min_index_list[1] == 2 || min_index_list[1] == 3 #left and down
                    prob_list=[random_prob, 0.75 + 2*random_prob, random_prob]
                else # selected_action == 4 #up
                    prob_list=[random_prob, 2*random_prob, 0.75 + random_prob]   
                end
            else
                prob_list=[0.25 ,2*0.25, 0.25]
            end


#             println(list_of_all_states)
#             println(prob_list)
#             println(sum(prob_list))


        #4. check left and up moves
        elseif [random_updated_left_x, random_updated_left_y] == [random_updated_up_x, random_updated_up_y]

            #right/ left_and_up / down
            list_of_all_states = 
            [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done)]

            if length(min_index_list) == 1
                if min_index_list[1] == 1  #right

                    prob_list=[0.75+random_prob ,2*random_prob, random_prob ]

                elseif min_index_list[1] == 2 || min_index_list[1] == 4 #left and up
                    prob_list=[random_prob, 0.75 + 2*random_prob, random_prob]
                else #elseif selected_action == 3 #down
                    prob_list=[random_prob, 2*random_prob, 0.75 + random_prob] 
                end
            else
                prob_list=[0.25 ,2*0.25, 0.25 ]
            end


#             println(list_of_all_states)
#             println(prob_list)
#             println(sum(prob_list))

        else
            list_of_all_states = 
            [GridWorldState(p_updated_x, p_updated_y, random_updated_right_x, random_updated_right_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_left_x, random_updated_left_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_down_x, random_updated_down_y, ship_type, game_is_done),
            GridWorldState(p_updated_x, p_updated_y, random_updated_up_x, random_updated_up_y, ship_type, game_is_done)]                                           

            if length(min_index_list) == 1
                prob_list=[random_prob , random_prob, random_prob, random_prob]
                prob_list[min_index_list[1]] = prob_list[min_index_list[1]]+0.75
            else
                prob_list=[0.25 , 0.25, 0.25, 0.25]

            end

#             println(list_of_all_states)
#             println(prob_list)
#             println(sum(prob_list))



        end






        s_updated_x = hunting_ship_neighbors[min_index_list[1]].s_x
        s_updated_y = hunting_ship_neighbors[min_index_list[1]].s_y
        if !inbounds(s_updated_x, s_updated_y)
            s_updated_x = hs_x
            s_updated_y = hs_y 
        end
#         return [GridWorldState(p_updated_x, p_updated_y, s_updated_x, s_updated_y, ship_type,
#         game_is_done)]

    # end of if for length(min_index_list)
    end

    return list_of_all_states, prob_list

end

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
#     return [GridWorldState(p_updated_x, p_updated_y, 
#                             s_updated_x_1, s_updated_y_1, ship_type,
#                             game_is_done)]



end

#Initial States
initialstate_function= Uniform([GridWorldState(6, 6, 10, 10, "shadow", false), 
        GridWorldState(6, 6, 10, 10, "hunt", false),
        GridWorldState(6, 6, 10, 10, "random", false)])



#this is only for ship_1, we are gonna have the same for the other ships
hostile_ship_1 = QuickPOMDP(
    states = s,

    actions = actions,
    #obstype = GridWorldState,
    observations = observation_list,
    initialstate = initialstate_function,
    discount = 0.95,

    transition = transition_function,

    observation = observation_function,

    reward = reward_function,


    isterminal = isterminal_func
)

#horizon length = 10 since 35/4=8.75
fhsh = fixhorizon(hostile_ship_1, 10)

solver = SARSOPSolver()
# solver = QMDPSolver(max_iterations=25,
#                     verbose=true)
# #POMCPOW -- online solver: this keeps gettting updated as time passes
# #BasicPOMCP 
policy = solve(solver, fhsh)



save("sarsop_finite_s1_pos_10_10.jld2", "policy", policy)
