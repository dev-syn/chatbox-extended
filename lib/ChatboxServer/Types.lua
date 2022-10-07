export type Map<K,V> = {[K]: V};
export type Dictionary<T> = Map<string,T>;

-- #region ChatChannel
    export type Object_ChatChannel = {
        Name: string,
        Messages: {},
        bCanColour: boolean,
        bAuthorized: boolean,
        AuthorizedPlayers: {Player}?
    };

    export type ChatChannel_Notification = {
        SERVER: string
    };

    export type Schema_ChatChannel = {
        __index: Schema_ChatChannel,
        Notification: ChatChannel_Notification,

        new: (name: string,bAuthorized: boolean?) -> ChatChannel,
        Init: (chatCommands: ChatCommands) -> (),
        IsPlayerAuthorized: (self: ChatChannel,Players: Player) -> boolean,
        SetAuthEnabled: (self: ChatChannel,bAuthorized: boolean) -> (),
        SetPlayerAuth: (self: ChatChannel,player: Player,toAuthorize: boolean) -> (),
        FireToAuthorized: (self: ChatChannel,remote: RemoteEvent,...any) -> (),
        PostMessage: (self: ChatChannel,sender: Player,message: string) -> (),
        PostNotification: (self: ChatChannel,notification: any,message: string,players: {Player} | Player?) -> ()
    };

    export type ChatChannel = Schema_ChatChannel & Object_ChatChannel;
-- #endregion

-- #region ChatCommands

    export type Object_Command = {
        Name: string,
        Aliases: {string}?,
        Executor: (...any) -> ()
    };

    export type Schema_Command = {
        __index: any,
        ClassName: "Command",
        new: (name: string,executor: (...any) -> (),aliases: {string}?) -> Command
    };

    export type Command = Object_Command & Schema_Command;

    export type ChatCommands = {
        Prefix: string,
        CommandContainer: Dictionary<Command>,

        Init: (chatboxExtended: ChatboxExtended) -> (),
        IsCommand: (name: string) -> boolean,
        HandleCommand: (name: string,...any) -> (boolean,...any),
        RegisterCommand: (command: Command) -> (),
        LoadDefaultCommands: () -> ()
    };
-- #endregion

export type ChatboxExtended = {
    ChatChannel: Schema_ChatChannel,
    ChatCommands: ChatCommands,
    ChatChannels: {
        General: ChatChannel
    } | Dictionary<ChatChannel>,
    Init: () -> (),
    CreateChannel: (...any) -> ChatChannel,
    GetChannel: (name: string) -> ChatChannel?
};

return true;