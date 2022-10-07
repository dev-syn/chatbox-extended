local MAX_MESSAGES: number = 30;

--- @module lib/ChatboxClient/Types
local Types = require(script:FindFirstChild("Types"));

local ChatboxExtended = {} :: Types.ChatboxExtended;
local ChatStyling = require(script.Parent:FindFirstChild("ChatStyling"));
ChatboxExtended.ChatStyling = ChatStyling;

ChatboxExtended.ActiveChannel = nil;

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
function ChatboxExtended.Init()
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
            PostMessage:FireServer(ChatboxExtended.ActiveChannel or "General",ChatboxExtended.ChatField.Text);
            ChatboxExtended.ChatField.Text = "";
        end
    end);
    ChatboxExtended.UI.Enabled = true;
end

return ChatboxExtended;