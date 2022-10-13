local Types = require(script:FindFirstChild("Types"));
type ChatChannel = Types.ChatChannel;

local function outWarn(level: number?,...: string)
    if level then
        warn("[ChatboxExtended]: ",...,debug.traceback(level + 2));
    else
        warn("[ChatboxExtended]: ",...);
    end
end

--[=[
    @class ChatboxExtendedServer
    This class is for the server chat which includes chat colours, chat commands and different chat channels.
]=]

local ChatboxExtended = {} :: Types.ChatboxExtended;

local ChatChannel = require(script:FindFirstChild("ChatChannel"));
ChatboxExtended.ChatChannel = ChatChannel;

--- @module lib/ChatboxServer/ChatCommands/init
local ChatCommands: Types.ChatCommands = require(script:FindFirstChild("ChatCommands"));
--[=[
    @prop ChatCommands ChatCommands
    @within ChatboxExtendedServer
    This property stores the ChatCommands class.
]=]
ChatboxExtended.ChatCommands = ChatCommands;

-- {[channelName]: ChatChannel}
--[=[
    @prop ChatChannels {[channelName]: ChatChannel}
    @within ChatboxExtendedServer
    This property stores a table which contains the current existing chat channels.
]=]
ChatboxExtended.ChatChannels = {};

local Remotes: Folder = script.Parent:FindFirstChild("Remotes");

local PostMessage: RemoteEvent = Remotes:FindFirstChild("PostMessage") :: RemoteEvent;
PostMessage.OnServerEvent:Connect(function(sender: Player,channelName: string,message: string)
    local channel: ChatChannel = ChatboxExtended.ChatChannels[channelName];
    if channel then
        -- Check if this sender is authorized to post message
        if channel:IsPlayerAuthorized(sender) then
            channel:PostMessage(sender,message);
        end
    end
end);

--[=[
    @within ChatboxExtendedServer
    Initializes the ChatChannel and ChatCommands class along with loading the default commands.
]=]
function ChatboxExtended.Init()
    ChatboxExtended.ChatChannels.General = ChatboxExtended.CreateChannel("General",false);
    -- Load the default chat commands
    ChatCommands.LoadDefaultCommands();
    ChatCommands.Init(ChatboxExtended);
    ChatChannel._Init(ChatCommands);
end

--[=[
    @within ChatboxExtendedServer
    Creates a ChatChannel object that will be registered with the ChatboxExtended class.
]=]
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

--[=[
    @within ChatboxExtendedServer
    Attempts to get a ChatChannel with it's name or returns nil if not found.
]=]
function ChatboxExtended.GetChannel(name: string) : ChatChannel?
    return ChatboxExtended.ChatChannels[name] or nil;
end

return ChatboxExtended;