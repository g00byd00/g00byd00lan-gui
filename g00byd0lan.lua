-- ============================================
-- g00byd0lan GUI - Sky Changer & Effect
-- Open/Close: H
-- Black & Green theme, black text
-- Sky texture: rbxassetid://8408806744 (All 6 sides)
-- Effect texture: rbxassetid://8408806744 (On Character)
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Конфигурация
local CONFIG = {
    menuKey = Enum.KeyCode.H,
    guiSize = UDim2.new(0, 300, 0, 300),
    bgColor = Color3.fromRGB(0, 0, 0),
    accentColor = Color3.fromRGB(0, 255, 0),
    textColor = Color3.fromRGB(0, 0, 0),
    textureID = "rbxassetid://8408806744"
}

local state = {
    menuOpen = false,
    mainGui = nil,
    originalSky = nil,
    skyOn = false,
    effectEmitters = {},
    effectConnection = nil,
    effectOn = false
}

-- ============================================
-- ЭФФЕКТ G00BY (На персонаже)
-- ============================================
local function removeEffect()
    for _, obj in ipairs(state.effectEmitters) do
        if obj and obj.Parent then obj:Destroy() end
    end
    state.effectEmitters = {}
end

local function createEffect(character)
    removeEffect()
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local att = Instance.new("Attachment")
    att.Name = "G00byEffect_Att"
    att.Parent = root

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "G00byEffect"
    emitter.Texture = CONFIG.textureID -- Применяем текстуру
    emitter.Rate = 80
    emitter.Lifetime = NumberRange.new(1, 2.5)
    emitter.Speed = NumberRange.new(1, 8)
    emitter.SpreadAngle = Vector2.new(360, 360)
    
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.2, 2.5),
        NumberSequenceKeypoint.new(0.8, 2.5),
        NumberSequenceKeypoint.new(1, 0)
    })
    
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.1, 0),
        NumberSequenceKeypoint.new(0.9, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    emitter.LightEmission = 1
    emitter.LightInfluence = 0
    emitter.ZOffset = 1
    emitter.Acceleration = Vector3.new(0, 2, 0)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-150, 150)
    emitter.Parent = att
    
    table.insert(state.effectEmitters, att)
    table.insert(state.effectEmitters, emitter)
end

local function toggleEffect(on)
    state.effectOn = on
    if on then
        local ch = LocalPlayer.Character
        if ch then createEffect(ch) end
        if state.effectConnection then state.effectConnection:Disconnect() end
        state.effectConnection = LocalPlayer.CharacterAdded:Connect(function(character)
            task.wait(1)
            if state.effectOn then createEffect(character) end
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
-- ЗАМЕНА НЕБА (Sky на все 6 сторон)
-- ============================================
local function toggleSky(on)
    -- Удаляем старые небеса, чтобы игра не перекрывала наше
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            obj:Destroy()
        end
    end

    if on then
        local sky = Instance.new("Sky")
        sky.Name = "g00byd0lan_Sky"
        -- Применяем текстуру на ВСЕ 6 СТОРОН
        sky.SkyboxBk = CONFIG.textureID -- Задняя
        sky.SkyboxDn = CONFIG.textureID -- Нижняя
        sky.SkyboxFt = CONFIG.textureID -- Передняя
        sky.SkyboxLf = CONFIG.textureID -- Левая
        sky.SkyboxRt = CONFIG.textureID -- Правая
        sky.SkyboxUp = CONFIG.textureID -- Верхняя
        sky.Parent = Lighting
        state.skyOn = true
    else
        state.skyOn = false
    end
end

-- ============================================
-- DRAG (перетаскивание GUI)
-- ============================================
local function makeDraggable(frame, dragPart)
    local dragging, dragStart, startPos = false, nil, nil
    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    dragPart.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                         or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local viewport = Camera.ViewportSize
            local frameSize = frame.AbsoluteSize
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, viewport.X - frameSize.X)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, viewport.Y - frameSize.Y)
            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

-- ============================================
-- GUI (300x300, черно-зеленый, черный текст)
-- ============================================
local function createGUI()
    if state.mainGui then state.mainGui:Destroy() end
    
    state.mainGui = Instance.new("ScreenGui")
    state.mainGui.Name = "g00byd0lan"
    state.mainGui.ResetOnSpawn = false
    state.mainGui.IgnoreGuiInset = true
    state.mainGui.DisplayOrder = 999
    state.mainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
    mainFrame.BackgroundColor3 = CONFIG.bgColor
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = state.mainGui
    
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = mainFrame
    local stroke = Instance.new("UIStroke"); stroke.Color = CONFIG.accentColor; stroke.Thickness = 2; stroke.Transparency = 0.3; stroke.Parent = mainFrame
    
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = CONFIG.guiSize
    }):Play()
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = CONFIG.bgColor
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    local tCorner = Instance.new("UICorner"); tCorner.CornerRadius = UDim.new(0, 12); tCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "g00byd0lan GUI"
    titleText.TextColor3 = CONFIG.accentColor
    titleText.TextSize = 16
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = CONFIG.accentColor
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0, 6); cCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        local t = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        t:Play()
        t.Completed:Connect(function()
            state.mainGui.Enabled = false
            mainFrame.Size = CONFIG.guiSize
            mainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
        end)
        state.menuOpen = false
    end)
    
    -- Контент
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -55)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = content
    
    -- Кнопка sky
    local skyBtn = Instance.new("TextButton")
    skyBtn.Size = UDim2.new(1, 0, 0, 40)
    skyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    skyBtn.Text = "sky"
    skyBtn.TextColor3 = CONFIG.textColor
    skyBtn.TextSize = 16
    skyBtn.Font = Enum.Font.GothamBold
    skyBtn.BorderSizePixel = 0
    skyBtn.Parent = content
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 8); sc.Parent = skyBtn
    
    local skyActive = false
    skyBtn.MouseButton1Click:Connect(function()
        skyActive = not skyActive
        if skyActive then
            skyBtn.BackgroundColor3 = CONFIG.accentColor
            toggleSky(true)
        else
            skyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            toggleSky(false)
        end
    end)
    
    -- Кнопка Effect G00BY
    local effectBtn = Instance.new("TextButton")
    effectBtn.Size = UDim2.new(1, 0, 0, 40)
    effectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    effectBtn.Text = "Effect G00BY"
    effectBtn.TextColor3 = CONFIG.textColor
    effectBtn.TextSize = 16
    effectBtn.Font = Enum.Font.GothamBold
    effectBtn.BorderSizePixel = 0
    effectBtn.Parent = content
    local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0, 8); ec.Parent = effectBtn
    
    local effectActive = false
    effectBtn.MouseButton1Click:Connect(function()
        effectActive = not effectActive
        if effectActive then
            effectBtn.BackgroundColor3 = CONFIG.accentColor
            toggleEffect(true)
        else
            effectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            toggleEffect(false)
        end
    end)
    
    -- Перетаскивание
    makeDraggable(mainFrame, titleBar)
    
    return state.mainGui
end

-- ============================================
-- ОТКРЫТИЕ/ЗАКРЫТИЕ
-- ============================================
local function toggleMenu()
    if not state.mainGui then
        createGUI()
        state.menuOpen = true
        return
    end
    state.menuOpen = not state.menuOpen
    state.mainGui.Enabled = state.menuOpen
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.menuKey then
        toggleMenu()
    end
end)

print("[g00byd0lan GUI] Loaded. Press H to open menu.")
