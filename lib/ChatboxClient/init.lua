local Config = require(script.Parent:FindFirstChild("ChatConfig"));

local MAX_MESSAGES: number = Config.MAX_MESSAGES or 30;

--- @module lib/ChatboxClient/Types
local Types = require(script:FindFirstChild("Types"));

--[=[
    @class ChatboxExtendedClient
    This class is for the client chat which includes chat colours, chat commands and different chat channels.
]=]
local ChatboxExtended = {} :: Types.ChatboxExtended;
local ChatStyling = require(script.Parent:FindFirstChild("ChatStyling"));
--[=[
    @prop ChatStyling ChatStyling
    @within ChatboxExtendedClient
    This property is a reference to the ChatStyling class.
]=]
ChatboxExtended.ChatStyling = ChatStyling;

--[=[
    @prop ActiveChannel string
    @within ChatboxExtendedClient
    This property stores a string which is a name of a ChatChannel or nil if not active channel.
]=]
ChatboxExtended.ActiveChannel = nil;

--[=[
    @prop Messages Dictionary<{TextLabel}>
    @within ChatboxExtendedClient
    This property is a dictionary which stores messages linked to their respective channels.
]=]
ChatboxExtended.Messages = {};

local Remotes: Folder = script.Parent:FindFirstChild("Remotes");
local PostMessage: RemoteEvent = Remotes:FindFirstChild("PostMessage") :: RemoteEvent;
local PostNotification: RemoteEvent = Remotes:FindFirstChild("PostNotification") :: RemoteEvent;

local function createMessageLabel(text: string)
    local message = Instance.new("TextLabel");
    message.Name = "message";
    message.AutomaticSize = Enum.AutomaticSize.Y;
    message.Size = UDim2.new(1, 0, 0.1, 0);
    message.BackgroundTransparency = 1;
    message.Font = Enum.Font.SourceSans;
    message.FontSize = Enum.FontSize.Size14;
    message.TextSize = 14;
    message.TextColor3 = Color3.fromRGB(255, 255, 255);
    message.RichText = true;
    message.Text = text;
    message.TextScaled = true;
    message.TextWrapped = true;
    message.TextWrap = true;
    message.TextXAlignment = Enum.TextXAlignment.Left;

    local UITextSizeConstraint = Instance.new("UITextSizeConstraint");
    UITextSizeConstraint.MaxTextSize = 16;
    UITextSizeConstraint.MinTextSize = 6;
    UITextSizeConstraint.Parent = message;

    message.Visible = true;
    return message;
end

local isInitialized: boolean = false;
--[=[
    @within ChatboxExtendedClient
    Initializes the client side of ChatboxExtended hooking the RemoteEvents and setting up the chat ui.
]=]
function ChatboxExtended.Init()
    if isInitialized then return; end
    isInitialized = true;
    ChatboxExtended.UI = script:FindFirstChild("ChatboxExtendedUI") :: ScreenGui;
    ChatboxExtended.UI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui");

    ChatboxExtended.Background = ChatboxExtended.UI:FindFirstChild("ChatBack");

    ChatboxExtended.ChatList = ChatboxExtended.Background:FindFirstChild("ChatList");
    ChatboxExtended.ChatListLayout = ChatboxExtended.ChatList:FindFirstChildOfClass("UIListLayout");

    PostNotification.OnClientEvent:Connect(function(channelName: string,prefix: string,message: string)
        -- If no channel by this name then create one
        if not ChatboxExtended.Messages[channelName] then
            ChatboxExtended.Messages[channelName] = {};
        end
        -- Destroy any messages above the max
        if #ChatboxExtended.Messages[channelName] > (MAX_MESSAGES - 1) then
            local messageLabel: TextLabel = ChatboxExtended.Messages[channelName][1];
            if messageLabel then
                messageLabel:Destroy();
            end
            table.remove(ChatboxExtended.Messages[channelName],1);
        end
        prefix = ChatStyling.ParseTextCodes(prefix);
        message = ChatStyling.ParseTextCodes("&7"..message);
        local messageLabel: TextLabel = createMessageLabel(prefix..message);
        messageLabel.Parent = ChatboxExtended.ChatList;
        table.insert(ChatboxExtended.Messages[channelName],messageLabel);
    end);

    PostMessage.OnClientEvent:Connect(function(channelName: string,sender: Player,message: string)
        -- If no channel by this name then create one
        if not ChatboxExtended.Messages[channelName] then
            ChatboxExtended.Messages[channelName] = {};
        end
        -- Destroy any messages above the max
        if #ChatboxExtended.Messages[channelName] > (MAX_MESSAGES - 1) then
            local messageLabel: TextLabel = ChatboxExtended.Messages[channelName][1];
            if messageLabel then
                messageLabel:Destroy();
            end
            table.remove(ChatboxExtended.Messages[channelName],1);
        end
        local goldenPrefix: string = ChatStyling.ParseTextCodes("&6["..sender.Name.."]: ");
        -- Create message label
        local parsedText: string = ChatStyling.ParseTextCodes("&7"..message);
        local messageLabel: TextLabel = createMessageLabel(goldenPrefix..parsedText);
        messageLabel.Parent = ChatboxExtended.ChatList;
        table.insert(ChatboxExtended.Messages[channelName],messageLabel);
    end);

    ChatboxExtended.ChatField = ChatboxExtended.Background:FindFirstChild("ChatField") :: TextBox;
    ChatboxExtended.ChatField.FocusLost:Connect(function(enterPressed: boolean,inputObject: InputObject)
        if enterPressed then
            if ChatboxExtended.ChatField.Text == "" or #ChatboxExtended.ChatField.Text > (Config.MAX_CHAR or 100) then
                return;
            end
            PostMessage:FireServer(ChatboxExtended.ActiveChannel or "General",ChatboxExtended.ChatField.Text);
            ChatboxExtended.ChatField.Text = "";
        end
    end);
    game:GetService("UserInputService").InputBegan:Connect(function(input: InputObject,gamePro: boolean)
        -- Only proccess input if it's from game and not ui
        if gamePro then return; end
        if input.KeyCode == Enum.KeyCode.Slash then
            if ChatboxExtended.ChatField:IsFocused() then
                ChatboxExtended.ChatField:ReleaseFocus(false);
            else
                game:GetService("RunService").Heartbeat:Wait();
                ChatboxExtended.ChatField:CaptureFocus();
            end
        end
    end);
    ChatboxExtended.UI.Enabled = true;
end

return ChatboxExtended;