#31 x 31, function to check whether ships are in the grid
function inbounds(x::Int64,y::Int64)
    if 1 <= x <= 11 && 1 <= y <= 11
        return true
    else
        return false
    end
end

#distance function
function get_distance(p_x::Int64,p_y::Int64, s_x::Int64,s_y::Int64)
    return abs(p_x - s_x) + abs(p_y - s_y)
end