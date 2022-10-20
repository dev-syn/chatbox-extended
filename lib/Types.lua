export type Map<K,V> = {[K]: V};
export type Dictionary<T> = Map<string,T>;

local Dependencies: Folder = script.Parent:FindFirstChild("Dependencies");
---@module Packages/TextStyling
local TextStylingClass = require(Dependencies:FindFirstChild("TextStyling"));
export type TextStyling = TextStylingClass.TextStyling;

-- Ctrl + K,Ctrl + 0 - Fold
-- Ctrl + K,Ctrl + J - Unfold


-- #region CoreTypes
    -- #region ChatConfig
        export type ChatConfig = {
            MAX_MESSAGES_SERVER: number?,
            MAX_MESSAGES: number?,
            MAX_CHAR: number?,
            MAX_CACHED_MESSAGES: number?,
            FOCUS_CHAT_KEY: Enum.KeyCode?,
            DEFAULT_CHANNEL: string?
        };
    -- #endregion

    -- #region ChatCommands
        -- #region Command
            export type Object_Command = {
                Name: string,
                _Aliases: {string}?,
                _Executor: (...any) -> ()
            };

            export type Schema_Command = {
                __index: any,
                __type: "Command",
                ClassName: string,

                new:<Return> (name: string,executor: (sender: Player,...any) -> ()?,aliases: {string}?) -> Return
            };

            export type Command = Object_Command & Schema_Command;
        -- #endregion

        -- #region RealmCommand
            export type Object_RealmCommand = Object_Command & {
                RemoteEvent: RemoteEvent
            };

            export type Schema_RealmCommand = Schema_Command & {
                Init: (chatCommands: ChatCommands) -> (),
                SetServerHandler: (self: RealmCommand,fn: (plr: Player,...any) -> ()) -> RBXScriptConnection,
                SetClientHandler: (self: RealmCommand,fn: (...any) -> ()) -> RBXScriptConnection
            };

            export type RealmCommand = Object_RealmCommand & Schema_RealmCommand;
        -- #endregion

        export type ChatCommands = {
            Command: Schema_Command,
            RealmCommand: Schema_RealmCommand,
            Prefix: string,
            _RegisteredCommands: {Command | RealmCommand},

            Init: (chatboxExtended: ChatboxExtended | ChatboxExtendedC) -> (),
            FindCommand: (queryName: string) -> (Command | RealmCommand)?,
            HandleCommand: (cmd: Command | RealmCommand,...any) -> (boolean,...any),
            RegisterCommand: (cmd: Command | RealmCommand) -> (),
            LoadDefaultCommands: (cmds: {Command | RealmCommand}?) -> ()
        };
    -- #endregion

    export type ReplicationAction = {
        CREATE: number,
        DESTROY: number
    };

    export type ChatboxCore = {
        ReplicationAction: ReplicationAction,
        ChatCommands: ChatCommands,
        Dependencies: Folder,
        TextStyling: TextStyling,
        Config: ChatConfig,

        GetConfig: () -> ChatConfig,
        SetConfig: (config: ChatConfig) -> (),
        FindChatChannel: (chatboxExtended: ChatboxExtended | ChatboxExtendedC,name: string) -> (ChatChannel | ChatChannelC,number),
        _FormatOut: (prefix: string,...any) -> string
    };

-- #endregion


-- #region ServerTypes
    -- #region ChatChannel
        export type Object_ChatChannel = {
            Name: string,
            _Messages: {string},
            _bCanColour: boolean,
            _bAuthorized: boolean,
            _AuthorizedPlayers: {Player}?,
            ChatMonitor: ChatMonitor
        };

        export type ChatChannel_Notification = {
            SERVER: string,
            ERROR: string
        };

        export type Schema_ChatChannel = {
            __index: Schema_ChatChannel,
            Core: ChatboxCore,
            Notification: ChatChannel_Notification,

            new: (name: string,bAuthorized: boolean?) -> ChatChannel,
            _Init: (chatboxExtended: ChatboxExtended) -> (),
            IsPlayerAuthorized: (self: ChatChannel,plr: Player) -> boolean,
            SetAuthEnabled: (self: ChatChannel,bAuthorized: boolean) -> (),
            SetPlayerAuth: (self: ChatChannel,plr: Player,toAuthorize: boolean) -> (),
            _FireToAuthorized: (self: ChatChannel,remote: RemoteEvent,...any) -> (),
            PostMessage: (self: ChatChannel,sender: Player,msg: string) -> (),
            PostNotification: (self: ChatChannel,prefix: string,msg: string,players: {Player} | Player?) -> (),
            Destroy: (self: ChatChannel) -> (),
            _PlayerRemovingHandler: (self: ChatChannel,plr: Player) -> ()
        };

        export type ChatChannel = Schema_ChatChannel & Object_ChatChannel;
    -- #endregion

    -- #region ChatMonitor
        export type Object_ChatMonitor = {
            _CachedMessages: Map<Player,{string}>,
            _MutedPlayers: {Player},
            _ChannelName: string,
            _LastMessageStamps: Map<Player,number>
        };
        export type Schema_ChatMonitor = {
            __index: Schema_ChatMonitor,
            _GMutedPlayers: {Player},

            _Init: (chatboxExtended: ChatboxExtended) -> (),
            new: (channelName: string) -> ChatMonitor,
            MutePlayer: (self: ChatMonitor,plr: Player,toMute: boolean,global: boolean?) -> (),
            VerifySimilarity: (a: string,b: string) -> number,
            Validate: (self: ChatMonitor,sender: Player,message: string) -> boolean,
            _PlayerRemovingHandler: (self: ChatMonitor,plr: Player) -> ()
        };
        export type ChatMonitor = Schema_ChatMonitor & Object_ChatMonitor;
    -- #endregion

    export type ChatboxExtended = {
        Core: ChatboxCore,
        ChatChannel: Schema_ChatChannel,
        _ChatChannels: {ChatChannel},
        Init: () -> (),
        CreateChannel: (channelName: string,bAuthorized: boolean?) -> ChatChannel,
        PostNotification: (channelName: string,plr: Player,prefix: string,msg: string) -> (),
        PostError: (channelName: string?,plr: Player,msg: string) -> (),
        FilterText: (sender: Player,text: string) -> string?
    };

-- #endregion
  

-- #region ClientTypes

    -- #region ChatChannel
    export type Schema_ChatChannelC = {
        __index: any,
        Core: ChatboxCore,

        new: (channelName: string) -> ChatChannelC,
        Init: (chatboxExtended: ChatboxExtendedC) -> (),
        PostMessage: (self: ChatChannelC,sender: Player,message: string) -> (),
        PostNotification: (self: ChatChannelC,prefix: string,message: string) -> ()
    };

    export type Object_ChatChannelC = {
        Name: string,
        Messages: {TextLabel}
    };

    export type ChatChannelC = Schema_ChatChannelC & Object_ChatChannelC;
    -- #endregion

    -- #region ChatUI
        export type ChatUI = {
            UI: ScreenGui,
            ChatBack: Frame?,
            ChatList: ScrollingFrame,
            ChatListLayout: UIListLayout,
            ChannelSelector: Frame,
            ChannelNameB: TextButton,
            NextChannelB: TextButton,
            PrevChannelB: TextButton,
            ChatField: TextBox,

            _Init: (chatboxExtended: ChatboxExtendedC,chatboxExtendedUI: ScreenGui) -> (),
            AssignUI: (chatboxExtendedUI: ScreenGui) -> ()
        };
    -- #endregion
    export type ChatboxExtendedC = {
        Core: ChatboxCore,
        _ChatChannels: {ChatChannelC},
        ActiveChannel: ChatChannelC?,
        Messages: Dictionary<{TextLabel}>,
        ChatUI: ChatUI,

        _FocusLostHandler: (enterPressed: boolean) -> (),
        _NextChannelHandler: () -> (),
        _PrevChannelHandler: () -> (),
        Init: () -> (),
        YieldTillChannel: (name: string,timeOut: number?) -> ChatChannelC
    };
-- #endregion


return true;