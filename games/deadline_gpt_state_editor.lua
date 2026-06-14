-- i used my modifyer and asked gpt to give me a editor since i so fucking lazy
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local SharedStateModule = require(ReplicatedStorage:WaitForChild("module"):WaitForChild("shared_state"))
local SharedState = SharedStateModule.SHARED_STATE

local OrigSharedValues = {}
local RowInstances = {}

for key, wrapper in pairs(SharedState) do
    if type(wrapper) == "table" and wrapper.value ~= nil then
        OrigSharedValues[key] = wrapper.value
    end
end

local function ModifySharedState(Key, Value)
    if not SharedState[Key] then return end
    local OrigREADONLY = SharedState[Key].readonly
    SharedState[Key].readonly = false
    SharedState[Key].value = Value
    SharedState[Key].changed:Fire(Value)
    SharedState[Key].readonly = OrigREADONLY
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SharedStateEditor"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainWindow = Instance.new("Frame")
MainWindow.Size = UDim2.new(0, 480, 0, 540)
MainWindow.Position = UDim2.new(0.5, -240, 0.5, -270)
MainWindow.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainWindow.BorderSizePixel = 0
MainWindow.Active = true
MainWindow.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Text = "  Shared State Value Editor"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = MainWindow

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -10, 0, 30)
SearchBox.Position = UDim2.new(0, 5, 0, 45)
SearchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SearchBox.BorderSizePixel = 0
SearchBox.PlaceholderText = "Search keys..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
SearchBox.Font = Enum.Font.SourceSans
SearchBox.TextSize = 14
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = MainWindow

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -85)
ScrollFrame.Position = UDim2.new(0, 5, 0, 80)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = MainWindow

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.SortOrder = Enum.SortOrder.Name
UIListLayout.Parent = ScrollFrame

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

Title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local filter = SearchBox.Text:lower()
    for _, item in ipairs(RowInstances) do
        if filter == "" or string.find(item.Name:lower(), filter, 1, true) then
            item.Visible = true
        else
            item.Visible = false
        end
    end
end)

for key, wrapper in pairs(SharedState) do
    if type(wrapper) == "table" and wrapper.value ~= nil then
        local Row = Instance.new("Frame")
        Row.Name = key
        Row.Size = UDim2.new(1, -8, 0, 35)
        Row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        Row.BorderSizePixel = 0
        Row.Parent = ScrollFrame
        
        table.insert(RowInstances, Row)
        
        local KeyLabel = Instance.new("TextLabel")
        KeyLabel.Size = UDim2.new(0.5, -10, 1, 0)
        KeyLabel.Position = UDim2.new(0, 10, 0, 0)
        KeyLabel.BackgroundTransparency = 1
        KeyLabel.Text = key
        KeyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
        KeyLabel.Font = Enum.Font.SourceSans
        KeyLabel.TextSize = 14
        KeyLabel.Parent = Row

        local ResetBtn = Instance.new("TextButton")
        ResetBtn.Size = UDim2.new(0, 25, 0, 25)
        ResetBtn.Position = UDim2.new(1, -30, 0, 5)
        ResetBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        ResetBtn.BorderSizePixel = 0
        ResetBtn.Text = "R"
        ResetBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
        ResetBtn.Font = Enum.Font.SourceSansBold
        ResetBtn.TextSize = 12
        ResetBtn.Parent = Row

        local currentVal = wrapper.value
        local updateUIField

        if type(currentVal) == "boolean" then
            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Size = UDim2.new(0, 70, 0, 25)
            ToggleBtn.Position = UDim2.new(1, -110, 0, 5)
            ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            ToggleBtn.Font = Enum.Font.SourceSansBold
            ToggleBtn.TextSize = 12
            ToggleBtn.Parent = Row
            
            updateUIField = function(val)
                ToggleBtn.Text = tostring(val):upper()
                ToggleBtn.BackgroundColor3 = val and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
            end
            
            ToggleBtn.MouseButton1Click:Connect(function()
                local newVal = not wrapper.value
                ModifySharedState(key, newVal)
                updateUIField(newVal)
            end)
            
        elseif type(currentVal) == "number" or type(currentVal) == "string" then
            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(0, 120, 0, 25)
            InputBox.Position = UDim2.new(1, -160, 0, 5)
            InputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            InputBox.BorderSizePixel = 0
            InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            InputBox.Font = Enum.Font.SourceSans
            InputBox.TextSize = 14
            InputBox.ClearTextOnFocus = false
            InputBox.Parent = Row
            
            updateUIField = function(val)
                InputBox.Text = tostring(val)
            end
            
            InputBox.FocusLost:Connect(function()
                local text = InputBox.Text
                if type(currentVal) == "number" then
                    local numValue = tonumber(text)
                    if numValue then
                        ModifySharedState(key, numValue)
                    else
                        InputBox.Text = tostring(wrapper.value)
                    end
                else
                    ModifySharedState(key, text)
                end
            end)
        end

        if updateUIField then
            updateUIField(currentVal)
        end

        ResetBtn.MouseButton1Click:Connect(function()
            local defaultVal = OrigSharedValues[key]
            if defaultVal ~= nil then
                ModifySharedState(key, defaultVal)
                if updateUIField then
                    updateUIField(defaultVal)
                end
            end
        end)
    end
end
