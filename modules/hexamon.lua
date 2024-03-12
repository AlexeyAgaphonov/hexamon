local CACHED_NEIGTHBOURS = nil
local SQRT_3 = math.sqrt(3.0)

---@class Hexamon.Orientation
---@field f0 number
---@field f1 number
---@field f2 number
---@field f3 number
---@field b0 number
---@field b1 number
---@field b2 number
---@field b3 number
---@field start_angle number

---@class Hexamon.Layout
---@field orientation Hexamon.Orientation
---@field size vector3
---@field origin vector3

---@class Hexamon.Borders
---@field left number
---@field right number
---@field top number
---@field bottom number

---@class Hexamon.Hex
---@field q number
---@field r number
---@field s number
local Hex = {}

---@return Hexamon.Hex[]
local function get_neigthbours()
    CACHED_NEIGTHBOURS = CACHED_NEIGTHBOURS or {
        Hex:new(1, 0, -1),
        Hex:new(1, -1, 0),
        Hex:new(0, -1, 1),
        Hex:new(-1, 0, 1),
        Hex:new(-1, 1, 0),
        Hex:new(0, 1, -1)
    }
    return CACHED_NEIGTHBOURS
end

---@param q number
---@param r number
---@param s number|nil
---@return Hexamon.Hex
function Hex:new(q, r, s)
    s = s or (-q - r)
    assert(q + r + s == 0, "q + r + s must be 0")
    ---@type Hexamon.Hex
    local o = {q = q, r = r, s = s or (-q - r)}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param a Hexamon.Hex
---@param b Hexamon.Hex
---@return Hexamon.Hex
function Hex.__add(a, b)
    return Hex:new(a.q + b.q, a.r + b.r, a.s + b.s)
end

---@param a Hexamon.Hex
---@param b Hexamon.Hex
---@return Hexamon.Hex
function Hex.__sub(a, b)
    return Hex:new(a.q - b.q, a.r - b.r, a.s - b.s)
end

---@param a Hexamon.Hex
---@param b Hexamon.Hex
---@return boolean
function Hex.__eq(a, b)
    return a.q == b.q and a.r == b.r and a.s == b.s
end


local M = {}

---@param q number
---@param r number
---@param s number|nil
---@return Hexamon.Hex
function M.new_hex(q, r, s)
    return Hex:new(q, r, s)
end

---@return Hexamon.Orientation
function M.new_orientation(f0, f1, f2, f3, b0, b1, b2, b3, start_angle)
    return {
        f0 = f0,
        f1 = f1,
        f2 = f2,
        f3 = f3,
        b0 = b0,
        b1 = b1,
        b2 = b2,
        b3 = b3,
        start_angle = start_angle
    }
end

---@return Hexamon.Orientation
function M.new_orientation_pointy()
    return M.new_orientation(
        SQRT_3, SQRT_3 / 2.0, 0.0, 3.0 / 2.0,
        SQRT_3 / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0, 0.5
    )
end

---@return Hexamon.Orientation
function M.new_orientation_flat()
    return M.new_orientation(
        3.0 / 2.0, 0.0, SQRT_3 / 2.0, SQRT_3,
        2.0 / 3.0, 0.0, -1.0 / 3.0, SQRT_3 / 3.0, 0.0
    )
end

---@return Hexamon.Layout
function M.new_layout(orientation, size, origin)
    local obj = {
        orientation = orientation,
        size = size,
        origin = origin
    }
    return obj
end

---@param size vector3
---@param origin vector3
---@return Hexamon.Layout
function M.new_layout_pointy(size, origin)
    return M.new_layout(M.new_orientation_pointy(), size, origin)
end

---@param size vector3
---@param origin vector3
---@return Hexamon.Layout
function M.new_layout_flat(size, origin)
    return M.new_layout(M.new_orientation_flat(), size, origin)
end


---@param hex Hexamon.Hex
---@return number
function M.length(hex)
    return (math.abs(hex.q) + math.abs(hex.r) + math.abs(hex.s)) / 2
end

---@param a Hexamon.Hex
---@param b Hexamon.Hex
---@return number
function M.distance(a, b)
    return M.length(a - b)
end

---@param direction number
function M.direction(direction)
    assert(direction > 0 and direction < 7, "direction must be between 1 and 6")
    return get_neigthbours()[direction + 1]
end

---@param hex Hexamon.Hex
---@param direction number
---@return Hexamon.Hex
function M.neigthbour(hex, direction)
    return hex + M.direction(direction)
end

---@param hex Hexamon.Hex
---@return Hexamon.Hex
function M.round(hex)
    local q = math.floor(math.floor(hex.q + 0.5))
    local r = math.floor(math.floor(hex.r + 0.5))
    local s = math.floor(math.floor(hex.s + 0.5))
    local q_diff = math.abs(q - hex.q)
    local r_diff = math.abs(r - hex.r)
    local s_diff = math.abs(s - hex.s)
    if q_diff > r_diff and q_diff > s_diff then
        q = -r - s
    elseif r_diff > s_diff then
        r = -q - s
    else
        s = -q - r
    end
    return Hex:new(q, r, s)
end

---@param layout Hexamon.Layout
---@param h Hexamon.Hex
---@return vector3
function M.hex_to_pixel(layout, h)
    orientation = layout.orientation
    local x = (orientation.f0 * h.q + orientation.f1 * h.r) * layout.size.x
    local y = (orientation.f2 * h.q + orientation.f3 * h.r) * layout.size.y
    return vmath.vector3(x + layout.origin.x, y + layout.origin.y, 0)
end

---@param layout Hexamon.Layout
---@param p vector3
---@return Hexamon.Hex
function M.pixel_to_hex(layout, p)
    orientation = layout.orientation
    local pt = vmath.vector3((p.x - layout.origin.x) / layout.size.x, (p.y - layout.origin.y) / layout.size.y, 0)
    local q = orientation.b0 * pt.x + orientation.b1 * pt.y
    local r = orientation.b2 * pt.x + orientation.b3 * pt.y
    return Hex:new(q, r, -q - r)
end

---@param layout Hexamon.Layout
---@param corner number
---@return vector3
function M.hex_corner_offset(layout, corner)
    orientation = layout.orientation
    local angle = 2.0 * math.pi * (orientation.start_angle - corner) / 6
    return vmath.vector3(layout.size.x * math.cos(angle), layout.size.y * math.sin(angle), 0)
end

---@param layout Hexamon.Layout
---@param h Hexamon.Hex
---@return Hexamon.Hex[]
function M.polygon_corners(layout, h)
    local corners = {}
    local center = M.hex_to_pixel(layout, h)
    for i = 0, 5 do
        local offset = M.hex_corner_offset(layout, i)
        table.insert(corners, vmath.vector3(center.x + offset.x, center.y + offset.y, 0))
    end
    return corners
end

---@param left number
---@param right number
---@param top number
---@param bottom number
---@return Hexamon.Borders
function M.new_borders(left, right, top, bottom)
    return {
        left = left,
        right = right,
        top = top,
        bottom = bottom
    }
end

---@param border Hexamon.Borders
---@return number
function M.offset_by_border(border)
    return math.abs(math.min(border.left, border.right, border.top, border.bottom))
end

---@param hex Hexamon.Hex
---@param offset number
---@return number
function M.cantor_encode(hex, offset)
    local q_shifted = hex.q + offset
    local r_shifted = hex.r + offset
    return (q_shifted + r_shifted) * (q_shifted + r_shifted + 1) / 2 + r_shifted
end

---@param z number
---@param offset number
---@return Hexamon.Hex
function M.cantor_decode(z, offset)
    local w = math.floor((-1 + math.sqrt(1 + 8 * z)) / 2)
    local t = (w * w + w) / 2
    local y = z - t
    local x = w - y
    return M.new_hex(x - offset, y - offset)
end

function M.foreach_hex_in_borders_flat(border, callback)
    local left = border.left
    local right = border.right
    local top = border.top
    local bottom = border.bottom
    for q = left, right do
        local q_offset = math.floor(q / 2.0)
        for r = top - q_offset, bottom - q_offset do
            callback(q, r)
        end
    end
end

return M