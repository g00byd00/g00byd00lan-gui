-- ============================================
-- g00byd0lan GUI - CUBE SKY & EFFECT (FINAL)
-- Open/Close: H
-- Texture: rbxassetid://94223128682740
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CONFIG = {
    menuKey = Enum.KeyCode.H,
    textureID = "rbxassetid://94223128682740" -- Твой новый ID
}

local state = {
    menuOpen = false,
    mainGui = nil,
    skyPart = nil,
    skyConnection = nil,
    effectParts = {},
    effectConnection = nil
}

-- ============================================
-- SKY (Куб с текстурой вместо неба)
-- ============================================
local function toggleSky(on)
    if state.skyPart then state.skyPart:Destroy() end
    if state.skyConnection then state.skyConnection:Disconnect() end
    
    if on then
        -- Отключаем атмосферу и стандартное небо игры
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then obj.Parent = nil end
            if obj:IsA("Atmosphere") then obj.Density = 0 end
        end
        
        -- Создаем куб вместо неба
        local cube = Instance.new("Part")
        cube.Name = "G00by_SkyBox"
        cube.Size = Vector3.new(2000, 2000, 2000)
        cube.Material = Enum.Material.SmoothPlastic
        cube.Transparency = 0
        cube.Anchored = true
        cube.CanCollide = false
        cube.CastShadow = false
        cube.Parent = workspace
        state.skyPart = cube

        -- Натягиваем текстуру (Texture работает на кубах идеально)
        local texture = Instance.new("Texture")
        texture.Texture = CONFIG.textureID
        texture.Face = Enum.NormalId.Back -- Задняя сторона куба, чтобы мы видели картинку изнутри
        texture.StudsPerTileU = 50 
        texture.StudsPerTileV = 50
        texture.Parent = cube

        -- Куб летает за камерой
        state.skyConnection = RunService.RenderStepped:Connect(function()
            if cube and cube.Parent then
                cube.CFrame = CFrame.new(Camera.CFrame.Position)
            end
        end)
    else
        if state.skyPart then
            state.skyPart:Destroy()
            state.skyPart = nil
        end
    end
end

-- ============================================
-- ЭФФЕКТ G00BY (Кубы вокруг персонажа)
-- ============================================
local function removeEffect()
    for _, part in ipairs(state.effectParts) do
        if part and part.Parent then part:Destroy() end
    end
    state.effectParts = {}
end

local function createEffect(character)
    removeEffect()
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local offsets = {
        Vector3.new(0, 3, 0), Vector3.new(0, -3, 0),
        Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0),
        Vector3.new(0, 0, 3), Vector3.new(0, 0, -3)
    }

    for _, offset in ipairs(offsets) do
        -- Используем Block (куб), чтобы текстура ложилась ровно
        local block = Instance.new("Part")
        block.Shape = Enum.PartType.Block
        block.Size = Vector3.new(3, 3, 0.2) 
        block.Material = Enum.Material.SmoothPlastic
        block.CanCollide = false
        block.Massless = true
        block.Anchored = false
        block.CFrame = root.CFrame * CFrame.new(offset)
        block.Parent = character
        
        local texture = Instance.new("Texture")
        texture.Texture = CONFIG.textureID
        texture.Face = Enum.NormalId.Front
        texture.StudsPerTileU = 3
        texture.StudsPerTileV = 3
        texture.Parent = block
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = block
        weld.Parent = block
        
        table.insert(state.effectParts, block)
    end
end

local function toggleEffect(on)
    if on then
        if LocalPlayer.Character then createEffect(LocalPlayer.Character) end
        if state.effectConnection then state.effectConnection:Disconnect() end
        state.effectConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(1)
            if #state.effectParts > 0 then createEffect(char) end
        end)
    else
        removeEffect()
        if state.effectConnection then
            state.effectConnection:Disconnect()
            state.effectConnection = nil
        end
    end
end

-- ============================================
-- GUI И ПЕРЕТАСКИВАНИЕ
-- ============================================
local function makeDraggable(frame, dragPart)
    local dragging, dragStart, startPos = false, nil, nil
    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
        end
    end)
    dragPart.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local viewport = Camera.ViewportSize
            local frameSize = frame.AbsoluteSize
            frame.Position = UDim2.new(0, math.clamp(startPos.X.Offset + delta.X, 0, viewport.X - frameSize.X), 0, math.clamp(startPos.Y.Offset + delta.Y, 0, viewport.Y - frameSize.Y))
        end
    end)
end

local function createGUI()
    if state.mainGui then state.mainGui:Destroy() end
    
    state.mainGui = Instance.new("ScreenGui")
    state.mainGui.Name = "g00byd0lan"
    state.mainGui.ResetOnSpawn = false
    state.mainGui.IgnoreGuiInset = true
    state.mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = state.mainGui
    
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = mainFrame
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(0, 255, 0); stroke.Thickness = 2; stroke.Parent = mainFrame
    
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 300, 0, 300) }):Play()
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    titleBar.BackgroundTransparency = 0.3
    titleBar.Parent = mainFrame
    local tCorner = Instance.new("UICorner"); tCorner.CornerRadius = UDim.new(0, 12); tCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -40, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "g00byd0lan GUI"
    titleText.TextColor3 = Color3.fromRGB(0, 255, 0)
    titleText.TextSize = 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0, 6); cCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        local t = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) })
        t:Play()
        t.Completed:Connect(function()
            state.mainGui.Enabled = false
            mainFrame.Size = UDim2.new(0, 300, 0, 300)
            mainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
        end)
        state.menuOpen = false
    end)
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -55)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = content
    
    local skyBtn = Instance.new("TextButton")
    skyBtn.Size = UDim2.new(1, 0, 0, 40)
    skyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    skyBtn.Text = "sky"
    skyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    skyBtn.TextSize = 16
    skyBtn.Font = Enum.Font.GothamBold
    skyBtn.Parent = content
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 8); sc.Parent = skyBtn
    
    local skyActive = false
    skyBtn.MouseButton1Click:Connect(function()
        skyActive = not skyActive
        skyBtn.BackgroundColor3 = skyActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)
        toggleSky(skyActive)
    end)
    
    local effectBtn = Instance.new("TextButton")
    effectBtn.Size = UDim2.new(1, 0, 0, 40)
    effectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    effectBtn.Text = "Effect G00BY"
    effectBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    effectBtn.TextSize = 16
    effectBtn.Font = Enum.Font.GothamBold
    effectBtn.Parent = content
    local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0, 8); ec.Parent = effectBtn
    
    local effectActive = false
    effectBtn.MouseButton1Click:Connect(function()
        effectActive = not effectActive
        effectBtn.BackgroundColor3 = effectActive and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)
        toggleEffect(effectActive)
    end)
    
    makeDraggable(mainFrame, titleBar)
    return state.mainGui
end

local function toggleMenu()
    if not state.mainGui then
        createGUI()
        state.menuOpen = true
        return
    end
    state.menuOpen = not state.menuOpen
    state.mainGui.Enabled = state.menuOpen
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.menuKey then
        toggleMenu()
    end
end)

print("[g00byd0lan GUI] Loaded.")
