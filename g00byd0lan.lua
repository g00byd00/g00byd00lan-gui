-- ============================================
-- g00byd0lan GUI - Sky Changer & Effect (FIXED 2.0)
-- Open/Close: H
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CONFIG = {
    menuKey = Enum.KeyCode.H,
    guiSize = UDim2.new(0, 300, 0, 300),
    bgColor = Color3.fromRGB(0, 0, 0),
    accentColor = Color3.fromRGB(0, 255, 0),
    textColor = Color3.fromRGB(0, 0, 0),
    textureID = "rbxassetid://178993746"
}

local state = {
    menuOpen = false,
    mainGui = nil,
    skyLoop = nil,
    effectObjects = {},
    effectConnection = nil,
    effectOn = false
}

-- ============================================
-- ЭФФЕКТ G00BY (Картинки вокруг персонажа)
-- ============================================
local function removeEffect()
    for _, obj in ipairs(state.effectObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    state.effectObjects = {}
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

    for i, offset in ipairs(offsets) do
        -- Создаем невидимую плашку (Part)
        local part = Instance.new("Part")
        part.Name = "G00byEffectPart"
        part.Size = Vector3.new(4, 4, 0.1)
        part.Transparency = 1
        part.Anchored = false
        part.CanCollide = false
        part.Massless = true
        part.CFrame = root.CFrame * CFrame.new(offset)
        part.Parent = character
        
        -- Прикрепляем картинку (Decal) к этой плашке
        local decal = Instance.new("Decal")
        decal.Texture = CONFIG.textureID
        decal.Face = Enum.NormalId.Front
        decal.Parent = part
        
        -- Привязываем плашку к персонажу с помощью Weld
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = part
        
        table.insert(state.effectObjects, part)
    end
end

local function toggleEffect(on)
    state.effectOn = on
    if on then
        if LocalPlayer.Character then createEffect(LocalPlayer.Character) end
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
-- SKY (Жесткая смена неба)
-- ============================================
local function toggleSky(on)
    if state.skyLoop then
        state.skyLoop:Disconnect()
        state.skyLoop = nil
    end

    if on then
        state.skyLoop = RunService.Heartbeat:Connect(function()
            -- Убиваем туман и эффекты, чтобы небо было видно
            for _, obj in ipairs(Lighting:GetChildren()) do
                if obj:IsA("Atmosphere") or obj:IsA("Sky") then
                    if obj.Name ~= "CustomSky" then obj:Destroy() end
                end
            end
            
            -- Создаем наше небо
            if not Lighting:FindFirstChild("CustomSky") then
                local sky = Instance.new("Sky")
                sky.Name = "CustomSky"
                -- Ставим картинку на все 6 сторон
                sky.SkyboxBk = CONFIG.textureID
                sky.SkyboxDn = CONFIG.textureID
                sky.SkyboxFt = CONFIG.textureID
                sky.SkyboxLf = CONFIG.textureID
                sky.SkyboxRt = CONFIG.textureID
                sky.SkyboxUp = CONFIG.textureID
                sky.Parent = Lighting
            end
        end)
    else
        local sky = Lighting:FindFirstChild("CustomSky")
        if sky then sky:Destroy() end
    end
end

-- ============================================
-- DRAG
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

-- ============================================
-- GUI
-- ============================================
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
    mainFrame.BackgroundColor3 = CONFIG.bgColor
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = state.mainGui
    
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = mainFrame
    local stroke = Instance.new("UIStroke"); stroke.Color = CONFIG.accentColor; stroke.Thickness = 2; stroke.Parent = mainFrame
    
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = CONFIG.guiSize }):Play()
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = CONFIG.bgColor
    titleBar.BackgroundTransparency = 0.3
    titleBar.Parent = mainFrame
    local tCorner = Instance.new("UICorner"); tCorner.CornerRadius = UDim.new(0, 12); tCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -40, 1, 0)
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
        local t = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) })
        t:Play()
        t.Completed:Connect(function()
            state.mainGui.Enabled = false
            mainFrame.Size = CONFIG.guiSize
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
    
    -- Кнопка Sky
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
        skyBtn.BackgroundColor3 = skyActive and CONFIG.accentColor or Color3.fromRGB(50, 50, 50)
        toggleSky(skyActive)
    end)
    
    -- Кнопка Effect
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
        effectBtn.BackgroundColor3 = effectActive and CONFIG.accentColor or Color3.fromRGB(50, 50, 50)
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

print("[g00byd0lan GUI] Loaded. Press H to open menu.")
