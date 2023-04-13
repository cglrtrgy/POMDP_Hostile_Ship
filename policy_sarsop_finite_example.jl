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

import POMDPModels

include("gridworld.jl")
include("list_states_for_random_ship.jl")   
include("list_states_for_hunting_ship.jl")
include("list_states_for_shadowing_ship.jl")

include("helper_functions.jl")
include("pomdp_functions.jl")

#list to create all combinations for the state list
state_combination_list = 
["shadow","hunt", "random"]

#empty list for states
s = GridWorldState[]

#size of the grids
size_x=4
size_y=4

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



#possible actions
actions = [:up, :down, :left, :right, :predict]


#Observation SPACE

o = GridWorldObs[]


for d = 0:1,  p_y = 1:size_y, p_x = 1:size_x, s_y = 1:size_y, s_x = 1:size_x
    push!(o, GridWorldObs(p_x, p_y, s_x, s_y,d))
end

observation_list = o

discount = 0.95


#Initial States
initialstate_function= Uniform([GridWorldState(3, 3, 2, 2, "shadow", false), 
        GridWorldState(3, 3, 2, 2, "hunt", false),
        GridWorldState(3, 3, 2, 2, "random", false)])



#this is only for ship_1, we are gonna have the same for the other ships
hostile_ship_inf_horizon = QuickPOMDP(
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
fin_horizion_sh = fixhorizon(hostile_ship_inf_horizon, 2)

println("Horizon length: ", horizon(fin_horizion_sh))

println(transition_function)

solver = SARSOPSolver()
# solver = QMDPSolver(max_iterations=25,
#                     verbose=true)
# #BasicPOMCP 
policy = solve(solver, fin_horizion_sh)


# save("finite_s1_pos_2_2.jld2", "policy_test", policy)
