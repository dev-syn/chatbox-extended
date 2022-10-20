type Dictionary<T> = {[string]: T};

---@module lib/Types
local Types = require(script.Parent:FindFirstChild("Types"));

type ChatboxExtended = Types.ChatboxExtended;
type ChatChannel = Types.ChatChannel;
type ChatboxExtendedC = Types.ChatboxExtendedC;
type ChatChannelC = Types.ChatChannelC;

--[=[
    @class ChatCore
    This class is designed to contain core functions/methods that get used by the server & client ChatboxExtended
]=]
local ChatboxCore = {} :: Types.ChatboxCore;

--[=[
    @interface E_ReplicationAction
    @within ChatCore
    .Create 0
    .Destroy 1

    This interface is for [ChatCore.ReplicationAction].
]=]
--[=[
    @prop ReplicationAction E_ReplicationAction
    @within ChatCore
    @readonly
    @tag enum-like

    This is an `enum-like` table used to distinguish the replication action to take when in the ChatChannelReplication [RemoteEvent].
]=]
ChatboxCore.ReplicationAction = {
    CREATE = 0,
    DESTROY = 1
};

--[=[
    @prop ChatCommands ChatCommands
    @within ChatCore
    @tag reference

    This property stores a reference to the [ChatCommands] class.
]=]
ChatboxCore.ChatCommands = require(script.Parent:FindFirstChild("ChatCommands"));

local Dependencies: Folder = script.Parent:FindFirstChild("Dependencies") :: Folder;
--[=[
    @prop Dependencies Folder
    @within ChatCore
    @tag reference

    This property stores a reference to the Dependencies folder.
]=]
ChatboxCore.Dependencies = Dependencies;

--[=[
    @prop TextStyling TextStyling
    @within ChatCore
    @tag reference

    This property stores a reference to the TextStyling class.

    :::note

    >Read more about [TextStyling](https://dev-syn.github.io/RBX-TextStyling/api/TextStyling)

    :::
]=]
ChatboxCore.TextStyling = require(Dependencies:FindFirstChild("TextStyling"));

local ConfigModule: ModuleScript = script.Parent:FindFirstChild("ChatConfig");
if ConfigModule then
    ChatboxCore.Config = require(ConfigModule);
end

--[=[
    @within ChatCore
    @return ChatConfig
    @server
    @client

    This function gets the current [ChatConfig].
]=]
function ChatboxCore.GetConfig() : Types.ChatConfig
    return ChatboxCore.Config;
end

--[=[
    @within ChatCore
    @param config ChatConfig
    @server
    @client

    This function sets the [ChatConfig] to the passed table.
]=]
function ChatboxCore.SetConfig(config: Types.ChatConfig)
    if config then ChatboxCore.Config = config; end
end

--[=[
    @within ChatCore
    @server
    @client
    @return ChatChannel | ChatChannelC -- The ChatChannel or nil if no channel was found.
    @return number -- The index of the ChatChannel(intended for internal use) or nil if no channel was found.

    This function is used to retrieve the ChatChannel with the specified name and it's index or nil if no ChatChannel found.

    ```lua
    local ChatboxExtended = require(game.ReplicatedStorage:FindFirstChild("ChatboxExtended"));
    type ChatChannel = ChatboxExtended.ChatChannel | ChatboxExtended.ChatChannelC;

    local Core: ChatboxExtended.ChatboxCore = ChatboxExtended.Core;

    -- The variable channel would be the 'General' ChatChannel if it exists or nil
    local channel: ChatChannel = Core.FindChatChannel(ChatboxExtended,"General");

    -- The variable channel would be the 'ExampleIndex' ChatChannel if it exists or nil
    -- The index can be retrieved but it's intended for internal use
    local channel2: ChatChannel,index: number = Core.FindChatChannel(ChatboxExtended,"ExampleIndex");

    -- Check if the channels exists
    if channel and channel2 then
        -- Do stuff
    end
    ```
]=]
function ChatboxCore.FindChatChannel(chatboxExtended: ChatboxExtended | ChatboxExtendedC,name: string) : (ChatChannel | ChatChannelC,number)
    for index: number,channel: ChatChannel | ChatChannelC in ipairs(chatboxExtended._ChatChannels) do
        if channel.Name == name then
            return channel,index;
        end
    end
end

--[=[
    @within ChatCore
    @server
    @client

    This function formats a prefix and a tuple of any type which is converted to a output message.
]=]
function ChatboxCore._FormatOut(prefix: string,...: any) : string
    local parsedText: string = string.format("[%s]: ",prefix);
    for _,v: any in ipairs({...}) do
        if not (type(v) == "string") then v = tostring(v); end
        parsedText = parsedText..v;
    end
    return parsedText;
end

return ChatboxCore;