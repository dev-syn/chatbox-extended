--- @module ChatboxExtended/lib/Types
local Types = require(script.Parent:FindFirstChild("Types"));
type ChatChannel = Types.ChatChannelC;
type RealmCommand = Types.RealmCommand;

--[=[
    @class ChatboxExtendedC
    @client

    This class is for the client chat which includes chat colours, chat commands and different chat channels.
]=]
local ChatboxExtended = {} :: Types.ChatboxExtendedC;

local Core = require(script.Parent:FindFirstChild("ChatCore"));
--[=[
    @prop Core ChatCore
    @within ChatboxExtendedC
    @tag reference

    This property is a reference to the [ChatCore] class.
]=]
ChatboxExtended.Core = Core;

local ChatUI: Types.ChatUI = require(script:FindFirstChild("ChatUI"));
--[=[
    @prop ChatUI ChatUI
    @within ChatboxExtendedC
    @tag reference

    This property is a reference to the [ChatUI] class.
]=]
ChatboxExtended.ChatUI = ChatUI;

--[=[
    @prop _ChatChannels {ChatChannelC}
    @within ChatboxExtendedC
    @private

    This is an internal property that stores the current existing [ChatChannels](/api/ChatChannelC)
]=]
ChatboxExtended._ChatChannels = {};

-- Remote declerations
local Remotes = script.Parent:FindFirstChild("Remotes") :: Folder;

local ChatChannelReplication = Remotes:FindFirstChild("ChatChannelReplication") :: RemoteEvent;
local RequestChannelsRF = Remotes:FindFirstChild("RequestChannels") :: RemoteFunction
local PostMessage = Remotes:FindFirstChild("PostMessage") :: RemoteEvent;
local PostNotification = Remotes:FindFirstChild("PostNotification") :: RemoteEvent;

--[=[
    @prop ActiveChannel ChatChannelC?
    @within ChatboxExtendedC

    This property stores the active [ChatChannel](/api/ChatChannelC) or nil if there isn't one.
]=]
ChatboxExtended.ActiveChannel = nil;

-- Class local references
local ChatChannel = require(script:FindFirstChild("ChatChannel")) :: Types.ChatChannelC;
---@module Packages/TextStyling
local TextStyling: Types.TextStyling = ChatboxExtended.Core.TextStyling;
local ChatCommands: Types.ChatCommands = ChatboxExtended.Core.ChatCommands;

local Command: Types.Schema_Command,RealmCommand: Types.Schema_RealmCommand = ChatCommands.Command,ChatCommands.RealmCommand;

local Config: Types.ChatConfig = ChatboxExtended.Core.GetConfig();

local function createChannel(channelName: string)
    -- Check if this channel already exists
    if Core.FindChatChannel(ChatboxExtended,channelName) then return; end
    local newChannel: ChatChannel = ChatChannel.new(channelName);
    table.insert(ChatboxExtended._ChatChannels,newChannel);
    -- If no active channel set it to the first created
    if not ChatboxExtended.ActiveChannel then 
        ChatboxExtended.ActiveChannel = newChannel::ChatChannel?;
        ChatUI.ChannelNameB.Text = string.format("Channel %d: %s",1,channelName);
    end
end

local function switchToChannel(channelIndex: number)
    local switchChannel: ChatChannel = ChatboxExtended._ChatChannels[channelIndex];
    if switchChannel then
        -- Clear out messages from active channel
        local activeChannel: ChatChannel? = ChatboxExtended.ActiveChannel;
        if activeChannel then
            if activeChannel == switchChannel then return; end
            ChatUI.ChatListLayout.Parent = nil::any;
            for _,child: Instance in ipairs(ChatUI.ChatList:GetChildren()) do
                child.Parent = nil::any;
            end
        end
        ChatUI.ChannelNameB.Text = string.format("Channel %d: %s",channelIndex,switchChannel.Name);
        -- Transition to switch channel messages
        for _,textL: TextLabel in ipairs(switchChannel.Messages) do
            textL.Parent = ChatUI.ChatList;
        end
        ChatUI.ChatListLayout.Parent = ChatUI.ChatList;
        ChatboxExtended.ActiveChannel = switchChannel :: ChatChannel?;
    end
end

--[=[
    @within ChatUI
    @private

    This function is a internal handler for when the [ChatUI.NextChannelB] MouseButton1Click event gets connected.
]=]
function ChatboxExtended._NextChannelHandler()
    local nextChannelIndex: number = nil;
        if ChatboxExtended.ActiveChannel then
            -- Get the current active channels index
            local currentIndex: number = table.find(ChatboxExtended._ChatChannels,ChatboxExtended.ActiveChannel);
            if currentIndex then nextChannelIndex = currentIndex + 1 end
        else
            nextChannelIndex = 1;
        end
        if not nextChannelIndex or nextChannelIndex > #ChatboxExtended._ChatChannels then
            nextChannelIndex = 1;
        end
        switchToChannel(nextChannelIndex);
end

--[=[
    @within ChatUI
    @private

    This function is a internal handler for when the [ChatUI.PrevChannelB] MouseButton1Click event gets connected.
]=]
function ChatboxExtended._PrevChannelHandler()
    local prevChannelIndex: number = nil;
        if ChatboxExtended.ActiveChannel then
            -- Get the current active channels index
            local currentIndex: number = table.find(ChatboxExtended._ChatChannels,ChatboxExtended.ActiveChannel);
            if not currentIndex or currentIndex == 1 then
                prevChannelIndex = #ChatboxExtended._ChatChannels;
            else
                prevChannelIndex = currentIndex - 1;
            end
        else
            prevChannelIndex = 1;
        end
        switchToChannel(prevChannelIndex);
end

local cachedMessages: {string};
local cachedIndex: number = 0;

--[=[
    @within ChatUI
    @private

    This function is a internal handler for when the [ChatUI.ChatField] FocusLost event gets connected.
]=]
function ChatboxExtended._FocusLostHandler(enterPressed: boolean)
    if enterPressed then
        local text: string = ChatUI.ChatField.Text;
        if text == "" or #text > (Config.MAX_CHAR or 100) then
            return;
        end
        -- Cache this message
        local max_cache: number = Config.MAX_CACHED_MESSAGES or 7;
        if #cachedMessages == max_cache then table.remove(cachedMessages,1); end
        table.insert(cachedMessages,text);
        cachedIndex = 0;
        -- Check if the first char is command prefix
        if text:sub(1,1) == ChatCommands.Prefix then
            local args = text:split(" ");
            -- Verify a command name and not just the prefix
            if #args[1] > 1 then
                -- Try finding command with the given name
                local cmd: Types.Command? = ChatCommands.FindCommand(args[1]:sub(2)) :: Types.Command?;
                if cmd then
                    local success: boolean = ChatCommands.HandleCommand(cmd,table.unpack(args,2));
                    return;
                end
            end
        end
        if ChatboxExtended.ActiveChannel then
            PostMessage:FireServer(ChatboxExtended.ActiveChannel.Name,text);
        end
        ChatboxExtended.ChatUI.ChatField.Text = "";
    end
end

local InputService: UserInputService = game:GetService("UserInputService");
local ReplicationAction: Types.ReplicationAction = ChatboxExtended.Core.ReplicationAction;
local lastPlayerWhoMessaged: Player? = nil;
local isInitialized: boolean = false;
--[=[
    @within ChatboxExtendedC

    Initializes the client side of [ChatboxExtended](/api/ChatboxExtendedC) hooking the RemoteEvents and setting up the chat ui.

    :::danger

    Failure to calling this function will break [ChatboxExtended](/api/ChatboxExtendedC)

    :::
]=]
function ChatboxExtended.Init()
    if isInitialized then return; end
    isInitialized = true;
    -- Get config for potential changes
    Config = Core.GetConfig();

    -- Initialize ChatChannel for ChatboxExtended reference
    ChatChannel.Init(ChatboxExtended);
    cachedMessages = {};

    ChatChannelReplication.OnClientEvent:Connect(function(replicationAction: number,channelName: string)
        if replicationAction == ReplicationAction.CREATE then
            createChannel(channelName);
        elseif replicationAction == ReplicationAction.DESTROY and ChatboxExtended._ChatChannels[channelName] then
            local foundChannel: ChatChannel,index: number = Core.FindChatChannel(ChatboxExtended,channelName);
            if foundChannel then
                -- Reassign the ActiveChannel if it's the channel being destroyed
                if ChatboxExtended.ActiveChannel == foundChannel then
                    local channelLength: number = #ChatboxExtended._ChatChannels;
                    -- Reassign ActiveChannel if it's not the last channel
                    if channelLength > 1 then
                        if index < channelLength then
                            ChatboxExtended.ActiveChannel = ChatboxExtended._ChatChannels[index + 1] :: ChatChannel?
                        else
                            ChatboxExtended.ActiveChannel = ChatboxExtended._ChatChannels[1] :: ChatChannel?
                        end
                    else
                        ChatboxExtended.ActiveChannel = nil;
                    end
                end
                table.remove(ChatboxExtended._ChatChannels,index);
            end
        end
    end);

    PostNotification.OnClientEvent:Connect(function(channelName: string?,prefix: string,message: string)
        if channelName then
            local channel: ChatChannel = Core.FindChatChannel(ChatboxExtended,channelName);
            if channel then
                channel:PostNotification(prefix,message);
            end
        else
            if ChatboxExtended.ActiveChannel then
                (ChatboxExtended.ActiveChannel::ChatChannel):PostNotification(prefix,message);
            end
        end
    end);

    PostMessage.OnClientEvent:Connect(function(channelName: string,sender: Player,msg: string)
        local channel: ChatChannel = Core.FindChatChannel(ChatboxExtended,channelName);
        if channel then
            -- TODO: Get custom prefix
            local prefix: string = string.format("&f&l[&r%s&f&l]&r: ",sender.Name);
            channel:PostMessage(prefix,"&7"..msg);
        end
    end);

    -- Initialize ChatUI
    local DefaultUI: ScreenGui = script:FindFirstChild("ChatboxExtendedUI") :: ScreenGui;
    if DefaultUI then ChatUI._Init(ChatboxExtended,DefaultUI); end

    -- Listen for the input key to capture chat focus
    InputService.InputBegan:Connect(function(input: InputObject,gamePro: boolean)
        -- Only proccess input if it's from game and not ui
        if not (InputService:IsKeyDown(Enum.KeyCode.LeftShift) or InputService:IsKeyDown(Enum.KeyCode.RightShift)) and input.KeyCode == (Config.FOCUS_CHAT_KEY or Enum.KeyCode.Slash) then
            if not ChatUI.ChatField:IsFocused() then
                game:GetService("RunService").Heartbeat:Wait();
                ChatUI.ChatField:CaptureFocus();
            end
        elseif input.KeyCode == Enum.KeyCode.Up and ChatUI.ChatField:IsFocused() then
            if cachedIndex < #cachedMessages then
                cachedIndex += 1;
                if cachedMessages[cachedIndex] then
                    ChatUI.ChatField.Text = cachedMessages[cachedIndex];
                    ChatUI.ChatField.CursorPosition = #ChatUI.ChatField.Text + 1;
                end
            end
        elseif input.KeyCode == Enum.KeyCode.Down and ChatUI.ChatField:IsFocused() then
            if cachedIndex > 1 then
                cachedIndex -= 1;
                if cachedMessages[cachedIndex] then
                    ChatUI.ChatField.Text = cachedMessages[cachedIndex];
                    ChatUI.ChatField.CursorPosition = #ChatUI.ChatField.Text + 1;
                end
            end
        end
    end);

    ChatUI.UI.Enabled = true;

    -- Request channels from the server and attempt to create them if they don't exist
    local channelNames: {string} = RequestChannelsRF:InvokeServer();
    for _,channelName: string in ipairs(channelNames) do
        createChannel(channelName);
    end

    ChatCommands.Init(ChatboxExtended);

    local msgCmd: RealmCommand;
    msgCmd = RealmCommand.new("msg",function(sender: Player,targetName: string,msg: string)
        local target: Player? = game.Players:FindFirstChild(targetName);
        if target then
            lastPlayerWhoMessaged = target;
            -- Request to send a private message to target
            msgCmd.RemoteEvent:FireServer(target,msg);
        end
    end);
    msgCmd:SetClientHandler(function(senderName: string,msg: string)
        if ChatboxExtended.ActiveChannel then
            local prefix: string = "&b[msg] -> &f&l[%s&f&l]&b: &7"
            (ChatboxExtended.ActiveChannel::ChatChannel):PostMessage(prefix:format(senderName),msg);
        end
    end);
    ChatCommands.RegisterCommand(msgCmd);
end

--[=[
    @within ChatboxExtendedC
    @yields

    This function yields until a [ChatChannel] exists or it will timeout after the specified seconds.
]=]
function ChatboxExtended.YieldTillChannel(name: string,timeOut: number?) : ChatChannel
    local startTime: number = DateTime.now().UnixTimestamp;
    local queryChannel: ChatChannel = nil;
    repeat
        queryChannel = Core.FindChatChannel(ChatboxExtended,name);
    until Core.FindChatChannel(ChatboxExtended,name) or timeOut and (DateTime.now().UnixTimestamp - startTime) >= timeOut;
    return queryChannel;
end

return ChatboxExtended;