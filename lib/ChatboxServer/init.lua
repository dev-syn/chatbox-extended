---@module ChatboxExtended/lib/Types
local Types = require(script.Parent:FindFirstChild("Types"));
type ChatChannel = Types.ChatChannel;
type RealmCommand = Types.RealmCommand;

local TextService: TextService = game:GetService("TextService");

--[=[
    @class ChatboxExtended
    @server

    This class is for the server chat which includes chat colours, chat commands and different chat channels.
]=]

local ChatboxExtended = {} :: Types.ChatboxExtended;

local Core: Types.ChatboxCore = require(script.Parent:FindFirstChild("ChatCore"));
--[=[
    @prop Core ChatCore
    @within ChatboxExtended
    @tag reference

    This property stores a reference to the [ChatCore] class.
]=]
ChatboxExtended.Core = Core;

local Config: Types.ChatConfig = Core.GetConfig();
local Command: Types.Schema_Command,RealmCommand: Types.Schema_RealmCommand = Core.ChatCommands.Command,Core.ChatCommands.RealmCommand;


local ChatChannel = require(script:FindFirstChild("ChatChannel")) :: Types.Schema_ChatChannel;
--[=[
    @prop ChatChannel ChatChannel
    @within ChatboxExtended
    @tag reference

    This property stores a reference to the [ChatChannel] class.
]=]
ChatboxExtended.ChatChannel = ChatChannel;

--[=[
    @prop _ChatChannels {ChatChannel}
    @within ChatboxExtended
    @private

    This property stores an array of ChatChannels.
]=]
ChatboxExtended._ChatChannels = {};

local Remotes = script.Parent:FindFirstChild("Remotes")::Folder;

local ChatChannelReplication = Remotes:FindFirstChild("ChatChannelReplication")::RemoteEvent;
local RequestChannelsRF = Remotes:FindFirstChild("RequestChannels")::RemoteFunction;
local PostMessage = Remotes:FindFirstChild("PostMessage")::RemoteEvent;
local PostNotification = Remotes:FindFirstChild("PostNotification")::RemoteEvent;

PostMessage.OnServerEvent:Connect(function(sender: Player,channelName: string,message: string)
    local channel: ChatChannel = Core.FindChatChannel(ChatboxExtended,channelName);
    if channel then
        -- Check if this sender is authorized to post message
        if channel:IsPlayerAuthorized(sender) then
            channel:PostMessage(sender,message);
        end
    end
end);

---@module ServerPackages/Permissions
local Permissions: any = require(Core.ChatboxExtendedModule.Parent:FindFirstChild("Permissions"));
if not Permissions then
    warn("[ChatboxExtended]: No 'Permissions' found as a dependency, if this dependency is missing then users will be able to use all commands that exist by default in ChatboxExtended");
end

local ChatMonitor: Types.Schema_ChatMonitor = require(script:FindFirstChild("ChatMonitor"));

local isInitialized: boolean = false;
--[=[
    @within ChatboxExtended
    @param permissions Permissions? -- You can pass 

    Initializes the [ChatChannel] and [ChatCommands] class and loads the [default chat commands](/api/ChatCommands#LoadDefaultCommands).

    :::danger

    This Init method must be called if it's not [ChatboxExtended] will break.

    :::
]=]
function ChatboxExtended.Init(permissions: any)
    if isInitialized then return; end
    isInitialized = true;
    -- Get the potentially updated config
    Config = Core.GetConfig();

    local ChatCommands: Types.ChatCommands = Core.ChatCommands;
    -- Initialize ChatCommands & ChatChannel
    ChatCommands.Init(ChatboxExtended);
    ChatChannel._Init(ChatboxExtended);

    game.Players.PlayerRemoving:Connect(function(plr: Player)
        for _,channel: ChatChannel in ipairs(ChatboxExtended._ChatChannels) do
            channel:_PlayerRemovingHandler(plr);
        end
        -- Incase of no channels remove players from _GMutedPlayers
        local plrIndex: number? = table.find(ChatMonitor._GMutedPlayers,plr);
        if plrIndex then table.remove(ChatMonitor._GMutedPlayers,plrIndex); end
    end);

    -- Message command
    local msgCmd: RealmCommand = RealmCommand.new("msg");
    msgCmd:SetServerHandler(function(sender: Player,target: Player,msg: string)
        if typeof(target) ~= "Instance" or not target:IsA("Player") then
            return ChatboxExtended.PostError(nil,sender,"Invalid arg target, This is not a valid player name.");
        end
        if msg == "" then return ChatboxExtended.PostError(nil,sender,"Invalid arg msg, The msg cannot be empty."); end
        local filteredMessage: string? = ChatboxExtended.FilterText(sender,msg);
        if filteredMessage then
            msgCmd.RemoteEvent:FireClient(target,sender.Name,msg);
        end
    end);
    ChatCommands.RegisterCommand(msgCmd);

    -- Load default server commands
    ChatCommands.LoadDefaultCommands({
        Command.new("test",function(sender: Player)
            local generalChannel: ChatChannel = ChatboxExtended.Core.FindChatChannel(ChatboxExtended,"General");
            if generalChannel then
                generalChannel:PostNotification(generalChannel.Notification.SERVER,"Test command was called");
            end
        end),
        Command.new("createchannel",function(sender: Player,channelName: string)
            if not typeof(channelName) == "string" then return; end
            if not Core.FindChatChannel(ChatboxExtended,channelName) then
                ChatboxExtended.CreateChannel(channelName,nil);
            end
        end);
    });
    -- Create the default chat channel
    ChatboxExtended.CreateChannel(Config.DEFAULT_CHANNEL or "General",false);
    RequestChannelsRF.OnServerInvoke = function(plr: Player) : any
        local channelNames: {string} = {};
        for _,channel: ChatChannel in ipairs(ChatboxExtended._ChatChannels) do
            if channel:IsPlayerAuthorized(plr) then table.insert(channelNames,channel.Name); end
        end
        return channelNames;
    end
end

--[=[
    @within ChatboxExtended

    Creates a [ChatChannel object](/api/ChatChannel#new) that will be registered with [ChatboxExtended].

    :::caution

    You should always check if the return from this function is valid since it can be nil if the channel already exists.

    :::
]=]
function ChatboxExtended.CreateChannel(channelName: string,bAuthorized: boolean?) : ChatChannel
    local chatChannel: ChatChannel = Core.FindChatChannel(ChatboxExtended,channelName);
    if chatChannel then warn(Core._FormatOut("ChatboxExtended ".."ChatChannel with name "..channelName.." already exists \n"..debug.traceback(4))); return nil::any; end
    chatChannel = ChatChannel.new(channelName,bAuthorized);
    table.insert(ChatboxExtended._ChatChannels,chatChannel);
    -- If the ChatChannel is not authorization enabled, create this ChatChannel on all clients --
    if not bAuthorized then ChatChannelReplication:FireAllClients(Core.ReplicationAction.CREATE,chatChannel.Name); end
    return chatChannel;
end

--[=[
    @within ChatboxExtended

    This is essentially the same function as [ChatChannel:PostNotification] except that it takes in a channel name
    and posts a notification to that channel if it's found.
]=]
function ChatboxExtended.PostNotification(channelName: string,plr: Player,prefix: string,msg: string)
    local channel: ChatChannel = Core.FindChatChannel(ChatboxExtended,channelName);
    if channel then channel:PostNotification(prefix,msg,plr); end
end

--[=[
    @within ChatboxExtended
]=]
function ChatboxExtended.PostError(channelName: string?,plr: Player,msg: string)
    if channelName then return ChatboxExtended.PostNotification(channelName,plr,ChatChannel.Notification.ERROR,msg); end
    -- If no ChatChannel then attempt to post notification to players active channel.
    PostNotification:FireClient(plr,nil,ChatChannel.Notification.ERROR,msg);
end

function ChatboxExtended.FilterText(sender: Player,text: string) : string?
    local filteredTextObject: TextFilterResult;
    local success: boolean, err: string = pcall(function()
        filteredTextObject = TextService:FilterStringAsync(text,sender.UserId,Enum.TextFilterContext.PublicChat);
    end);
    if success then
        return filteredTextObject:GetNonChatStringForBroadcastAsync();
    end
    return nil;
end

return ChatboxExtended;