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


include("list_states_for_random_ship.jl")   
include("list_states_for_hunting_ship.jl")
include("list_states_for_shadowing_ship.jl")
include("gridworld.jl")
include("helper_functions.jl")

include("pomdp_functions.jl")

#size of the grids
size_x=11
size_y=11

println("Random Ship transition: ")

list_of_states_random, list_of_probas_random = list_states_for_random_ship(5,7, 11, 10, "random", false)
for (x,y) in zip(list_of_states_random, list_of_probas_random)
    println(x,y)
end

println("Total Probability: ", sum(list_of_probas_random))


println("Hunting Ship transition: ")
list_of_states_random, list_of_probas_random = list_states_for_hunting_ship(4, 4, 4, 4, "hunt", false)
for (x,y) in zip(list_of_states_random, list_of_probas_random)
    println(x,y)
end
println("Total Probability: ", sum(list_of_probas_random))


println("Shadowing Ship transition: ")
list_of_states_shadowing, list_of_probas_shadowing = list_states_for_shadowing_ship(10, 11, 11, 11, "shadow",false, 3)
for (x,y) in zip(list_of_states_shadowing, list_of_probas_shadowing)
    println(x,y)
end
println("Total Probability: ", sum(list_of_probas_shadowing))


println("All transition functions together: ")
for action in [:right, :left, :down, :up, :predict]
    for ship_type in ["shadow", "hunt", "random"]
        for i=1:2, j=1:2, k=1:2, l=1:2
    
        println(ship_type," ", action,[i,j,k,l])
        display(transition_function(GridWorldState(i,j,k,l,ship_type, false), action))#3
        end
    end
end
