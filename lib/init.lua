local Remotes: Folder = script:FindFirstChild("Remotes");
local PostMessageEvent: RemoteEvent = Remotes:FindFirstChild("PostMessage");

local ChatboxClient: ModuleScript,ChatboxServer: ModuleScript = script:FindFirstChild("ChatboxClient"),script:FindFirstChild("ChatboxServer");

-- Export types in main module for wally-types
-- #region Types

--- @module lib/ChatboxClient/Types
local ClientTypes: boolean = require(ChatboxClient:FindFirstChild("Types"));

export type ChatboxExtendedClient = ClientTypes.ChatboxExtended;

--- @module lib/ChatboxServer/Types
local ServerTypes: boolean = require(ChatboxServer:FindFirstChild("Types"));

export type Schema_ChatChannel = ServerTypes.Schema_ChatChannel;
export type ChatChannel = ServerTypes.ChatChannel;

export type Schema_Command = ServerTypes.Schema_Command;
export type Command = ServerTypes.Command;

export type ChatCommands = ServerTypes.ChatCommands;
export type ChatboxExtendedServer = ServerTypes.ChatboxExtended;

--#endregion

if game:GetService("RunService"):IsServer() then
    return require(ChatboxServer);
else
    if ChatboxServer then
        ChatboxServer:Destroy();
    end
    return require(ChatboxClient);
end