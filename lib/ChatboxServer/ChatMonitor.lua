--- @module ChatboxExtended/lib/Types
local Types = require(script.Parent.Parent:FindFirstChild("Types"));
export type ChatMonitor = Types.ChatMonitor;

--[=[
    @class ChatMonitor
    @server

    This class is designed to monitor the [ChatChannel] messages that are being recieved to prevent spam and monitor the chats.
]=]
local ChatMonitor = {} :: Types.Schema_ChatMonitor;
ChatMonitor.__index = ChatMonitor;
--[=[
    @prop _GMutedPlayers {Player}
    @within ChatMonitor

    This is an internal array of globally muted players.
]=]
ChatMonitor._GMutedPlayers = {};

local ChatboxExtended: Types.ChatboxExtended;

local function postError(monitor: ChatMonitor,plr: Player,text: string)
    ChatboxExtended.PostNotification(monitor._ChannelName,plr,ChatboxExtended.ChatChannel.Notification.ERROR,"&c"..text);
end
--[=[
    @within ChatMonitor
    @private

    This is an internal initialization method and is called to set the reference to [ChatboxExtended].
]=]
function ChatMonitor._Init(chatboxExtended: Types.ChatboxExtended)
    ChatboxExtended = chatboxExtended;
end

--[=[
    @within ChatMonitor

    This function creates a new [ChatMonitor] object.
]=]
function ChatMonitor.new(channelName: string) : ChatMonitor
    local self = {} :: Types.Object_ChatMonitor;
    --[=[
        @prop _ChannelName string
        @within ChatMonitor
        @private
        @tag object-prop

        This is an internal property that stores a [ChatChannel.Name] used to
        monitor that channel.
    ]=]
    self._ChannelName = channelName;
    --[=[
        @prop _CachedMessages Map<Player,{string}>
        @within ChatMonitor
        @private
        @tag object-prop

        This is an internal property that stores a [Player]'s messages used
        for similarity checks.
    ]=]
    self._CachedMessages = {};
    --[=[
        @prop _MutedPlayers {Player}
        @within ChatMonitor
        @private
        @tag object-prop

        This is an internal property that stores an array of [Player]'s which is used for the
        per-channel muted players.
    ]=]
    self._MutedPlayers = {};
    --[=[
        @prop _LastMessageStamps Map<Player,number>
        @within ChatMonitor
        @private
        @tag object-prop

        This is a map of [Player] keys that stores a number which is the last message timestamp.
    ]=]
    self._LastMessageStamps = {};
    return setmetatable(self,ChatMonitor) :: ChatMonitor;
end

--[=[
    @method MutePlayer
    @within ChatMonitor
    @param plr Player
    @param toMute boolean -- Passing false will unmute the player
    @param global boolean?

    This method is for muting a player either per-channel or globally if param global is true.
]=]
function ChatMonitor.MutePlayer(self: ChatMonitor,plr: Player,toMute: boolean,global: boolean?)
    if toMute then
        if global and not table.find(ChatMonitor._GMutedPlayers,plr) then
            table.insert(ChatMonitor._GMutedPlayers,plr);
        elseif not table.find(self._MutedPlayers,plr) then
            table.insert(self._MutedPlayers,plr);
        end
    end
end

-- By IrishFix
--[=[
    @within ChatMonitor
    @param a string -- The previous message to compare
    @param b string -- The new message to compare
    This function is for verifying messages similarity to previous messages in [ChatMonitor._CachedMessages].
]=]
function ChatMonitor.VerifySimilarity(a: string,b: string) : number
    local tolerance: number = 0.1
    local ACharacters = string.split(a, "")
    local SimilarCharacters = 0
    for i=1, #a do
        local Character = ACharacters[i]
        local FoundEqual = string.find(b, Character, i)
        if FoundEqual then
            local Distance = 0
            if FoundEqual < i then
                Distance = FoundEqual - i
            else
                Distance = i - FoundEqual
            end
            if (Distance / #a) <= tolerance then
                SimilarCharacters += 1
            end
        end
    end
    return SimilarCharacters/#b
end

--[=[
    @method Validate
    @within ChatMonitor
    @param sender Player
    @param message string

    This method validates a message checking for similarity and checking if a player is muted returning true if the message passed otherwise false.
]=]
function ChatMonitor.Validate(self: ChatMonitor,sender: Player,message: string) : boolean
    -- Check if sender has been globally muted
    local cachedMessages: {string} = self._CachedMessages[sender];
    if cachedMessages then
        -- Reset cachedMessages after 5 seconds
        local lastMessageStamp: number? = self._LastMessageStamps[sender];
        if lastMessageStamp and (DateTime.now().UnixTimestamp - lastMessageStamp) >= 5 then
            table.clear(cachedMessages);
        end
        for _,prevMsg: string in ipairs(cachedMessages) do
            local similarity: number = ChatMonitor.VerifySimilarity(prevMsg,message);
            if similarity >= 0.7 then
                -- Send error notif' to the sender: message is too similar
                postError(self,sender,"This message is too similar to the previous message, please wait before sending this message again.");
                return false;
            end
        end
    else
        self._CachedMessages[sender] = {};
    end
    if #self._CachedMessages >= 3 then table.remove(self._CachedMessages,1); end
    table.insert(self._CachedMessages[sender],message);
    self._LastMessageStamps[sender] = DateTime.now().UnixTimestamp;
    return true;
end

--[=[
    @method _PlayerRemovingHandler
    @within ChatMonitor
    @param plr Player
    @private

    This is a internal handler that is called when a player is removed and is for cleaning up player references.
]=]
function ChatMonitor._PlayerRemovingHandler(self: ChatMonitor,plr: Player)
    self._CachedMessages[plr] = nil;
    local mutedIndex: number? = table.find(self._MutedPlayers,plr);
    if mutedIndex then table.remove(self._MutedPlayers,mutedIndex); end
    local gMutedIndex: number? = table.find(ChatMonitor._GMutedPlayers,plr);
    if gMutedIndex then table.remove(ChatMonitor._GMutedPlayers,gMutedIndex); end
end

return ChatMonitor;