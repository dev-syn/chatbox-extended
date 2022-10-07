local Remotes: Folder = script:FindFirstChild("Remotes");
local PostMessageEvent: RemoteEvent = Remotes:FindFirstChild("PostMessage");

if game:GetService("RunService"):IsServer() then
    return require(script:FindFirstChild("ChatboxServer"));
else
    local ChatboxServer: ModuleScript = script:FindFirstChild("ChatboxServer");
    if ChatboxServer then
        ChatboxServer:Destroy();
    end
    return require(script:FindFirstChild("ChatboxClient"));
end