--- @module ChatboxExtended/lib/Types
local Types = require(script.Parent.Parent:FindFirstChild("Types"));

--[=[
    @class ChatUI
    @client

    This class is designed to contain the [ChatboxExtended](/api/ChatboxExtendedC) ChatUI references
    and to allow overriding the default UI.

    The ChatUI Instance hierarchy is as follows:

    ```
    UI (ScreenGui)
    ChatBack (Frame?) - Optional
        ChannelSelector (Frame)
            ChannelNameB (TextButton)
            NextChannelB (TextButton)
            PrevChannelB (TextButton)
        ChatList (ScrollingFrame)
            UIListLayout (UIListLayout?) - Optional
        ChatField (TextBox)
    ```
]=]
local ChatUI = {} :: Types.ChatUI;

local ChatboxExtended: Types.ChatboxExtendedC;
local Core: Types.ChatboxCore;
function ChatUI._Init(chatboxExtended: Types.ChatboxExtendedC,chatboxExtendedUI: ScreenGui)
    ChatboxExtended = chatboxExtended;
    Core = chatboxExtended.Core;
    ChatUI.AssignUI(chatboxExtendedUI);
end

local focusLostListener: RBXScriptConnection?;
local nextChannelListener: RBXScriptConnection?;
local prevChannelListener: RBXScriptConnection?;

local ERROR_INVALID_ASSIGN: string = "Failed to assign invalid UI for '%s' got %s; expected %s.";
--[=[
    @within ChatUI

    This function when called will take the passed ScreenGui
    and verify all the proper UI Instances for a valid ChatUI.

    :::caution

    > This method will **throw** if the UI is incompatible with the ChatUI default hierarchy.

    :::
]=]
function ChatUI.AssignUI(chatboxExtendedUI: ScreenGui)
    local chatUIType: string = typeof(chatboxExtendedUI);
    if chatUIType ~= "Instance" or not chatboxExtendedUI:IsA("ScreenGui") then
        if chatUIType == "Instance" then chatUIType = chatboxExtendedUI.ClassName; end
        error(Core._FormatOut("ChatUI",string.format(ERROR_INVALID_ASSIGN,"ChatboxExtendedUI",chatUIType,"ScreenGui")),2);
    end

    --[=[
        @prop UI ScreenGui
        @within ChatUI

        This property stores a [ScreenGui] which represents the ChatboxExtendedUI.
    ]=]
    ChatUI.UI = chatboxExtendedUI;
    local ChatBack: (Frame?) | ScreenGui = chatboxExtendedUI:FindFirstChild("ChatBack")::Frame?;

    --[=[
        @prop ChatBack Frame?
        @within ChatUI

        This property stores a [Frame] or nil which represents the chat background.

        :::note

        > This is an optional property and is not required.

        :::
    ]=]
    if ChatBack then ChatUI.ChatBack = ChatBack::Frame; else ChatBack = chatboxExtendedUI::ScreenGui; end
    -- ChatList
    local ChatList: ScrollingFrame? = ChatBack:FindFirstChild("ChatList")::ScrollingFrame?;
    if not ChatList or not ChatList:IsA("ScrollingFrame") then
        error(Core._FormatOut("ChatUI",string.format(ERROR_INVALID_ASSIGN,"ChatList",ChatList and ChatList.ClassName or "nil","ScrollingFrame")),2);
    end

    --[=[
        @prop ChatList ScrollingFrame
        @within ChatUI

        This property stores a [ScrollingFrame] which represents the list of chats.
    ]=]
    ChatUI.ChatList = ChatList::ScrollingFrame;
    local ChatListLayout: UIListLayout? = ChatList:FindFirstChildOfClass("UIListLayout")::UIListLayout?;
    if not ChatListLayout then
        ChatListLayout = Instance.new("UIListLayout");
        ChatListLayout.Padding = UDim.new(0,6);
        ChatListLayout.Parent = ChatList;
    end

    --[=[
        @prop ChatListLayout UIListLayout
        @within ChatUI

        This property stores a UIListLayout which is used to layout the chat messages.

        :::note

        > This is an optional property and is not required and will be auto-assigned.

        :::
    ]=]
    ChatUI.ChatListLayout = ChatListLayout::UIListLayout;

    local ChannelSelector: Frame? = ChatBack:FindFirstChild("ChannelSelector") :: Frame?;
    if not ChannelSelector or not ChannelSelector:IsA("Frame") then
        error(Core._FormatOut("ChatUI",string.format(ERROR_INVALID_ASSIGN,"ChannelSelector",ChannelSelector and ChannelSelector.ClassName or "nil","Frame")));
    end
    --[=[
        @prop ChannelSelector Frame
        @within ChatUI

        This property stores a [Frame] which represents the back frame of the channel selector UI.
    ]=]
    ChatUI.ChannelSelector = ChannelSelector;

    local ChannelNameB: TextButton? = ChannelSelector:FindFirstChild("ChannelNameB") :: TextButton?;
    if not ChannelNameB or not ChannelNameB:IsA("TextButton") then
        error(Core._FormatOut("ChatUI",string.format(ERROR_INVALID_ASSIGN,"ChannelNameB",ChannelNameB and ChannelNameB.ClassName or "nil","TextButton")));
    end
    --[=[
        @prop ChannelNameB TextButton
        @within ChatUI

        This property stores a [TextButton] which displays the active channels name.
    ]=]
    ChatUI.ChannelNameB = ChannelNameB::TextButton;

    local NextChannelB: TextButton? = ChannelSelector:FindFirstChild("NextChannelB") :: TextButton?;
    if not NextChannelB or not NextChannelB:IsA("TextButton") then
        error(Core._FormatOut("ChatUI",string.format(ERROR_INVALID_ASSIGN,"NextChannelB",NextChannelB and NextChannelB.ClassName or "nil","TextButton")));
    end
    --[=[
        @prop NextChannelB TextButton
        @within ChatUI

        This property stores a [TextButton] which is used to traverse to the next [ChatChannel](/api/ChatChannelC).
    ]=]
    ChatUI.NextChannelB = NextChannelB::TextButton;

    local PrevChannelB: TextButton? = ChannelSelector:FindFirstChild("PrevChannelB") :: TextButton?;
    if not PrevChannelB or not PrevChannelB:IsA("TextButton") then
        error(Core._FormatOut("ChatUI",string.format(ERROR_INVALID_ASSIGN,"PrevChannelB",PrevChannelB and PrevChannelB.ClassName or "nil","TextButton")));
    end
    --[=[
        @prop PrevChannelB TextButton
        @within ChatUI

        This property stores a [TextButton] which is used to traverse to the previous [ChatChannel](/api/ChatChannelC).
    ]=]
    ChatUI.PrevChannelB = PrevChannelB::TextButton;

    local ChatField: TextBox? = ChatBack:FindFirstChild("ChatField") :: TextBox?;
    if not ChatField or not ChatField:IsA("TextBox") then
        error(Core._FormatOut("ChatUI",string.format(ERROR_INVALID_ASSIGN,"ChatField",ChatField and ChatField.ClassName or "nil","TextBox")));
    end
    --[=[
        @prop ChatField TextBox
        @within ChatUI

        This property stores a [TextBox] which is used to input messages/commands.
    ]=]
    ChatUI.ChatField = ChatField::TextBox;

    if focusLostListener then focusLostListener:Disconnect(); end
    focusLostListener = ChatField.FocusLost:Connect(ChatboxExtended._FocusLostHandler);
    if nextChannelListener then nextChannelListener:Disconnect(); end
    nextChannelListener = NextChannelB.MouseButton1Click:Connect(ChatboxExtended._NextChannelHandler);
    if prevChannelListener then prevChannelListener:Disconnect(); end
    prevChannelListener = PrevChannelB.MouseButton1Click:Connect(ChatboxExtended._PrevChannelHandler);

    ChatUI.UI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui");
end

return ChatUI;