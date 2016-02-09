
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



local Dog = {}
setmetatable(Dog, {
	__index = Animal;
})
local Dog_mt = {
	__index = Dog;
}


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
