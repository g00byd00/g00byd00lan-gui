-- ============================================
-- g00byd0lan GUI - 3D Sky & Effect (FINAL FIX)
-- Open/Close: H
-- Texture: rbxassetid://178993746
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CONFIG = {
    menuKey = Enum.KeyCode.H,
    textureID = "rbxassetid://178993746"
}

local state = {
    menuOpen = false,
    mainGui = nil,
    skyModel = nil,
    effectParts = {},
    updateConnection = nil
}

-- ============================================
-- 3D НЕБО (Купол вокруг карты)
-- ============================================
local function toggleSky(on)
    if state.skyModel then
        state.skyModel:Destroy()
        state.skyModel = nil
    end

    if on then
        state.skyModel = Instance.new("Model")
        state.skyModel.Name = "G00by_SkyDome"
        state.skyModel.Parent = workspace

        -- Создаем огромную сферу вокруг игрока
        local sphere = Instance.new("Part")
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(4000, 4000, 4000) -- Огромный размер
        sphere.Material = Enum.Material.SmoothPlastic
        sphere.Transparency = 0.1
        sphere.CanCollide = false
        sphere.Anchored = true
        sphere.Parent = state.skyModel

        -- Натягиваем твою картинку на эту сферу
        local decal = Instance.new("Decal")
        decal.Texture = CONFIG.textureID
        decal.Face = Enum.NormalId.Front -- Картинка будет изнутри
        decal.Parent = sphere

        -- Сфера всегда будет двигаться за камерой, чтобы ты видел картинку везде
        if state.updateConnection then state.updateConnection:Disconnect() end
        state.updateConnection = RunService.RenderStepped:Connect(function()
            if sphere and sphere.Parent then
                sphere.CFrame = CFrame.new(Camera.CFrame.Position)
            end
        end)
    else
        if state.updateConnection then
            state.updateConnection:Disconnect()
            state.updateConnection = nil
        end
    end
end

-- ============================================
-- 3D ЭФФЕКТ G00BY (Сферы вокруг персонажа)
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
        Vector3.new(0, 3, 0), Vector3.new(0, -2, 0),
        Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0),
        Vector3.new(0, 0, 3), Vector3.new(0, 0, -3)
    }

    for _, offset in ipairs(offsets) do
        local sphere = Instance.new("Part")
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(4, 4, 4) -- Размер шарика эффекта
        sphere.Material = Enum.Material.Neon -- Светящийся
        sphere.CanCollide = false
        sphere.Anchored = false
        sphere.Massless = true
        sphere.CFrame = root.CFrame * CFrame.new(offset)
        sphere.Parent = character
        
        -- Натягиваем картинку на шарик
        local decal = Instance.new("Decal")
        decal.Texture = CONFIG.textureID
        decal.Face = Enum.NormalId.Front
        decal.Parent = sphere
        
        -- Крепим к персонажу
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = sphere
        weld.Parent = sphere
        
        table.insert(state.effectParts, sphere)
    end
end

local function toggleEffect(on)
    if on then
        if LocalPlayer.Character then createEffect(LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(1)
            if #state.effectParts > 0 then createEffect(char) end
        end)
    else
        removeEffect()
    end
end

-- ============================================
-- DRAG (Перетаскивание GUI)
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
