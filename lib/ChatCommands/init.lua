--- @module ChatboxExtended/lib/Types
local Types = require(script.Parent:FindFirstChild("Types"));
type ChatChannel = Types.ChatChannel;
type Command = Types.Command;
type RealmCommand = Types.RealmCommand;

--[=[
    @class ChatCommands

    This class was designed to create and handle commands used in the chat with ChatboxExtended.
]=]
local ChatCommands = {} :: Types.ChatCommands;

--- @module lib/ChatCommands/Command
local Command = require(script:FindFirstChild("Command")) :: Types.Schema_Command;
--[=[
    @prop Command Command
    @within ChatCommands
    @tag reference

    This property stores a reference to the [Command] class.
]=]
ChatCommands.Command = Command;

local RealmCommand: Types.Schema_RealmCommand = require(script:FindFirstChild("RealmCommand"));
--[=[
    @prop RealmCommand RealmCommand
    @within ChatCommands
    @tag reference

    This property stores a reference to the [RealmCommand] class.
]=]
ChatCommands.RealmCommand = RealmCommand;

--[=[
    @prop Prefix string
    @within ChatCommands

    This is the prefix used to recognize commands by default this represents '/'.
]=]
ChatCommands.Prefix = "/";

--[=[
    @prop _RegisteredCommands {Command | RealmCommand}
    @within ChatCommands
    @private

    This is an internal table which contains an array of [Command] or [RealmCommand] objects.
]=]
ChatCommands._RegisteredCommands = {};

--- @module lib/ChatboxServer/init
local ChatboxExtended: Types.ChatboxExtended | Types.ChatboxExtendedC;
--[=[
    @param chatboxExtended ChatboxExtendedServer -- The ChatboxExtended class

    This is an internal initial' which is called to set a reference for [ChatboxExtended].
]=]
function ChatCommands.Init(chatboxExtended: Types.ChatboxExtended | Types.ChatboxExtendedC)
    ChatboxExtended = chatboxExtended;
end

--[=[
    @within ChatCommands
    @return (Command | RealmCommand)?

    This method is for finding a command that was registered with it's name.
]=]
function ChatCommands.FindCommand(queryName: string) : (Command | RealmCommand)?
    for _,command: Command | RealmCommand in ipairs(ChatCommands._RegisteredCommands) do
        if command.Name == queryName or command._Aliases and table.find(command._Aliases,queryName) then
            return command;
        end
    end
    return nil;
end

local isServer: boolean = game:GetService("RunService"):IsServer();

--[=[
    @within ChatCommands
    @param cmd Command -- The command to be handled
    @param ... any -- The arguments that get sent to the command executor
    @return boolean -- Returns true if the command executor gets called or false if no executor was found
    @return ...any -- Returns a tuple of any results returned from the command executor

    This method is used to execute a command with the args passed.
]=]
function ChatCommands.HandleCommand(cmd: Command | RealmCommand,...: any) : (boolean,...any)
    if cmd._Executor then
        return true,cmd._Executor(...);
    end
    return false;
end

--[=[
    This method registers a command object to [ChatCommands] allowing it to be used in the [ChatboxExtended] chat.
]=]
function ChatCommands.RegisterCommand(cmd: Command | RealmCommand)
    local registeredCommands: {Command | RealmCommand} = ChatCommands._RegisteredCommands;
    if table.find(registeredCommands,cmd) then warn("Command already exists"); return; end
    table.insert(registeredCommands,cmd);
end

--[=[
    This method is for loading default commands for the [ChatboxExtended] chat.

    :::note

    You can assign commands per realm by passing an array of Commands into this function.

    :::
]=]
function ChatCommands.LoadDefaultCommands(cmds: {Command | RealmCommand}?)
    if cmds then
        for _,cmd: Command | RealmCommand in ipairs(cmds) do
            ChatCommands.RegisterCommand(cmd);
        end
    end
end

return ChatCommands;