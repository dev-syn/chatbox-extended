--- @module lib/ChatboxServer/Types
local Types = require(script.Parent:FindFirstChild("Types"));
type ChatChannel = Types.ChatChannel;

--- @module lib/ChatboxServer/ChatCommands/Command
local Command = require(script:FindFirstChild("Command"));

local ChatCommands = {} :: Types.ChatCommands;

ChatCommands.Prefix = "/";

ChatCommands.CommandContainer = {};

--- @module lib/ChatboxServer/init
local ChatboxExtended;
function ChatCommands.Init(chatboxExtended: Types.ChatboxExtended)
    ChatboxExtended = chatboxExtended;
end

function ChatCommands.IsCommand(name: string) : boolean
    return ChatCommands.CommandContainer[name] and true or false;
end

function ChatCommands.HandleCommand(name: string,...: any) : (boolean,...any)
    local command: Types.Command = ChatCommands.CommandContainer[name];
    if command and command.Executor then
        return true,command.Executor(...);
    end
    return false;
end

function ChatCommands.RegisterCommand(command: Types.Command)
    if ChatCommands.CommandContainer[command.Name] then
        warn("Command already exists");
        return;
    end
    ChatCommands.CommandContainer[command.Name] = command;
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