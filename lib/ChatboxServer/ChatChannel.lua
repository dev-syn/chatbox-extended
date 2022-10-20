local TextService: TextService = game:GetService("TextService");

local Remotes: Folder = script.Parent.Parent:FindFirstChild("Remotes");

local ChatChannelReplication = Remotes:FindFirstChild("ChatChannelReplication") :: RemoteEvent;
local PostMessage: RemoteEvent = Remotes:FindFirstChild("PostMessage");
local PostNotification: RemoteEvent = Remotes:FindFirstChild("PostNotification");

--- @module lib/Types
local Types = script.Parent.Parent:FindFirstChild("Types");
export type ChatChannel = Types.ChatChannel;

local ChatMonitor = require(script.Parent:FindFirstChild("ChatMonitor")) :: Types.Schema_ChatMonitor;

--[=[
    @class ChatChannel

    This class was designed for ChatboxExtended and allows seperating different chats into ChatChannel's even allowing restricted access to certain players.
]=]
local ChatChannel = {} :: Types.Schema_ChatChannel;
ChatChannel.__index = ChatChannel;

--[=[
    @param bAuthorized boolean? -- Whether or not this ChatChannel should be authorization only enabling restricted access.

    Creates a new [ChatChannel] object.
]=]
function ChatChannel.new(name: string,bAuthorized: boolean?) : ChatChannel
    local self = {} :: Types.Object_ChatChannel;
    --[=[
        @prop Name string
        @within ChatChannel
        @tag object-prop

        This property is the name of the [ChatChannel].
    ]=]
    self.Name = name;

    --[=[
        @prop _Messages {string}
        @within ChatChannel
        @private
        @tag object-prop

        This property is an array of cached messages.
    ]=]
    self._Messages = {};

    --[=[
        @prop _bCanColour boolean
        @within ChatChannel
        @private
        @tag object-prop

        This internal property enables/disables colour codes in this [ChatChannel].
    ]=]
    self._bCanColour = true;

    --[=[
        @prop _bAuthorized boolean
        @within ChatChannel
        @private
        @tag object-prop

        This internal property stores if this [ChatChannel] is authorization enabled.
        [Read more](/api/ChatChannel#SetAuthEnabled)
    ]=]
    self._bAuthorized = bAuthorized or false;

    --[=[
        @prop _AuthorizedPlayers {Player}?
        @within ChatChannel
        @private
        @tag object-prop

        This internal property that stores an array of Players who are authorized or nil if authorization is disabled.
    ]=]
    self._AuthorizedPlayers = self._bAuthorized and {} or nil;
    self.ChatMonitor = ChatMonitor.new(self.Name);
    return setmetatable(self,ChatChannel) :: ChatChannel;
end

local ChatboxExtended: Types.ChatboxExtended = nil;
local Config: Types.ChatConfig = nil;
local ChatStyling: Types.ChatStyling = nil;
local ChatCommands: Types.ChatCommands = nil;

--[=[
    @private

    This is an internal initial' which is called to set a reference of [ChatboxExtended] and [ChatCommands].
]=]
function ChatChannel._Init(chatboxExtended: Types.ChatboxExtended)
    ChatboxExtended = chatboxExtended;
    local Core: Types.ChatboxCore = ChatboxExtended.Core;
    Config = Core.GetConfig();
    ChatStyling = Core.ChatStyling;
    ChatCommands = Core.ChatCommands;
    ChatMonitor._Init(ChatboxExtended);
end

--[=[
    @method IsPlayerAuthorized
    @within ChatChannel
    @param plr Player

    This method is for validating if a player is authorized or not.
]=]
function ChatChannel.IsPlayerAuthorized(self: ChatChannel,plr: Player) : boolean
    if not self._bAuthorized then return true; end
    return table.find(self._AuthorizedPlayers,plr) and true or false;
end

--[=[
    @method SetAuthEnabled
    @within ChatChannel
    @param bAuthorized boolean -- Whether or not to enable/disable authorization.

    This method is for enabling/disabling authorization on this ChatChannel.
]=]
function ChatChannel.SetAuthEnabled(self: ChatChannel,bAuthorized: boolean)
    if bAuthorized and not self._AuthorizedPlayers then
        self._AuthorizedPlayers = {};
    else
        self._AuthorizedPlayers = nil;
    end
    self._bAuthorized = bAuthorized;
end

--[=[
    @method SetPlayerAuth
    @within ChatChannel
    @param plr Player
    @param toAuthorize boolean -- Whether or not to authorize the player in this ChatChannel

    This method is for setting if a player is authorized or not.
]=]
function ChatChannel.SetPlayerAuth(self: ChatChannel,plr: Player,toAuthorize: boolean)
    if not self._bAuthorized then
        self:SetAuthEnabled(true);
    end
    local foundIndex: number? = table.find(self._AuthorizedPlayers,plr);
    if toAuthorize and not foundIndex then
        table.insert(self._AuthorizedPlayers,plr);
    elseif not toAuthorize and foundIndex then
        table.remove(self._AuthorizedPlayers,foundIndex);
    end
end

--[=[
    @method _FireToAuthorized
    @within ChatChannel
    @private
    @param remote RemoteEvent
    @param ... any

    This internal method is for firing events to the authorized players only.
]=]
function ChatChannel._FireToAuthorized(self: ChatChannel,remote: RemoteEvent,...: any)
    for _,player: Player in ipairs(self._bAuthorized and self._AuthorizedPlayers or game.Players:GetPlayers()) do
        remote:FireClient(player,...);
    end
end

--[=[
    @method PostMessage
    @within ChatChannel
    @param sender Player -- The player that sent the message
    @param msg string -- The message that will be sent to this ChatChannel

    This method is for posting messages to this ChatChannel displaying those messages to other players in the ChatChannel.
]=]
function ChatChannel.PostMessage(self: ChatChannel,sender: Player,msg: string)
    -- #default MAX_CHAR
    if msg == "" or #msg > (Config.MAX_CHAR or 100) then
        -- Message is empty or over max char limit
        return;
    end
    -- Strip message of any rich text
    msg = ChatStyling.StripRichText(msg);

    -- Check if the first char is command prefix
    if msg:sub(1,1) == ChatCommands.Prefix then
        local args = msg:split(" ");
        -- Verify a command name and not just the prefix
        if #args[1] > 1 then
            -- Try finding command with the given name
            local cmd: Types.Command? = ChatCommands.FindCommand(args[1]:sub(2)) :: Types.Command?;
            if cmd then
                local success: boolean = ChatCommands.HandleCommand(cmd,table.unpack({sender,table.unpack(args,2)}));
                return;
            end
        end
    end

    -- TODO: Check if this sender has authorization to post a message
    local filteredMessage: string? = ChatboxExtended.FilterText(sender,msg);
    if filteredMessage then
        local msgValidated: boolean = self.ChatMonitor:Validate(sender,msg);
        if msgValidated then
            self:_FireToAuthorized(PostMessage,self.Name,sender,filteredMessage);
            -- #default MAX_MESSAGES_SERVER
            if #self._Messages > ((Config.MAX_MESSAGES_SERVER or 15) - 1) then
                table.remove(self._Messages,1);
            end
            table.insert(self._Messages,filteredMessage);
        end
    end
end

--[=[
    @interface E_Notification
    @within ChatChannel
    .Server "&f&l[&6Server&f]&r&7: "
    .Error "&f&l[&4Error&f]&r&7: "
]=]

--[=[
    @prop Notification E_Notification
    @within ChatChannel
    @tag enum-like

    This property is a enum-like table containing prefixes that are used in [ChatboxExtended:PostNotification].
]=]
ChatChannel.Notification = {
    SERVER = "&f&l[&6Server&f]&r&7: ",
    ERROR = "&f&l[&4Error&f]&r&7: ";
};

--[=[
    @method PostNotification
    @within ChatChannel
    @param prefix string
    @param msg string
    @param plr Player

    This method is for posting notifications to the ChatChannel usually for Server or Errors in the chat.
]=]
function ChatChannel.PostNotification(self: ChatChannel,prefix: string,msg: string,players: {Player} | Player?)
    if prefix == "" then return; end
    if msg == "" then return; end
    if players then
        local playersType: string = typeof(players);
        if playersType == "Instance" and players:IsA("Player") then
            PostNotification:FireClient(players::Player,self.Name,prefix,msg);
        elseif playersType == "table" then
            for _,plr: Player in ipairs(players) do
                PostNotification:FireClient(plr,self.Name,prefix,msg);
            end
        end
    else
        -- TODO: Decide if I want to fire to all players or only channel authorized
        self:_FireToAuthorized(PostNotification,self.Name,prefix,msg);
    end
end

--[=[
    @method Destroy
    @within ChatChannel

    This method frees up memory that was used for this [ChatChannel].
]=]
function ChatChannel.Destroy(self: ChatChannel)
    self._bAuthorized = false;
    self._AuthorizedPlayers = nil;
    ChatChannelReplication:FireAllClients(ChatboxExtended.Core.ReplicationAction.DESTROY,self.Name);
    local channelIndex: number? = table.find(ChatboxExtended._ChatChannels,self);
    if channelIndex then table.remove(ChatboxExtended._ChatChannels,channelIndex); end
end

--[=[
    @method _PlayerRemovingHandler
    @within ChatChannel
    @param plr Player
    @private

    This is a internal handler that is called when a player is removed and is for cleaning up player references.
]=]
function ChatChannel._PlayerRemovingHandler(self: ChatChannel,plr: Player)
    if self._bAuthorized then
        local plrIndex: number? = table.find(self._AuthorizedPlayers,plr);
        if plrIndex then table.remove(self._AuthorizedPlayers,plrIndex); end
    end
    self.ChatMonitor:_PlayerRemovingHandler(plr);
end

return ChatChannel;