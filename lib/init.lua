local Remotes: Folder = script:FindFirstChild("Remotes");
local PostMessageEvent: RemoteEvent = Remotes:FindFirstChild("PostMessage");

local ChatboxClient: ModuleScript,ChatboxServer: ModuleScript = script:FindFirstChild("ChatboxClient"),script:FindFirstChild("ChatboxServer");

if game:GetService("RunService"):IsServer() then
    return require(ChatboxServer);
else
    if ChatboxServer then
        ChatboxServer:Destroy();
    end
    return require(ChatboxClient);
end