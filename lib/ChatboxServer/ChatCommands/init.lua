--- @module lib/Types
local Types = require(script.Parent.Parent:FindFirstChild("Types"));
type ChatChannel = Types.ChatChannel;
type Command = Types.Command;

--- @module lib/ChatboxServer/ChatCommands/Command
local Command = require(script:FindFirstChild("Command")) :: Types.Schema_Command;

--[=[
    @class ChatCommands
    This class was designed to create and handle commands used in the chat with ChatboxExtended.
]=]
local ChatCommands = {} :: Types.ChatCommands;

--[=[
    @prop Prefix string
    @within ChatCommands
    This is the prefix used to recognize commands by default this represents '/'.
]=]
ChatCommands.Prefix = "/";

--[=[
    @prop _RegisteredCommands {Command}
    @within ChatCommands
    @private
    This is an internal table which contains an array of Command objects.
]=]
ChatCommands._RegisteredCommands = {};

--- @module lib/ChatboxServer/init
local ChatboxExtended;
--[=[
    @param chatboxExtended ChatboxExtendedServer -- The ChatboxExtended class
    This is an internal initial' which is called to set a reference for ChatboxExtended.
]=]
function ChatCommands.Init(chatboxExtended: Types.ChatboxExtendedServer)
    ChatboxExtended = chatboxExtended;
end

--[=[
    @within ChatCommands
    This method is for finding a command that was registered with it's name.
]=]
function ChatCommands.FindCommand(queryName: string) : Command?
    for _,command: Command in ipairs(ChatCommands._RegisteredCommands) do
        if command.Name == queryName or table.find(command._Aliases,queryName) then
            return command::Command?;
        end
    end
    return nil;
end

--[=[
    @within ChatCommands
    @param cmd Command -- The command to be handled
    @param ... any -- The arguments that get sent to the command executor
    @return boolean -- Returns true if the command executor gets called or false if no executor was found
    @return ...any -- Returns a tuple of any results returned from the command executor
    This method is used to execute a command with the args passed.
]=]
function ChatCommands.HandleCommand(cmd: Command,...: any) : (boolean,...any)
    if cmd._Executor then
        return true,cmd._Executor(...);
    end
    return false;
end

--[=[
    This method registers a command object to ChatCommands allowing it to be used in the ChatboxExtended chat.
]=]
function ChatCommands.RegisterCommand(cmd: Command)
    local registeredCommands: {Command} = ChatCommands._RegisteredCommands;
    if table.find(registeredCommands,cmd) then warn("Command already exists"); return; end
    table.insert(registeredCommands,cmd);
end

--[=[
    This method is for loading default commands for the ChatboxExtended chat.
]=]
function ChatCommands.LoadDefaultCommands()
    -- Test command
    ChatCommands.RegisterCommand(Command.new("test",function(sender: Player)
        if ChatboxExtended then
            local generalChannel: ChatChannel = ChatboxExtended.GetChannel("General");
            if generalChannel then
                generalChannel:PostNotification(generalChannel.Notification.SERVER,"Test command was called");
            end
        end
    end));
end

return ChatCommands;