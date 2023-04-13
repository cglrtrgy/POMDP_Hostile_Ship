include("list_states_for_random_ship.jl")
include("gridworld.jl")
include("helper_functions.jl")


println("Random Ship transition: ")

list_of_states_random, list_of_probas_random = list_states_for_random_ship(5,7, 11, 10, "random", false)
for (x,y) in zip(list_of_states_random, list_of_probas_random)
    println(x,y)
end

println("Total Probability: ", sum(list_of_probas_random))
