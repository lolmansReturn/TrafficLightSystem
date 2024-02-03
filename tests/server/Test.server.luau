local TrafficLightManager = require(game:GetService("ReplicatedStorage").TrafficLightSystem)

for _, intersection in workspace.Intersections:GetChildren() do
    TrafficLightManager.RegisterIntersection(intersection)
end