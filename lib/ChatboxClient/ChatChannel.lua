---@module lib/Types
local Types = require(script.Parent.Parent:FindFirstChild("Types"));

type ChatboxExtended = Types.ChatboxExtendedC;
type ChatChannel = Types.ChatChannelC;

--[=[
    @class ChatChannelC
    @client

    This is the client class of ChatChannel used to post messages & notifications.
]=]
local ChatChannel = {} :: Types.Schema_ChatChannelC;
ChatChannel.__index = ChatChannel;

--[=[
    @prop Core ChatCore
    @within ChatChannelC
    @tag reference

    This property is a reference to the [ChatCore] class.
]=]
ChatChannel.Core = require(script.Parent.Parent:FindFirstChild("ChatCore"));

local ChatStyling: Types.ChatStyling = ChatChannel.Core.ChatStyling;

local Config: Types.ChatConfig = ChatChannel.Core.GetConfig();

local function createMessageLabel(text: string) : TextLabel
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
    message.TextScaled = true;
    message.TextWrapped = true;
    message.TextWrap = true;
    message.TextXAlignment = Enum.TextXAlignment.Left;
    message.Text = text;

    local UITextSizeConstraint = Instance.new("UITextSizeConstraint");
    UITextSizeConstraint.MaxTextSize = 16;
    UITextSizeConstraint.MinTextSize = 6;
    UITextSizeConstraint.Parent = message;

    message.Visible = true;
    return message;
end

--[=[
    @within ChatChannelC

    Creates a new [ChatChannel](/api/ChatChannelC) object.
]=]
function ChatChannel.new(channelName: string) : ChatChannel
    local self = {};
    --[=[
        @prop Name string
        @within ChatChannelC
        @tag object-prop

        This property is the name of the [ChatChannel](/api/ChatChannelC).
    ]=]
    self.Name = channelName;
    --[=[
        @prop Messages {TextLabel}
        @within ChatChannelC
        @tag object-prop

        This property stores the TextLabel messages for this [ChatChannel](/api/ChatChannelC).
    ]=]
    self.Messages = {};
    return setmetatable(self,ChatChannel) :: ChatChannel;
end

local ChatboxExtended: ChatboxExtended = nil;
--[=[
    @within ChatChannelC

    Initializes the client side of [ChatChannel](/api/ChatChannelC).
]=]
function ChatChannel.Init(chatboxExtended: ChatboxExtended)
    ChatboxExtended = chatboxExtended;
end

local function validateMessageLimit(chatChannel: ChatChannel)
    if #chatChannel.Messages > ((Config.MAX_MESSAGES or 30) - 1) then
        local messageLabel: TextLabel = chatChannel.Messages[1];
        if messageLabel then messageLabel:Destroy(); end
        table.remove(chatChannel.Messages,1);
    end
end

--[=[
    @method PostMessage
    @within ChatChannelC
    @param sender Player -- The player who posted this message
    @param message string -- The message that was sent

    This method posts the sent message to the [ChatChannel](/api/ChatChannelC).
]=]
function ChatChannel.PostMessage(self: ChatChannel,sender: Player,message: string)
    -- Destroy first message when exceeding chat limit
    validateMessageLimit(self);

    -- Do ChatStyling on the prefix & message
    local goldenPrefix: string = ChatStyling.ParseTextCodes("&6["..sender.Name.."]: ");
    local parsedText: string = ChatStyling.ParseTextCodes("&7"..message);

    -- Create message label and parent to ChatList
    local messageLabel: TextLabel = createMessageLabel(goldenPrefix..parsedText);
    messageLabel.Parent = ChatboxExtended.ChatUI.ChatList;
    table.insert(self.Messages,messageLabel);
end

--[=[
    @method PostNotification
    @within ChatChannelC
    @param prefix string -- The prefix for this notification
    @param message string -- The message to be posted with the notification

    This method posts the specified notification and message to the [ChatChannel](/api/ChatChannelC).
]=]
function ChatChannel.PostNotification(self: ChatChannel,prefix: string,message: string)
    -- Destroy first message when exceeding chat limit
    validateMessageLimit(self);

    -- Do ChatStyling on the prefix & message
    prefix = ChatStyling.ParseTextCodes(prefix);
    message = ChatStyling.ParseTextCodes("&7"..message);

    -- Create message label and parent to ChatList
    local messageLabel: TextLabel = createMessageLabel(prefix..message);
    messageLabel.Parent = ChatboxExtended.ChatUI.ChatList;
    table.insert(self.Messages,messageLabel);
end

return ChatChannel;

