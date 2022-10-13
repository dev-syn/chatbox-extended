type Dictionary<T> = {[string]: T};

---@module lib/Types
local Types = require(script.Parent:FindFirstChild("Types"));

--[=[
    @class ChatCore
    This class is designed to contain core functions/methods that get used by the server & client ChatboxExtended
]=]
local ChatboxCore = {} :: Types.ChatboxCore;

local ConfigModule: ModuleScript = script.Parent:FindFirstChild("ChatConfig");
--[=[
    @within ChatCore
    This function gets the ChatConfig table
]=]
function ChatboxCore.GetConfig() : Dictionary<any>
    if ConfigModule then return require(ConfigModule) end
end

return ChatboxCore;