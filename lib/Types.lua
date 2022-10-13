export type Map<K,V> = {[K]: V};
export type Dictionary<T> = Map<string,T>;

-- #region CoreTypes
export type ChatboxCore = {
    GetConfig: () -> Dictionary<any>
};

-- #endregion

-- #region ServerTypes

-- #region ChatChannel
    export type Object_ChatChannel = {
        Name: string,
        Messages: {},
        bCanColour: boolean,
        bAuthorized: boolean,
        AuthorizedPlayers: {Player}?
    };

    export type ChatChannel_Notification = {
        SERVER: string,
        ERROR: string
    };

    export type Schema_ChatChannel = {
        __index: Schema_ChatChannel,
        Notification: ChatChannel_Notification,

        new: (name: string,bAuthorized: boolean?) -> ChatChannel,
        _Init: (chatCommands: ChatCommands) -> (),
        IsPlayerAuthorized: (self: ChatChannel,plr: Player) -> boolean,
        SetAuthEnabled: (self: ChatChannel,bAuthorized: boolean) -> (),
        SetPlayerAuth: (self: ChatChannel,plr: Player,toAuthorize: boolean) -> (),
        _FireToAuthorized: (self: ChatChannel,remote: RemoteEvent,...any) -> (),
        PostMessage: (self: ChatChannel,sender: Player,msg: string) -> (),
        PostNotification: (self: ChatChannel,notification: any,msg: string,players: {Player} | Player?) -> ()
    };

    export type ChatChannel = Schema_ChatChannel & Object_ChatChannel;
-- #endregion

-- #region ChatCommands

    export type Object_Command = {
        Name: string,
        _Aliases: {string}?,
        _Executor: (...any) -> ()
    };

    export type Schema_Command = {
        __index: any,
        ClassName: "Command",
        new: (name: string,executor: (...any) -> (),aliases: {string}?) -> Command
    };

    export type Command = Object_Command & Schema_Command;

    export type ChatCommands = {
        Prefix: string,
        _RegisteredCommands: {Command},

        Init: (chatboxExtended: ChatboxExtendedServer) -> (),
        FindCommand: (queryName: string) -> Command?,
        HandleCommand: (cmd: Command,...any) -> (boolean,...any),
        RegisterCommand: (cmd: Command) -> (),
        LoadDefaultCommands: () -> ()
    };
-- #endregion

export type ChatboxExtendedServer = {
    Core: ChatboxCore,
    ChatChannel: Schema_ChatChannel,
    ChatCommands: ChatCommands,
    ChatChannels: {
        General: ChatChannel
    } | Dictionary<ChatChannel>,
    Init: () -> (),
    CreateChannel: (...any) -> ChatChannel,
    GetChannel: (name: string) -> ChatChannel?
};

-- #endregion

-- #region ClientTypes
export type ChatboxExtendedClient = {
    ChatStyling: any,
    ActiveChannel: string?,
    Messages: Dictionary<{TextLabel}>,
    Init: () -> (),
    UI: ScreenGui,
    Background: Frame,
    ChatField: TextBox,
    ChatList: ScrollingFrame,
    ChatListLayout: UIListLayout
};
-- #endregion

return true;