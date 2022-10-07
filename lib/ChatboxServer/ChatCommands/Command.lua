--- @module lib/ChatboxServer/Types
local Types = require(script.Parent.Parent:FindFirstChild("Types"));
type Command = Types.Command;

local Command = {} :: Types.Schema_Command;
Command.__index = Command;
Command.ClassName = "Command";

function Command.new(name: string,executor: () -> () | (...any) -> ...any,aliases: {string}?) : Command
    local self = {} :: Types.Object_Command;
    self.Name = name:lower();
    self.Aliases = aliases;
    self.Executor = executor;
    return setmetatable(self,Command) :: Command;
end

return Command;