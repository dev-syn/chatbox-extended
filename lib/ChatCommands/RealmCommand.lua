---@module lib/Types
local Types = require(script.Parent.Parent:FindFirstChild("Types"));
type RealmCommand = Types.RealmCommand;

local isServer: boolean = game:GetService("RunService"):IsServer();

local Command = require(script.Parent:FindFirstChild("Command")) :: Types.Command;

local RealmCommandEvents: Folder = script.Parent.Parent:FindFirstChild("Remotes"):FindFirstChild("RealmCommandEvents");

--[=[
    @class RealmCommand

    This class inherits from the [Command] class and it implements server & client communication for cross-realm commands.
]=]
local RealmCommand = {} :: Types.Schema_RealmCommand;
RealmCommand.__index = RealmCommand;
RealmCommand.ClassName = "RealmCommand";

setmetatable(RealmCommand::table,Command::table);

local ChatCommands: Types.ChatCommands;
--[=[
    This function is for initializing the reference to [ChatCommands].
]=]
function RealmCommand.Init(chatCommands: Types.ChatCommands)
    ChatCommands = chatCommands;
end

function RealmCommand.new<RealmCommand>(name: string,executor: (...any) -> (),aliases: {string}?) : RealmCommand
    local self = Command.new(name,executor,aliases) :: Types.Object_RealmCommand;
    local remote: RemoteEvent;
    if isServer then
        if not RealmCommandEvents:FindFirstChild(name) then
            remote = Instance.new("RemoteEvent");
            remote.Name = name;
            remote.Parent = RealmCommandEvents;
        end
    else
        remote = RealmCommandEvents:WaitForChild(name);
    end
    self.RemoteEvent = remote;
    return setmetatable(self::table,RealmCommand::table) :: RealmCommand;
end

function RealmCommand.SetServerHandler(self: RealmCommand,fn: (plr: Player,...any) -> ()) : RBXScriptConnection
    return self.RemoteEvent.OnServerEvent:Connect(fn);
end

function RealmCommand.SetClientHandler(self: RealmCommand,fn: (...any) -> ())
    return self.RemoteEvent.OnClientEvent:Connect(fn);
end

return RealmCommand;