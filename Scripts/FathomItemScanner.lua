local TweenService = game:GetService("TweenService")
--Globals
local Env = getgenv()
local Player = game:GetService("Players").LocalPlayer
local AnchoredRoot

-- Cleanup on re-execute
if Env.ArmorStandNotifierCleanup then
	pcall(Env.ArmorStandNotifierCleanup)
end

-- Colour per rarity
local TierColors = {
    epic = Color3.fromRGB(170, 85, 255),
    legendary = Color3.fromRGB(255, 170, 0),
    event = Color3.fromRGB(255, 85, 170),
    exclusive = Color3.fromRGB(0, 200, 255),
    unfathomable = Color3.fromRGB(0, 0, 0),
	otherworldly = Color3.fromRGB(75, 0, 130),
}

-- Tiers that anchor your HumanoidRootPart when found (true = anchor)
Env.AnchorTiers = Env.AnchorTiers or {
	epic = false,
	legendary = true,
	event = true,
	exclusive = true,
	unfathomable = true,
	otherworldly = true
}

local function AnchorRoot()
	local Root = (Player.Character or Player.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart", 5)

	if Root and Root:IsA("BasePart") then
		Root.Anchored = true
		AnchoredRoot = Root
	end
end

-- Finds the tier from attributes, value objects, then the names
local function GetTier(Stand, Item)
	local Sources = {Stand, Item}

	for _, Source in Sources do
		for _, Attribute in {"Rarity", "Tier", "rarity", "tier"} do
			local Value = Source:GetAttribute(Attribute)
			local Child = Source:FindFirstChild(Attribute)

			if typeof(Value) == "string" and TierColors[Value:lower()] then
				return Value:lower()
			end

			if Child and Child:IsA("StringValue") and TierColors[Child.Value:lower()] then
				return Child.Value:lower()
			end
		end
	end

	for _, Source in Sources do
		for Tier in TierColors do
			if Source.Name:lower():find(Tier, 1, true) then
				return Tier
			end
		end
	end
end

-- Popup UI
local Gui = Instance.new("ScreenGui")
local Holder = Instance.new("Frame")
local Layout = Instance.new("UIListLayout")

Gui.Name = "ArmorStandNotifier"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999
pcall(function()
	Gui.Parent = game:GetService("CoreGui")
end)
if not Gui.Parent then
	Gui.Parent = Player:WaitForChild("PlayerGui")
end

Holder.BackgroundTransparency = 1
Holder.AnchorPoint = Vector2.new(0.5, 0)
Holder.Position = UDim2.new(0.5, 0, 0, 20)
Holder.Size = UDim2.new(0, 320, 0, 300)
Holder.Parent = Gui

Layout.Padding = UDim.new(0, 6)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Holder

local function Popup(Tier, ItemName)
	local Color = TierColors[Tier]
	local Frame = Instance.new("Frame")
	local Stroke = Instance.new("UIStroke")
	local Label = Instance.new("TextLabel")
	local FadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	Frame.Size = UDim2.new(1, 0, 0, 44)
	Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	Frame.BackgroundTransparency = 1
	Frame.BorderSizePixel = 0
	Frame.Parent = Holder

	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

	Stroke.Color = Color
	Stroke.Thickness = 2
	Stroke.Transparency = 1
	Stroke.Parent = Frame

	Label.BackgroundTransparency = 1
	Label.Size = UDim2.new(1, -16, 1, 0)
	Label.Position = UDim2.new(0, 8, 0, 0)
	Label.Font = Enum.Font.GothamBold
	Label.TextSize = 15
	Label.TextColor3 = Color
	Label.TextTransparency = 1
	Label.TextWrapped = true
	Label.Text = string.format("%s armor stand spawned: %s", Tier:upper(), ItemName)
	Label.Parent = Frame

	TweenService:Create(Frame, FadeIn, {BackgroundTransparency = 0.15}):Play()
	TweenService:Create(Stroke, FadeIn, {Transparency = 0}):Play()
	TweenService:Create(Label, FadeIn, {TextTransparency = 0}):Play()

	task.delay(6, function()
		local FadeOut = TweenInfo.new(0.4)
		local LabelTween = TweenService:Create(Label, FadeOut, {TextTransparency = 1})

		TweenService:Create(Frame, FadeOut, {BackgroundTransparency = 1}):Play()
		TweenService:Create(Stroke, FadeOut, {Transparency = 1}):Play()
		LabelTween:Play()
		LabelTween.Completed:Wait()
		Frame:Destroy()
	end)
end

local function AddHighlight(Stand, Color)
	local Highlight = Instance.new("Highlight")

	Highlight.Name = "TierHighlight"
	Highlight.Adornee = Stand
	Highlight.FillColor = Color
	Highlight.OutlineColor = Color
	Highlight.FillTransparency = 0.5
	Highlight.OutlineTransparency = 0
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.Parent = Stand
end

-- Watching for armor stands
local Connection = workspace:WaitForChild("Props").ChildAdded:Connect(function(Stand)
	if Stand.Name ~= "ArmorStand" then
		return
	end

	local Body = Stand:WaitForChild("Body", 5)

	if not Body then
		return
	end

	local Item = Body:FindFirstChildOfClass("Accessory") or Body:FindFirstChildOfClass("Pants") or Body:FindFirstChildOfClass("Shirt")
	local Tier = GetTier(Stand, Item)

	if not Tier then
		return
	end

	AddHighlight(Stand, TierColors[Tier])

	if Tier ~= "epic" then
		Popup(Tier, Item and Item.Name or "unknown item")
	end

	if Env.AnchorTiers[Tier] then
		task.spawn(AnchorRoot)
	end
end)

Env.ArmorStandNotifierCleanup = function()
	Connection:Disconnect()

	if AnchoredRoot and AnchoredRoot.Parent then
		AnchoredRoot.Anchored = false
	end

	Gui:Destroy()
end
