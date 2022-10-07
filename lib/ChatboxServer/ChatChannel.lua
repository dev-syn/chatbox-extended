local TextService: TextService = game:GetService("TextService");

local Remotes: Folder = script.Parent.Parent:FindFirstChild("Remotes");
local PostMessage: RemoteEvent = Remotes:FindFirstChild("PostMessage");
local PostNotification: RemoteEvent = Remotes:FindFirstChild("PostNotification");

--- @module lib/ChatboxServer/Types
local Types = script.Parent:FindFirstChild("Types");
export type ChatChannel = Types.ChatChannel;

local ChatChannel = {} :: Types.Schema_ChatChannel;
ChatChannel.__index = ChatChannel;

--- @module lib/ChatStyling
local ChatStyling = require(script.Parent.Parent:FindFirstChild("ChatStyling"));

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
function ChatChannel.Init(chatCommands: Types.ChatCommands)
    ChatCommands = chatCommands;
end

function ChatChannel.IsPlayerAuthorized(self: ChatChannel,player: Player) : boolean
    if not self.bAuthorized then
        return true;
    end
    return table.find(self.AuthorizedPlayers,player) and true or false;
end

function ChatChannel.SetPlayerAuth(self: ChatChannel,player: Player,toAuthorize: boolean)
    if not self.bAuthorized then
        self:SetAuthEnabled(true);
    end
    local foundIndex: number? = table.find(self.AuthorizedPlayers,player);
    if toAuthorize and not foundIndex then
        table.insert(self.AuthorizedPlayers,player);
    elseif not toAuthorize and foundIndex then
        table.remove(self.AuthorizedPlayers,foundIndex);
    end
end

function ChatChannel.SetAuthEnabled(self: ChatChannel,bAuthorized: boolean)
    if bAuthorized and not self.AuthorizedPlayers then
        self.AuthorizedPlayers = {};
    else
        self.AuthorizedPlayers = nil;
    end
    self.bAuthorized = bAuthorized;
end

function ChatChannel.FireToAuthorized(self: ChatChannel,remote: RemoteEvent,...: any)
    for _,player: Player in ipairs(self.bAuthorized and self.AuthorizedPlayers or game.Players:GetPlayers()) do
        remote:FireClient(player,...);
    end
end

function ChatChannel.PostMessage(self: ChatChannel,sender: Player,message: string)
    -- Strip message of any rich text
    message = ChatStyling.StripRichText(message);
    -- Check if message is a command
    if ChatCommands and message:sub(1,1) == ChatCommands.Prefix then
        local args = message:split(" ");
        if #args == 0 then
            warn("No args for command");
            return;
        end
        if ChatCommands.IsCommand(args[1]:sub(2)) then
            local success = ChatCommands.HandleCommand(args[1]:sub(2),table.unpack({sender,table.unpack(args,2)}));
            return;
        end
    end
    -- TODO: Check if this sender has authorization to post a message
    local filteredTextObject: TextFilterResult;
    local success: boolean, err: string = pcall(function()
        filteredTextObject = TextService:FilterStringAsync(message,sender.UserId,Enum.TextFilterContext.PublicChat);
    end);
    if success then
        local filteredMessage: string = filteredTextObject:GetNonChatStringForBroadcastAsync();
        -- Get the players set name colour
        self:FireToAuthorized(PostMessage,self.Name,sender,filteredMessage);
    end
end

ChatChannel.Notification = {
    SERVER = ChatStyling.ParseTextCodes("&f&l[&6Server&f]&r&7: "),
    ERROR = ChatStyling.ParseTextCodes("&f&l[&4Error&f]&r&7: ");
};

function ChatChannel.PostNotification(self: ChatChannel,prefix: string,message: string,players: {Player} | Player?)
    if players then
        if typeof(players) == "Instance" and players:IsA("Player") then
            PostNotification:FireClient(players::Player,self.Name,prefix,message);
        elseif typeof(players) == "table" then
            for _,plr: Player in ipairs(players) do
                PostNotification:FireClient(plr,self.Name,prefix,message);
            end
        end
    else
        -- TODO: Decide if I want to fire to all players or only channel authorized
        self:FireToAuthorized(PostNotification,self.Name,prefix,message);
    end
end

return ChatChannel;