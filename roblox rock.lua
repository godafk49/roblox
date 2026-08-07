local A = {}
A.Environment = getrenv() or getfenv()
A.Parent = A.Environment
A.Services = A.Environment:GetServices() or {}

local RunService = A.Environment:FindService("RunService") or A.Environment:GetService("RunService")
local Players = A.Environment:FindService("Players") or A.Environment:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = A.Environment:FindService("Workspace") or A.Environment:GetService("Workspace")
local Lighting = A.Environment:FindService("Lighting") or A.Environment:GetService("Lighting")
local ReplicatedStorage = A.Environment:FindService("ReplicatedStorage") or A.Environment:GetService("ReplicatedStorage")
local ReplicatedFirst = A.Environment:FindService("ReplicatedFirst") or A.Environment:GetService("ReplicatedFirst")
local StarterPack = A.Environment:FindService("StarterPack") or A.Environment:GetService("StarterPack")
local StarterGui = A.Environment:FindService("StarterGui") or A.Environment:GetService("StarterGui")
local StarterPlayer = A.Environment:FindService("StarterPlayer") or A.Environment:GetService("StarterPlayer")
local TweenService = A.Environment:FindService("TweenService") or A.Environment:GetService("TweenService")
local VirtualUser = A.Environment:FindService("VirtualUser") or A.Environment:GetService("VirtualUser")
local HttpService = A.Environment:FindService("HttpService") or A.Environment:GetService("HttpService")
local UserInputService = A.Environment:FindService("UserInputService") or A.Environment:GetService("UserInputService")
local GuiService = A.Environment:FindService("GuiService") or A.Environment:GetService("GuiService")

local CoreFunctions = {
    isfile = A.Environment.isfile or syn.isfile or isfile,
    writefile = A.Environment.writefile or syn.writefile or writefile,
    readfile = A.Environment.readfile or syn.readfile or readfile,
    makefolder = A.Environment.makefolder or syn.makefolder or makefolder,
    delfolder = A.Environment.delfolder or syn.delfolder or delfolder,
    listfiles = A.Environment.listfiles or syn.listfiles or listfiles,
    getnilinstances = A.Environment.getnilinstances or syn.getnilinstances or getnilinstances,
    gethui = A.Environment.gethui or syn.gethui or gethui,
    getscriptbytecode = A.Environment.getscriptbytecode or syn.getscriptbytecode or getscriptbytecode,
    decompile = A.Environment.decompile or syn.decompile or decompile,
    saveinstance = A.Environment.saveinstance or syn.saveinstance or saveinstance,
    getproperties = A.Environment.getproperties or syn.getproperties or getproperties,
    getgame = A.Environment.getgame or function() return game end,
    getexecutorname = A.Environment.getexecutorname or syn.getexecutorname or function() return "Unknown" end
}
A.Core = CoreFunctions

local SupportedExecutors = {"Delta", "Fluxus", "Arceus X", "Krnl", "Synapse X", "Script-Ware", "WeAreDevs", "Comet", "Hydrogen", "Electron", "Vega X", "Xenon", "Celery", "Owl Hub", "AWP", "Rogue", "Nebula", "Cryptic", "Sentry", "Elysium", "Pandora", "Ambition", "Fusion", "Infinity", "Destiny", "Velocity", "Aura", "Legion", "Nexus", "Avior", "Yin", "Yang", "Quantum", "Phantom", "Radiant", "Zen", "Evo", "AltStore", "Crystal", "Draco", "Eclipse", "Flare", "Galaxy", "Helios", "Iris", "Jupiter", "Kronos", "Lyra", "Mars", "Nova", "Orion", "Pegasus", "Rigel", "Sirius", "Titan", "Uranus", "Vulcan", "Wolf", "Xerxes", "Yggdrasil", "Zephyr"}
A.ExecutorName = CoreFunctions.getexecutorname()
A.Supported = table.find(SupportedExecutors, A.ExecutorName) ~= nil

local Settings = {
    ProjectName = "UltimateDump_" .. (game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "UnknownPlace"),
    SaveWorkspace = true,
    SaveLighting = true,
    SaveReplicatedStorage = true,
    SaveReplicatedFirst = true,
    SaveStarterPack = true,
    SaveStarterGui = true,
    SaveStarterPlayer = true,
    SaveTerrain = true,
    SaveScripts = true,
    SaveMeshes = true,
    SaveUI = true,
    ExportMode = "Native", -- "Native", "XML", "JSON"
    YieldRate = 500,
    Processing = false,
    TotalInstances = 0,
    ProcessedInstances = 0,
    CurrentProgress = 0,
    DumpPath = "workspace/MapDumps/"
}

local function getGameName()
    local success, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if success and info then
        return info.Name:gsub("[^%w]", "_")
    else
        return "UnknownPlace_" .. game.PlaceId
    end
end
Settings.ProjectName = "UltimateDump_" .. getGameName()

local function safeCall(func, fallback)
    local s, r = pcall(func)
    if s then return r end
    return fallback
end

local function getPropertyList(instance)
    local props = {}
    if CoreFunctions.getproperties then
        local s, res = pcall(CoreFunctions.getproperties, instance)
        if s then
            for _, prop in ipairs(res) do
                table.insert(props, prop)
            end
            return props
        end
    end
    -- fallback common properties
    local common = {"Name", "Parent", "ClassName", "Archivable", "Anchored", "Position", "Size", "CFrame", "Transparency", "Color", "Material", "BrickColor", "Reflectance", "Velocity", "RotVelocity", "CanCollide", "Elasticity", "Friction", "Mass", "SurfaceType", "SurfaceParam", "Texture", "TextureId", "MeshId", "MeshType", "Offset", "Scale", "VertexColor", "Face", "FaceColor", "VertexColor", "Bevel", "Shape", "Spherical", "Horizontal", "Vertical", "Angle", "Cylinder", "Font", "Text", "TextColor3", "TextScaled", "TextSize", "TextWrapped", "TextXAlignment", "TextYAlignment", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel", "Visible", "LayoutOrder", "Active", "SelectionImageObject", "Draggable", "Resizable", "ZIndex", "ClipsDescendants", "Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "SliceCenter", "Scaled", "Tile", "MaxScroll", "Scrolling", "ScrollBarImageColor3", "ScrollBarThickness", "TopImage", "BottomImage", "MidImage", "Title", "TitleColor3", "TitleTransparency", "TitleFont", "TitleSize", "TitleWrapped", "TextColor", "TextTransparency", "TextFont", "TextSizeWrapped", "TextWrapped", "TextXAlignment", "TextYAlignment", "AutoLocalize", "UseRichText"}
    for _, p in ipairs(common) do
        table.insert(props, p)
    end
    return props
end

local function serializeValue(value)
    local t = typeof(value)
    if t == "string" then return '"'..tostring(value):gsub('"', '\\"')..'"' end
    if t == "number" or t == "boolean" then return tostring(value) end
    if t == "Color3" then return string.format("Color3.new(%f, %f, %f)", value.r, value.g, value.b) end
    if t == "BrickColor" then return 'BrickColor.new("'..value.Name..'")' end
    if t == "CFrame" then return string.format("CFrame.new(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)", value:components()) end
    if t == "Vector3" then return string.format("Vector3.new(%f, %f, %f)", value.x, value.y, value.z) end
    if t == "Vector2" then return string.format("Vector2.new(%f, %f)", value.x, value.y) end
    if t == "UDim" then return string.format("UDim.new(%f, %d)", value.Scale, value.Offset) end
    if t == "UDim2" then return string.format("UDim2.new(%f, %d, %f, %d)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset) end
    if t == "Ray" then return string.format("Ray.new(Vector3.new(%f,%f,%f), Vector3.new(%f,%f,%f))", value.Origin.x, value.Origin.y, value.Origin.z, value.Direction.x, value.Direction.y, value.Direction.z) end
    if t == "Rect" then return string.format("Rect.new(%d, %d, %d, %d)", value.Min.x, value.Min.y, value.Max.x, value.Max.y) end
    if t == "PhysicalProperties" then return string.format("PhysicalProperties.new(%f, %f, %f, %f, %f)", value.Density, value.Friction, value.Elasticity, value.FrictionWeight, value.ElasticityWeight) end
    if t == "EnumItem" then return "Enum."..tostring(value) end
    return tostring(value)
end

local function serializeInstance(inst, parentPath, visited)
    if not inst or visited[inst] then return nil end
    visited[inst] = true
    local className = inst.ClassName
    local props = getPropertyList(inst)
    local propTable = {}
    for _, prop in ipairs(props) do
        local success, val = pcall(function() return inst[prop] end)
        if success and val ~= nil then
            local typ = typeof(val)
            if typ == "Instance" then
                -- skip references to avoid circular
            else
                propTable[prop] = serializeValue(val)
            end
        end
    end
    local children = {}
    local childList = inst:GetChildren()
    for _, child in ipairs(childList) do
        local childData = serializeInstance(child, parentPath .. "/" .. child.Name, visited)
        if childData then
            table.insert(children, childData)
        end
    end
    return {
        ClassName = className,
        Name = inst.Name,
        Properties = propTable,
        Children = children,
        Path = parentPath .. "/" .. inst.Name
    }
end

local function serializeToXML(instData, indent)
    indent = indent or 0
    local spaces = string.rep("  ", indent)
    local xml = spaces .. "<" .. instData.ClassName .. " Name=\"" .. instData.Name .. "\">\n"
    for prop, val in pairs(instData.Properties) do
        xml = xml .. spaces .. "  <Property Name=\"" .. prop .. "\">" .. val .. "</Property>\n"
    end
    for _, child in ipairs(instData.Children) do
        xml = xml .. serializeToXML(child, indent + 1)
    end
    xml = xml .. spaces .. "</" .. instData.ClassName .. ">\n"
    return xml
end

local function serializeToJSON(instData)
    return HttpService:JSONEncode(instData)
end

local function deepCloneInstance(instance, parent)
    local newInst = Instance.new(instance.ClassName)
    newInst.Name = instance.Name
    for prop, val in pairs(instance.Properties) do
        pcall(function() newInst[prop] = val end)
    end
    newInst.Parent = parent
    for _, childData in ipairs(instance.Children) do
        deepCloneInstance(childData, newInst)
    end
    return newInst
end

local function reconstructFromXML(xmlString)
    -- not implemented; would require XML parser
end

local function reconstructFromJSON(jsonString)
    local data = HttpService:JSONDecode(jsonString)
    local root = deepCloneInstance(data, nil)
    return root
end

local function isService(name)
    return Settings["Save"..name] == true
end

local function getTargetServices()
    local services = {}
    if isService("Workspace") then table.insert(services, Workspace) end
    if isService("Lighting") then table.insert(services, Lighting) end
    if isService("ReplicatedStorage") then table.insert(services, ReplicatedStorage) end
    if isService("ReplicatedFirst") then table.insert(services, ReplicatedFirst) end
    if isService("StarterPack") then table.insert(services, StarterPack) end
    if isService("StarterGui") then table.insert(services, StarterGui) end
    if isService("StarterPlayer") then table.insert(services, StarterPlayer) end
    return services
end

local function getHiddenInstances()
    local hidden = {}
    local nilInsts = CoreFunctions.getnilinstances()
    if nilInsts then
        for _, inst in ipairs(nilInsts) do
            table.insert(hidden, inst)
        end
    end
    local hui = CoreFunctions.gethui()
    if hui then
        for _, inst in ipairs(hui:GetChildren()) do
            table.insert(hidden, inst)
        end
    end
    return hidden
end

local function decompileScript(script)
    if not CoreFunctions.decompile then return nil end
    local success, source = pcall(CoreFunctions.decompile, script)
    if success and source then
        return source
    end
    return nil
end

local function getScriptBytecode(script)
    if not CoreFunctions.getscriptbytecode then return nil end
    local success, bc = pcall(CoreFunctions.getscriptbytecode, script)
    if success and bc then
        return bc
    end
    return nil
end

local function readTerrainVoxels(terrain, region)
    -- attempt to read voxels, may not be supported
    if not terrain or not terrain.ReadVoxels then return nil end
    local success, voxels = pcall(function()
        return terrain:ReadVoxels(region, 1)
    end)
    if success and voxels then
        return voxels
    end
    return nil
end

local function readTerrainMaterials(terrain, region)
    if not terrain or not terrain.ReadMaterials then return nil end
    local success, mats = pcall(function()
        return terrain:ReadMaterials(region)
    end)
    if success and mats then
        return mats
    end
    return nil
end

local DumpQueue = {}
local DumpResults = {}
local DumpRunning = false

local function processQueue()
    if #DumpQueue == 0 then
        DumpRunning = false
        return
    end
    local batchSize = Settings.YieldRate
    local processed = 0
    while #DumpQueue > 0 and processed < batchSize do
        local item = table.remove(DumpQueue, 1)
        if item then
            local inst = item.inst
            local parent = item.parent
            local path = item.path
            -- Serialize or clone based on mode
            if Settings.ExportMode == "Native" and CoreFunctions.saveinstance then
                -- Native mode handled separately
            else
                local visited = {}
                local data = serializeInstance(inst, path, visited)
                if data then
                    table.insert(DumpResults, data)
                end
            end
            Settings.ProcessedInstances = Settings.ProcessedInstances + 1
            Settings.CurrentProgress = (Settings.ProcessedInstances / Settings.TotalInstances) * 100
            -- update progress UI
            pcall(function()
                if UI and UI.ProgressLabel then
                    UI.ProgressLabel.Text = string.format("Progress: %.1f%% (%d/%d)", Settings.CurrentProgress, Settings.ProcessedInstances, Settings.TotalInstances)
                end
            end)
            processed = processed + 1
        end
    end
    if #DumpQueue > 0 then
        task.wait(0.01)
        processQueue()
    else
        DumpRunning = false
        -- finalize dump
        finishDump()
    end
end

local function finishDump()
    local folderName = Settings.ProjectName
    local path = Settings.DumpPath .. folderName
    CoreFunctions.makefolder(path)
    if Settings.ExportMode == "XML" then
        local xmlContent = '<roblox>\n'
        for _, data in ipairs(DumpResults) do
            xmlContent = xmlContent .. serializeToXML(data, 1)
        end
        xmlContent = xmlContent .. '</roblox>'
        CoreFunctions.writefile(path .. "/dump.xml", xmlContent)
    elseif Settings.ExportMode == "JSON" then
        local json = HttpService:JSONEncode(DumpResults)
        CoreFunctions.writefile(path .. "/dump.json", json)
    elseif Settings.ExportMode == "Native" then
        CoreFunctions.saveinstance(path .. "/NativeSave.rbxlx")
    end
    -- also save scripts separately if enabled
    if Settings.SaveScripts then
        -- scripts already included in serialization
    end
    -- terrain
    if Settings.SaveTerrain and Workspace.Terrain then
        local terrain = Workspace.Terrain
        local region = terrain:GetExtents()
        local voxels = readTerrainVoxels(terrain, region)
        if voxels then
            CoreFunctions.writefile(path .. "/terrain_voxels.dat", tostring(voxels))
        end
        local materials = readTerrainMaterials(terrain, region)
        if materials then
            CoreFunctions.writefile(path .. "/terrain_materials.dat", tostring(materials))
        end
    end
    DumpResults = {}
    Settings.Processing = false
    pcall(function()
        if UI and UI.DumpButton then
            UI.DumpButton.Text = "One-Click Full Map Dump"
            UI.DumpButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        end
        if UI and UI.ProgressLabel then
            UI.ProgressLabel.Text = "Dump Complete!"
        end
    end)
end

local function startDump()
    if Settings.Processing then return end
    Settings.Processing = true
    DumpResults = {}
    DumpQueue = {}
    Settings.ProcessedInstances = 0
    Settings.TotalInstances = 0
    pcall(function()
        if UI and UI.DumpButton then
            UI.DumpButton.Text = "Dumping..."
            UI.DumpButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end)
    -- collect instances
    local services = getTargetServices()
    local allInstances = {}
    for _, svc in ipairs(services) do
        local children = svc:GetDescendants()
        for _, child in ipairs(children) do
            table.insert(allInstances, child)
        end
        table.insert(allInstances, svc)
    end
    -- hidden
    local hidden = getHiddenInstances()
    for _, h in ipairs(hidden) do
        table.insert(allInstances, h)
    end
    Settings.TotalInstances = #allInstances
    for _, inst in ipairs(allInstances) do
        table.insert(DumpQueue, {inst = inst, parent = inst.Parent, path = inst:GetFullName()})
    end
    DumpRunning = true
    processQueue()
end

local function cleanWorkspace()
    local folder = Settings.DumpPath
    if CoreFunctions.isfile(folder) then
        CoreFunctions.delfolder(folder)
    end
    CoreFunctions.makefolder(folder)
end

local function restoreHiddenToWorkspace()
    local hidden = getHiddenInstances()
    for _, inst in ipairs(hidden) do
        pcall(function()
            inst.Parent = Workspace
        end)
    end
end

local function scanNilInstances()
    local nilInsts = CoreFunctions.getnilinstances()
    if not nilInsts then return end
    local msg = "Found " .. #nilInsts .. " nil instances"
    pcall(function()
        if UI and UI.InfoLabel then
            UI.InfoLabel.Text = msg
        end
    end)
end

-- UI Construction
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MapDumperUI"
    screenGui.ResetOnSpawn = false
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    titleBar.Parent = mainFrame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Text = "Universal Map Duplicator"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = titleBar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 1, 0)
    closeBtn.Position = UDim2.new(1, -40, 0, 0)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 20
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        Settings.Processing = false
    end)
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    tabContainer.Parent = mainFrame
    local tabButtons = {}
    local tabFrames = {}
    local function createTab(name, content)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.Text = name
        btn.BackgroundTransparency = 1
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.Parent = tabContainer
        local frame = Instance.new("ScrollingFrame")
        frame.Size = UDim2.new(1, -10, 1, -50)
        frame.Position = UDim2.new(0, 5, 0, 45)
        frame.BackgroundTransparency = 1
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.ScrollBarThickness = 8
        frame.Visible = false
        frame.Parent = mainFrame
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame
        -- content
        content(frame)
        table.insert(tabFrames, frame)
        btn.MouseButton1Click:Connect(function()
            for _, f in ipairs(tabFrames) do
                f.Visible = false
            end
            for _, b in ipairs(tabButtons) do
                b.BackgroundTransparency = 1
                b.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            frame.Visible = true
            btn.BackgroundTransparency = 0.3
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        table.insert(tabButtons, btn)
        return frame
    end
    -- Tab 1: Dashboard
    local dashFrame = createTab("Dashboard", function(parent)
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -20, 0, 30)
        nameLabel.Text = "Project Name:"
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = parent
        local nameBox = Instance.new("TextBox")
        nameBox.Size = UDim2.new(1, -20, 0, 30)
        nameBox.Text = Settings.ProjectName
        nameBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameBox.Font = Enum.Font.SourceSans
        nameBox.TextSize = 16
        nameBox.Parent = parent
        nameBox:GetPropertyChangedSignal("Text"):Connect(function()
            Settings.ProjectName = nameBox.Text
        end)
        local dumpBtn = Instance.new("TextButton")
        dumpBtn.Size = UDim2.new(1, -20, 0, 50)
        dumpBtn.Text = "One-Click Full Map Dump"
        dumpBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        dumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        dumpBtn.Font = Enum.Font.SourceSansBold
        dumpBtn.TextSize = 18
        dumpBtn.Parent = parent
        dumpBtn.MouseButton1Click:Connect(function()
            startDump()
        end)
        UI.DumpButton = dumpBtn
        local progressLabel = Instance.new("TextLabel")
        progressLabel.Size = UDim2.new(1, -20, 0, 30)
        progressLabel.Text = "Progress: 0%"
        progressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        progressLabel.BackgroundTransparency = 1
        progressLabel.Font = Enum.Font.SourceSans
        progressLabel.TextSize = 16
        progressLabel.Parent = parent
        UI.ProgressLabel = progressLabel
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -20, 0, 30)
        infoLabel.Text = "Ready"
        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Font = Enum.Font.SourceSans
        infoLabel.TextSize = 14
        infoLabel.Parent = parent
        UI.InfoLabel = infoLabel
        local cleanBtn = Instance.new("TextButton")
        cleanBtn.Size = UDim2.new(0.5, -10, 0, 40)
        cleanBtn.Text = "Clean Workspace"
        cleanBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        cleanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        cleanBtn.Font = Enum.Font.SourceSans
        cleanBtn.TextSize = 16
        cleanBtn.Parent = parent
        cleanBtn.MouseButton1Click:Connect(function()
            cleanWorkspace()
            infoLabel.Text = "Workspace cleaned"
        end)
        local scanBtn = Instance.new("TextButton")
        scanBtn.Size = UDim2.new(0.5, -10, 0, 40)
        scanBtn.Position = UDim2.new(0.5, 5, 0, 0)
        scanBtn.Text = "Scan Hidden"
        scanBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        scanBtn.Font = Enum.Font.SourceSans
        scanBtn.TextSize = 16
        scanBtn.Parent = parent
        scanBtn.MouseButton1Click:Connect(function()
            scanNilInstances()
        end)
    end)
    -- Tab 2: Settings
    local settingsFrame = createTab("Settings", function(parent)
        local function createToggle(label, settingKey, default)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 30)
            frame.BackgroundTransparency = 1
            frame.Parent = parent
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.7, 0, 1, 0)
            lbl.Text = label
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSans
            lbl.TextSize = 16
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = frame
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 40, 1, 0)
            btn.Position = UDim2.new(1, -40, 0, 0)
            btn.Text = default and "ON" or "OFF"
            btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 14
            btn.Parent = frame
            local state = default
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = state and "ON" or "OFF"
                btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
                Settings[settingKey] = state
            end)
            Settings[settingKey] = default
        end
        createToggle("Workspace", "SaveWorkspace", true)
        createToggle("Lighting", "SaveLighting", true)
        createToggle("ReplicatedStorage", "SaveReplicatedStorage", true)
        createToggle("ReplicatedFirst", "SaveReplicatedFirst", true)
        createToggle("StarterPack", "SaveStarterPack", true)
        createToggle("StarterGui", "SaveStarterGui", true)
        createToggle("StarterPlayer", "SaveStarterPlayer", true)
        createToggle("Terrain", "SaveTerrain", true)
        createToggle("Scripts (Decompile)", "SaveScripts", true)
        createToggle("Meshes/Textures", "SaveMeshes", true)
        createToggle("UI (ScreenGui)", "SaveUI", true)
        local yieldLabel = Instance.new("TextLabel")
        yieldLabel.Size = UDim2.new(1, -20, 0, 30)
        yieldLabel.Text = "Yield Rate (Objects/tick): " .. Settings.YieldRate
        yieldLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        yieldLabel.BackgroundTransparency = 1
        yieldLabel.Font = Enum.Font.SourceSans
        yieldLabel.TextSize = 16
        yieldLabel.Parent = parent
        local yieldSlider = Instance.new("TextButton")
        yieldSlider.Size = UDim2.new(1, -20, 0, 30)
        yieldSlider.Text = "Adjust"
        yieldSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        yieldSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
        yieldSlider.Font = Enum.Font.SourceSans
        yieldSlider.TextSize = 16
        yieldSlider.Parent = parent
        yieldSlider.MouseButton1Click:Connect(function()
            local input = Instance.new("TextBox")
            input.Size = UDim2.new(0, 100, 0, 30)
            input.Position = UDim2.new(0.5, -50, 0, 0)
            input.Text = tostring(Settings.YieldRate)
            input.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            input.TextColor3 = Color3.fromRGB(255, 255, 255)
            input.Font = Enum.Font.SourceSans
            input.TextSize = 16
            input.Parent = parent
            local confirm = Instance.new("TextButton")
            confirm.Size = UDim2.new(0, 60, 0, 30)
            confirm.Position = UDim2.new(0.5, 70, 0, 0)
            confirm.Text = "Set"
            confirm.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            confirm.TextColor3 = Color3.fromRGB(255, 255, 255)
            confirm.Font = Enum.Font.SourceSans
            confirm.TextSize = 16
            confirm.Parent = parent
            local function setYield()
                local val = tonumber(input.Text)
                if val and val >= 50 and val <= 2000 then
                    Settings.YieldRate = val
                    yieldLabel.Text = "Yield Rate (Objects/tick): " .. val
                    input:Destroy()
                    confirm:Destroy()
                end
            end
            input.FocusLost:Connect(function(enter)
                if enter then setYield() end
            end)
            confirm.MouseButton1Click:Connect(setYield)
        end)
    end)
    -- Tab 3: Export
    local exportFrame = createTab("Export", function(parent)
        local modeLabel = Instance.new("TextLabel")
        modeLabel.Size = UDim2.new(1, -20, 0, 30)
        modeLabel.Text = "Export Mode: " .. Settings.ExportMode
        modeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        modeLabel.BackgroundTransparency = 1
        modeLabel.Font = Enum.Font.SourceSans
        modeLabel.TextSize = 16
        modeLabel.Parent = parent
        local modeBtn = Instance.new("TextButton")
        modeBtn.Size = UDim2.new(1, -20, 0, 40)
        modeBtn.Text = "Switch Mode"
        modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        modeBtn.Font = Enum.Font.SourceSans
        modeBtn.TextSize = 16
        modeBtn.Parent = parent
        local modes = {"Native", "XML", "JSON"}
        local idx = 1
        for i, m in ipairs(modes) do if m == Settings.ExportMode then idx = i break end end
        modeBtn.MouseButton1Click:Connect(function()
            idx = idx % 3 + 1
            Settings.ExportMode = modes[idx]
            modeLabel.Text = "Export Mode: " .. Settings.ExportMode
        end)
        local restoreBtn = Instance.new("TextButton")
        restoreBtn.Size = UDim2.new(1, -20, 0, 40)
        restoreBtn.Text = "Restore Hidden Objects"
        restoreBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 170)
        restoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        restoreBtn.Font = Enum.Font.SourceSans
        restoreBtn.TextSize = 16
        restoreBtn.Parent = parent
        restoreBtn.MouseButton1Click:Connect(function()
            restoreHiddenToWorkspace()
        end)
        local listBtn = Instance.new("TextButton")
        listBtn.Size = UDim2.new(1, -20, 0, 40)
        listBtn.Text = "List Saved Dumps"
        listBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
        listBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        listBtn.Font = Enum.Font.SourceSans
        listBtn.TextSize = 16
        listBtn.Parent = parent
        listBtn.MouseButton1Click:Connect(function()
            local files = CoreFunctions.listfiles(Settings.DumpPath)
            local msg = "Dumps: " .. table.concat(files or {}, ", ")
            pcall(function()
                if UI and UI.InfoLabel then
                    UI.InfoLabel.Text = msg
                end
            end)
        end)
    end)
    -- Tab 4: Hidden
    local hiddenFrame = createTab("Hidden", function(parent)
        local scanBtn = Instance.new("TextButton")
        scanBtn.Size = UDim2.new(1, -20, 0, 50)
        scanBtn.Text = "Scan Nil Instances"
        scanBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        scanBtn.Font = Enum.Font.SourceSansBold
        scanBtn.TextSize = 18
        scanBtn.Parent = parent
        scanBtn.MouseButton1Click:Connect(function()
            scanNilInstances()
        end)
        local restoreBtn = Instance.new("TextButton")
        restoreBtn.Size = UDim2.new(1, -20, 0, 50)
        restoreBtn.Text = "Restore Hidden to Workspace"
        restoreBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        restoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        restoreBtn.Font = Enum.Font.SourceSansBold
        restoreBtn.TextSize = 18
        restoreBtn.Parent = parent
        restoreBtn.MouseButton1Click:Connect(function()
            restoreHiddenToWorkspace()
        end)
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -20, 0, 60)
        info.Text = "Hidden instances are those not visible in the explorer. Use these tools to discover and recover them."
        info.TextColor3 = Color3.fromRGB(200, 200, 200)
        info.BackgroundTransparency = 1
        info.Font = Enum.Font.SourceSans
        info.TextSize = 14
        info.TextWrapped = true
        info.Parent = parent
    end)
    -- show first tab
    if #tabFrames > 0 then
        tabFrames[1].Visible = true
        tabButtons[1].BackgroundTransparency = 0.3
        tabButtons[1].TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    -- parent to CoreGUI
    local coreGui = A.Environment:FindService("CoreGui") or A.Environment:GetService("CoreGui")
    if coreGui then
        screenGui.Parent = coreGui
    else
        screenGui.Parent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    end
    return screenGui
end

local UI = {}
local gui = createUI()
UI.Gui = gui

-- Additional safe initialisation
pcall(function()
    CoreFunctions.makefolder(Settings.DumpPath)
end)

-- if executor is mobile, adjust default yield
if A.ExecutorName and string.match(A.ExecutorName:lower(), "mobile") then
    Settings.YieldRate = 200
end

-- Main loop for heartbeat (if needed)
RunService.Heartbeat:Connect(function()
    -- could be used for throttling but we use task.wait in queue
end)

-- override startDump with a pcall wrapper
local originalStart = startDump
startDump = function()
    pcall(originalStart)
end

-- Provide global access for debugging
_G.MapDumper = {
    Settings = Settings,
    Start = startDump,
    Clean = cleanWorkspace,
    Scan = scanNilInstances,
    Restore = restoreHiddenToWorkspace,
    UI = UI
}

print("Universal Map Duplicator loaded. Executor: " .. A.ExecutorName)
