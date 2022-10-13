--- @module lib/ChatConfig
local Config = require(script.Parent.Parent:FindFirstChild("ChatConfig"));

local TextService: TextService = game:GetService("TextService");

local Remotes: Folder = script.Parent.Parent:FindFirstChild("Remotes");
local PostMessage: RemoteEvent = Remotes:FindFirstChild("PostMessage");
local PostNotification: RemoteEvent = Remotes:FindFirstChild("PostNotification");

--- @module lib/Types
local Types = script.Parent:FindFirstChild("Types");
export type ChatChannel = Types.ChatChannel;

--[=[
    @class ChatChannel
    This class was designed for ChatboxExtended and allows seperating different chats into ChatChannel's even allowing restricted access to certain players.
]=]
local ChatChannel = {} :: Types.Schema_ChatChannel;
ChatChannel.__index = ChatChannel;

--- @module lib/ChatStyling
local ChatStyling = require(script.Parent.Parent:FindFirstChild("ChatStyling"));

--[=[
    @param bAuthorized boolean? -- Whether or not this ChatChannel should be authorization only enabling restricted access.
    Creates a new ChatChannel object
]=]
function ChatChannel.new(name: string,bAuthorized: boolean?) : ChatChannel
    local self = {} :: Types.Object_ChatChannel;
    self.Name = name;
    self.Messages = {};

    self.bCanColour = true;
    self.bAuthorized = bAuthorized or false;
    self.AuthorizedPlayers = self.bAuthorized and {} or nil;
    return setmetatable(self,ChatChannel) :: ChatChannel;
end

local ChatCommands: Types.ChatCommands = nil;
--[=[
    @private
    This is an internal initial' which is called to set a reference for ChatCommands.
]=]
function ChatChannel._Init(chatCommands: Types.ChatCommands)
    ChatCommands = chatCommands;
end

--[=[
    @method IsPlayerAuthorized
    @within ChatChannel
    @param plr Player
    This method is for validating if a player is authorized or not.
]=]
function ChatChannel.IsPlayerAuthorized(self: ChatChannel,plr: Player) : boolean
    if not self.bAuthorized then return true; end
    return table.find(self.AuthorizedPlayers,plr) and true or false;
end

--[=[
    @method SetAuthEnabled
    @within ChatChannel
    @param bAuthorized boolean -- Whether or not to enable/disable authorization.
    This method is for enabling/disabling authorization on this ChatChannel.
]=]
function ChatChannel.SetAuthEnabled(self: ChatChannel,bAuthorized: boolean)
    if bAuthorized and not self.AuthorizedPlayers then
        self.AuthorizedPlayers = {};
    else
        self.AuthorizedPlayers = nil;
    end
    self.bAuthorized = bAuthorized;
end

--[=[
    @method SetPlayerAuth
    @within ChatChannel
    @param plr Player
    @param toAuthorize boolean -- Whether or not to authorize the player in this ChatChannel
    This method is for setting if a player is authorized or not.
]=]
function ChatChannel.SetPlayerAuth(self: ChatChannel,plr: Player,toAuthorize: boolean)
    if not self.bAuthorized then
        self:SetAuthEnabled(true);
    end
    local foundIndex: number? = table.find(self.AuthorizedPlayers,plr);
    if toAuthorize and not foundIndex then
        table.insert(self.AuthorizedPlayers,plr);
    elseif not toAuthorize and foundIndex then
        table.remove(self.AuthorizedPlayers,foundIndex);
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
    for _,player: Player in ipairs(self.bAuthorized and self.AuthorizedPlayers or game.Players:GetPlayers()) do
        remote:FireClient(player,...);
    end
end

local function getFilteredText(sender: Player,text: string) : string?
    local filteredTextObject: TextFilterResult;
    local success: boolean, err: string = pcall(function()
        filteredTextObject = TextService:FilterStringAsync(text,sender.UserId,Enum.TextFilterContext.PublicChat);
    end);
    if success then
        return filteredTextObject:GetNonChatStringForBroadcastAsync();
    end
    return nil;
end

--[=[
    @method PostMessage
    @within ChatChannel
    @param sender Player -- The player that sent the message
    @param msg string -- The message that will be sent to this ChatChannel
    This method is for posting messages to this ChatChannel displaying those messages to other players in the ChatChannel.
]=]
function ChatChannel.PostMessage(self: ChatChannel,sender: Player,msg: string)
    if msg == "" or #msg > (Config.MAX_CHAR or 100) then
        -- Message is empty or over max char limit
        return;
    end
    -- Strip message of any rich text
    msg = ChatStyling.StripRichText(msg);
    
    -- Check if the first char is command prefix
    if ChatCommands and msg:sub(1,1) == ChatCommands.Prefix then
        local args = msg:split(" ");
        if #args == 0 then
            warn("No args for command");
            return;
        end
        -- Try finding command with the given name
        local cmd: Types.Command? = ChatCommands.FindCommand(args[1]:sub(2)) :: Types.Command?;
        if cmd then
            local success: boolean = ChatCommands.HandleCommand(cmd,table.unpack({sender,table.unpack(args,2)}));
            return;
        end
    end
    -- TODO: Check if this sender has authorization to post a message
    local filteredMessage: string = getFilteredText(sender,msg);
    if filteredMessage then
        self:_FireToAuthorized(PostMessage,self.Name,sender,filteredMessage);
    end
end

--[=[
    @interface Notification_T
    @within ChatChannel
    .Server "[Server]: "
    .Error "[Error]: "
]=]
--[=[
    @prop Notification Notification_T
    @within ChatChannel
    This property is a map to a chat prefix for the notification.
]=]
ChatChannel.Notification = {
    SERVER = ChatStyling.ParseTextCodes("&f&l[&6Server&f]&r&7: "),
    ERROR = ChatStyling.ParseTextCodes("&f&l[&4Error&f]&r&7: ");
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
    if typeof(prefix) ~= "string" or prefix == "" then return; end
    if typeof(msg) ~= "string" or msg == "" then return; end
    if players then
        if typeof(players) == "Instance" and players:IsA("Player") then
            PostNotification:FireClient(players::Player,self.Name,prefix,msg);
        elseif typeof(players) == "table" then
            for _,plr: Player in ipairs(players) do
                PostNotification:FireClient(plr,self.Name,prefix,msg);
            end
        end
    else
        -- TODO: Decide if I want to fire to all players or only channel authorized
        self:_FireToAuthorized(PostNotification,self.Name,prefix,msg);
    end
end

return ChatChannel;