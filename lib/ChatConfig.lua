--[=[
    @class ChatConfig
    This is a table which represents the ChatboxExtended config which contains preset values that can be configured
]=]

--[=[
    @prop MAX_MESSAGES number
    @within ChatConfig
    This configu' is for the max amount of messages that is preserved before being removed, the default is 30.
]=]

--[=[
    @prop MAX_CHAR number
    @within ChatConfig
    This configu' is for the max amount of characters allowed in a message, the default is 100 chars.
]=]

--[=[
    @prop FOCUS_CHAT_KEY Enum.KeyCode
    @within ChatConfig
    This configu' is for focusing/unfocusing the chat text field, the default is Enum.KeyCode.Slash
]=]

return {
    MAX_MESSAGES = 30, -- The max amount of messages that is stored before being removed
    MAX_CHAR = 100, -- The max amount of chars in a message
    FOCUS_CHAT_KEY = Enum.KeyCode.Slash
};