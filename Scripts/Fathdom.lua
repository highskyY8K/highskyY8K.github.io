local Player = game:GetService("Players").LocalPlayer
local Halloween = workspace:WaitForChild("Halloween")
--Pumpkins
local Running = true
local Pumpkins, Collected = {}, {}
local LastPosition = Vector3.zero
--Pathfinding
local Path = game:GetService("PathfindingService"):CreatePath({AgentCanJump = true})
local Params = RaycastParams.new()

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

local function GetWaypoints(Start, Goal)
	local Computed = pcall(Path.ComputeAsync, Path, Start, Goal)

	if Computed and Path.Status == Enum.PathStatus.Success then
		return Path:GetWaypoints()
	end
end

-- Pathfinds toward the far mark in 150 stud steps, only to points that have ground under them
local function GetFarWaypoints(Root)
	local Direction = (Vector3.new(100000, 0, 100000) - Vector3.new(Root.Position.X, 0, Root.Position.Z)).Unit

	Params.FilterDescendantsInstances = {Player.Character}

	for _, Angle in {0, 20, -20, 40, -40, 60, -60, 90, -90} do
		local Point = Root.Position + CFrame.Angles(0, math.rad(Angle), 0) * Direction * 150
		local Ground = workspace:Raycast(Point + Vector3.new(0, 200, 0), Vector3.new(0, -600, 0), Params)
		local Waypoints = Ground and GetWaypoints(Root.Position, Ground.Position)

		if Waypoints then
			return Waypoints
		end
	end
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

		-- Recompute the path when needed (nearest pumpkin, or the far mark if there are none)
		if Target ~= Nearest or os.clock() - LastCompute > 1.5 then
			Target = Nearest
			LastCompute = os.clock()
			Waypoints = if Nearest then GetWaypoints(Root.Position, Nearest:GetPivot().Position) else GetFarWaypoints(Root)
			Index = 2
		end

		-- Move to the next waypoint (flat distance)
		local Waypoint = Waypoints and Waypoints[Index]
		if Waypoint then
			local Flat = Vector3.new(Root.Position.X - Waypoint.Position.X, 0, Root.Position.Z - Waypoint.Position.Z)
			if Flat.Magnitude < 3 then
				Index += 1
				Waypoint = Waypoints[Index]
			end
		end

		-- No path means no walking, so it never walks off into a hole
		if not Waypoint then
			continue
		end

		Humanoid:MoveTo(Waypoint.Position)

		if Waypoint.Action == Enum.PathWaypointAction.Jump then
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
		task.wait(0.25)
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
