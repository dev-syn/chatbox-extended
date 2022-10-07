--- @diagnostic disable: undefined-global

local game = remodel.readPlaceFile("ChatboxExtended.rbxlx");

local serviceName = table.pack(...)[1];
if serviceName then
    local QueryService = game:GetService(serviceName);

    local ChatboxExtendedUI = QueryService:FindFirstChild("ChatboxExtendedUI");
    if ChatboxExtendedUI then
        remodel.writeModelFile("lib/ChatboxClient/ChatboxExtendedUI.rbxmx",ChatboxExtendedUI);
    end
end