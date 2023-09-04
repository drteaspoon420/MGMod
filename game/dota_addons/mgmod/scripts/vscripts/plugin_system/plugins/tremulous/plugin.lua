TremulousPlugin = class({})
_G.TremulousPlugin = TremulousPlugin

function TremulousPlugin:Init()
    print("[TremulousPlugin] found")
end

function TremulousPlugin:ApplySettings()
    TremulousPlugin.settings = PluginSystem:GetAllSetting("tremulous")
end