local Player = game:GetService("Players").LocalPlayer
local Halloween = workspace:WaitForChild("Halloween")
--Pumpkins
local Running = true
local Pumpkins, Collected = {}, {}
local LastPosition = Vector3.zero

local function Track(Descendant)
	if Descendant.Name == "Pumpkin" and Descendant:IsA("Model") and not Collected[Descendant] then
		Pumpkins[Descendant] = true
	end
end

local function GetNearest(Position)
	local Nearest, Shortest
	for Pumpkin in Pumpkins do
		local Distance = (Pumpkin:GetPivot().Position - Position).Magnitude
		if not Shortest or Distance < Shortest then
			Nearest, Shortest = Pumpkin, Distance
		end
	end
	return Nearest, Shortest
end

for _, Descendant in Halloween:GetDescendants() do
	Track(Descendant)
end

Halloween.DescendantAdded:Connect(Track)

Halloween.DescendantRemoving:Connect(function(Descendant)
	Pumpkins[Descendant] = nil
	Collected[Descendant] = nil
end)

-- Stop the whole script when E is pressed
local Connection
Connection = game:GetService("UserInputService").InputBegan:Connect(function(Input, Processed)
	if not Processed and Input.KeyCode == Enum.KeyCode.E then
		Running = false
		Connection:Disconnect()
	end
end)

-- Walking with pathfinding
task.spawn(function()
	local Path = game:GetService("PathfindingService"):CreatePath({AgentCanJump = true})
	local Waypoints, Index, Target
	local LastCompute = 0

	while Running do
		task.wait(0.1)
		local Humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
		local Root = Humanoid and Humanoid.RootPart
		local Nearest, Distance
		if Root then
			Nearest, Distance = GetNearest(Root.Position)
		end

		if not Root or (Nearest and Distance <= 15) then
			Waypoints, Target = nil, nil
			continue
		end

		-- Goal is the nearest pumpkin, or the far away point if there are none
		local Goal = Nearest and Nearest:GetPivot().Position or Vector3.new(100000, Root.Position.Y, 100000)

		-- Recompute the path when needed
		if Target ~= Nearest or os.clock() - LastCompute > 1.5 then
			Target = Nearest
			LastCompute = os.clock()
			local Computed = pcall(Path.ComputeAsync, Path, Root.Position, Goal)
			Waypoints = Computed and Path.Status == Enum.PathStatus.Success and Path:GetWaypoints() or nil
			Index = 2
		end

		-- Move to the next waypoint (flat distance), or straight at the goal if there is no path
		local Waypoint = Waypoints and Waypoints[Index]
		if Waypoint then
			local Flat = Vector3.new(Root.Position.X - Waypoint.Position.X, 0, Root.Position.Z - Waypoint.Position.Z)
			if Flat.Magnitude < 3 then
				Index += 1
				Waypoint = Waypoints[Index]
			end
		end

		Humanoid:MoveTo(Waypoint and Waypoint.Position or Goal)

		if Waypoint and Waypoint.Action == Enum.PathWaypointAction.Jump then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		-- Jump if stuck
		if (Root.Position - LastPosition).Magnitude < 0.3 then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		LastPosition = Root.Position
	end
end)

-- Collecting every 0.5 seconds when near
task.spawn(function()
	while Running do
		task.wait(0.5)
		local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
		local Nearest, Distance
		if Root then
			Nearest, Distance = GetNearest(Root.Position)
		end

		if Running and Nearest and Distance <= 15 then
			local Success = pcall(function()
				game:GetService("ReplicatedStorage").Packages.Networker._remotes.HalloweenService.RemoteFunction:InvokeServer(
					"collect",
					Nearest:GetAttribute("PumpkinKey"),
					Nearest:GetAttribute("PumpkinId")
				)
			end)

			-- Ignore this pumpkin from now on
			if Success then
				Pumpkins[Nearest] = nil
				Collected[Nearest] = true
			end
		end
	end
end)
