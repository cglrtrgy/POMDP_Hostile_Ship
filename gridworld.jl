#This is how we hold information for the states 
struct GridWorldState 
    p_x::Int64 # x position of the player
    p_y::Int64 # y position of the player
    s_x::Int64 # x position of the ship
    s_y::Int64 # y position of the ship
    s_type::String #shadow #hunt #random
    done::Bool # are we in a terminal state?
end

#same with state except observation doesn't have info about ship types
struct GridWorldObs
    p_x::Int64 # x position of the player
    p_y::Int64 # y position of the player
    s_x::Int64 # x position of the player
    s_y::Int64 # y position of the player
    done::Bool # are we in a terminal state?
end