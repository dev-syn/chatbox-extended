--[=[
    @class ChatConfig
    This is a table which represents the ChatboxExtended config which contains preset values that can be configured.

    ```lua
    -- Default configuration
    return {
        MAX_MESSAGES_SERVER = 15, -- The max amount of msgs cached per channel on server
        MAX_MESSAGES = 45, -- The max amount of msgs cached per channel on the client
        MAX_CHAR = 100, -- The max amount of chars in a message excluding the prefixes
        MAX_CACHED_MESSAGES = 7, -- The amount of previous sent messages that get cached for reuse
        FOCUS_CHAT_KEY = Enum.KeyCode.Slash, -- The key that toggles focus on the ChatField
        DEFAULT_CHANNEL = "General" -- The name that will be used for the default ChatChannel
    }
    ```
    :::note

    You can configure the config by getting it from [ChatCore.GetConfig] and editing it manually, or you can set the config with [ChatCore.SetConfig].

    :::
    :::tip

    You can write to the config before calling [ChatboxExtended.Init] or [ChatboxExtendedC.Init] to ensure everything is configured at runtime.

    :::
]=]

--[=[
    @prop MAX_MESSAGES_SERVER number
    @within ChatConfig

    This configuration is for the max amount of messages that is cached on the server before being removed, the default is `15`.
]=]

--[=[
    @prop MAX_MESSAGES number
    @within ChatConfig

    This configuration is for the max amount of messages that is cached before being removed, the default is `45`.
]=]

--[=[
    @prop MAX_CHAR number
    @within ChatConfig

    This configuration is for the max amount of characters allowed in a message, the default is `100` chars.
]=]

--[=[
    @prop MAX_CACHED_MESSAGES number
    @within ChatConfig

    This configuration is for caching past messages and re-inserting them into the ChatField.
    You can do this by using [Enum.KeyCode.Up] when focused in the ChatField. The max amount of cached messages by default is `7`.
]=]

--[=[
    @prop FOCUS_CHAT_KEY Enum.KeyCode
    @within ChatConfig

    This configuration is for focusing/unfocusing the chat text field, the default is [Enum.KeyCode.Slash].
]=]

--[=[
    @prop DEFAULT_CHANNEL string
    @within ChatConfig

    This configuration is for setting the name of the default [ChatChannel] or [ChatChannelC] that gets created, the default is `"General"`.
]=]

return {
    MAX_MESSAGES_SERVER = 15, -- The max amount of msgs cached per channel on server
    MAX_MESSAGES = 45, -- The max amount of msgs cached per channel on the client
    MAX_CHAR = 100, -- The max amount of chars in a message excluding the prefixes
    MAX_CACHED_MESSAGES = 7, -- The amount of previous sent messages that get cached for reuse
    FOCUS_CHAT_KEY = Enum.KeyCode.Slash, -- The key that toggles focus on the ChatField
    DEFAULT_CHANNEL = "General" -- The name that will be used for the default ChatChannel
};