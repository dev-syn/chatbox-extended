--- @module lib/ChatboxServer/Types
local Types = require(script.Parent:FindFirstChild("Types"));
type ChatChannel = Types.ChatChannel;
type Command = Types.Command;

--- @module lib/ChatboxServer/ChatCommands/Command
local Command: Types.Schema_Command = require(script:FindFirstChild("Command"));

local ChatCommands = {} :: Types.ChatCommands;

ChatCommands.Prefix = "/";

ChatCommands.RegisteredCommands = {};

--- @module lib/ChatboxServer/init
local ChatboxExtended;
function ChatCommands.Init(chatboxExtended: Types.ChatboxExtended)
    ChatboxExtended = chatboxExtended;
end

function ChatCommands.FindCommand(queryName: string) : Command?
    for _,command: Command in ipairs(ChatCommands.RegisteredCommands) do
        if command.Name == queryName or table.find(command._Aliases,queryName) then
            return command::Command?;
        end
    end
    return nil;
end

function ChatCommands.HandleCommand(cmd: Command,...: any) : (boolean,...any)
    if cmd._Executor then
        return true,cmd._Executor(...);
    end
    return false;
end

function ChatCommands.RegisterCommand(cmd: Command)
    local registeredCommands: {Command} = ChatCommands.RegisteredCommands;
    if table.find(registeredCommands,cmd) then warn("Command already exists"); return; end
    table.insert(registeredCommands,cmd);
end

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