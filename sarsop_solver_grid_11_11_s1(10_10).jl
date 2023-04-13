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
