local Types = require(script:FindFirstChild("Types"));
type ChatChannel = Types.ChatChannel;

local function outWarn(level: number?,...: string)
    if level then
        warn("[ChatboxExtended]: ",...,debug.traceback(level + 2));
    else
        warn("[ChatboxExtended]: ",...);
    end
end

local ChatboxExtended = {} :: Types.ChatboxExtended;

local ChatChannel = require(script:FindFirstChild("ChatChannel"));
ChatboxExtended.ChatChannel = ChatChannel;

--- @module lib/ChatboxServer/ChatCommands/init
local ChatCommands: Types.ChatCommands = require(script:FindFirstChild("ChatCommands"));
ChatboxExtended.ChatCommands = ChatCommands;

-- {[channelName]: ChatChannel}
ChatboxExtended.ChatChannels = {};

local Remotes: Folder = script.Parent:FindFirstChild("Remotes");

local PostMessage: RemoteEvent = Remotes:FindFirstChild("PostMessage");
PostMessage.OnServerEvent:Connect(function(sender: Player,channelName: string,message: string)
    local channel: ChatChannel = ChatboxExtended.ChatChannels[channelName];
    if channel then
        if channel:IsPlayerAuthorized(sender) then
            channel:PostMessage(sender,message);
        end
    end
end);

function ChatboxExtended.Init()
    ChatboxExtended.ChatChannels.General = ChatboxExtended.CreateChannel("General",false);
    -- Load the default chat commands
    ChatCommands.LoadDefaultCommands();
    ChatCommands.Init(ChatboxExtended);
    ChatChannel.Init(ChatCommands);
end

function ChatboxExtended.CreateChannel(channelName: string,...: any) : ChatChannel
    local chatChannel = ChatChannel.new(channelName,...);
    if not ChatboxExtended.ChatChannels[chatChannel.Name] then
        ChatboxExtended.ChatChannels[chatChannel.Name] = chatChannel;
    else
        -- TODO: Output that this chat channel already exists and won't be overwritten
        outWarn(3,string.format("ChatChannel with name '%s' already exists",chatChannel.Name));
    end
    return chatChannel;
end

function ChatboxExtended.GetChannel(name: string) : ChatChannel?
    return ChatboxExtended.ChatChannels[name] or nil;
end

return ChatboxExtended;