
-- Create a new class that inherits from a base class
--
function inheritsFrom( baseClass )

    -- The following lines are equivalent to the SimpleClass example:

    -- Create the table and metatable representing the class.
    local new_class = {}
    local class_mt = { __index = new_class }

    -- Note that this function uses class_mt as an upvalue, so every instance
    -- of the class will share the same metatable.
    --
    function new_class:create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    -- The following is the key to implementing inheritance:

    -- The __index member of the new class's metatable references the
    -- base class.  This implies that all methods of the base class will
    -- be exposed to the sub-class, and that the sub-class can override
    -- any of these methods.
    --
    if baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    return new_class
end


local function test_animal()
local Animal = {}
local Animal_mt = {
	__index = Animal;
}

function Animal.new(kind)
	local obj =  {
		kind = kind;
	}		

	setmetatable(obj, Animal_mt)
	return obj;
end


function Animal.whatKind(self)
	print(self.kind)
end



local Dog = inheritsFrom(Animal);


function Dog.new(self)
	local obj = {
		kind = "canine";
	}
	setmetatable(obj, Dog_mt)

	return obj;
end

function Dog.bark(self)
	print("I am a dog: woof!")
end

-- test
local a = Animal.new("ostrich")
a:whatKind();

local d = Dog:new()
d:whatKind();
d:bark();
end



local Path = {}
setmetatable(Path, {
    __call = function(self, ...)    -- functor
        return self:new(...);
    end,
})

function Path.new(self, params)
    local obj = params or {}
    obj._kind = "path";

    local meta = {
        __index = Path;
        Commands = {};
    }
    setmetatable(obj, meta);

    return obj;
end

function Path.addCommand(self, ins, ...)
    local tbl = getmetatable(self);
    local commands = tbl.Commands;

    -- construct the new instruction
    local res = {}
    table.insert(res,tostring(ins))
    local coords = {...};
    for _, value in ipairs(coords) do
        table.insert(res, string.format("%d",tonumber(value)))
    end

    table.insert(commands, table.concat(res, ' '));
end

function Path.toString(self)
    local tbl = getmetatable(self);
    local commands = tbl.Commands;

    return table.concat(commands);
end

-- Path construction commands
-- add a single arc segment
function Path.arcBy(self, rx, ry, rotation, large, sweep, x, y)
    self:addCommand('a', rx, ry, rotation, large, sweep, x, y)
end

function Path.arcTo(self, rx, ry, rotation, large, sweep, x, y)
    self:addCommand('A', rx, ry, rotation, large, sweep, x, y)
end

function Path.close(self)
    self:addCommand('z')
end

function Path.cubicBezierTo(self, ...)
    self:addCommand('C', ...)
end

function Path.quadraticBezierTo(self, ...)
    self:addCommand('Q', ...)
end

function Path.hLineTo(self, x, y)
    self:addCommand('H', x, y)
end

function Path.lineBy(self, x,y)
    self:addCommand('l', x, y)
end

function Path.lineTo(self, x,y)
    self:addCommand('L', x, y)
end

function Path.moveBy(self, x, y)
    self:addCommand('m', x,y)
end
function Path.moveTo(self, x, y)
    self:addCommand('M', x,y)
end

function Path.vLineTo(self, x, y)
    self:addCommand('V', x, y)
end

local function test_meta()
    local p = Path();
    p:moveTo(100,100);
    p:lineTo(300, 100);
    p:lineTo(200, 300);
    p:close();

    print(p:toString())
end

test_meta();
