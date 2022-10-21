--- @module ChatboxExtended/lib/Types
local Types = require(script.Parent.Parent:FindFirstChild("Types"));
type Command = Types.Command;

--[=[
    @class Command

    This class is built to be used with [ChatCommands].
]=]
local Command = {} :: Types.Schema_Command;
Command.__index = Command;
--[=[
    @prop __type "Command"
    @within Command

    The __type property of the [Command] class.
]=]
Command.__type = "Command";
--[=[
    @prop ClassName "Command"
    @within Command

    The class name property of the [Command] class.
]=]
Command.ClassName = "Command";

--[=[
    @within Command

    This function creates a new Command object.
]=]
function Command.new<Command>(name: string,executor: (sender: Player,...any) -> ...any,aliases: {string}?) : Command
    local self = {} :: Types.Object_Command;
    self.Name = name:lower();
    self._Aliases = aliases;
    self._Executor = executor;
    return setmetatable(self,Command) :: Command;
end

return Command;