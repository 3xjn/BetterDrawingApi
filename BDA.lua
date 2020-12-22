-------|   Better Drawing Api   |-------
-------|      Developed by      |-------
-------|          3xjn          |-------

--[[local Draw = function(...)
    local args = { ... }

    local class = args[1]
    local obj = Drawing.new(class)

    for k, v in pairs(args[2] or { }) do
        pcall(function()
            obj[k] = v
        end)
    end

    local mt = {
        index = { }
    }
    --function mt.index:
    setmetatable(obj, mt)

    return obj
end--]]

local Camera = game:GetService("Workspace").CurrentCamera
local VPS = Camera.ViewportSize

Camera.Changed:Connect(function()
    VPS = Camera.ViewportSize
end)

function Convert(u)
    return Vector2.new(u.X.Scale * VPS.X + u.X.Offset, u.Y.Scale * VPS.Y + u.Y.Offset)
end

local TweenService = game:GetService("TweenService")
local Create = clonefunction(TweenService.Create)

local Environment = { }

function copy(t)
    local n = {}

    for k, v in pairs(t) do
        n[k] = v
    end; return n
end

local custom_properties = {
    Square = {
        Center = "boolean"
    }
}

local Draw = function(...)
    local args = { ... }

    local type = args[1]
    local object = Drawing.new(type)

    local proxy = copy(object)
    local custom = { }

    proxy.class = type
    proxy.object = object
    proxy.custom = custom

    if object then
        local mt = getmetatable(proxy) or { }

        mt.__index = function(_, key)
            -- Custom property check
            local properties = custom_properties[type]
            if properties  then
                local check = properties[key]
                if check then
                    return custom[key]
                end
            end

            local value;
            local success, errormessage = pcall(function()
                value = object[key]
            end)

            if success then
                return value
            end
        end

        mt.__newindex = function(_, index, value)
            -- Custom property check
            local properties = custom_properties[type]
            if properties  then
                local check = properties[index]
                if check then
                    if typeof(check) == "table" then
                        for k, v in pairs(check) do
                            if type(value) == v then
                                custom[index] = value

                                if index == "Center" then
                                    proxy.Position = object.Position + object.Size/2 * (value and -1 or 1)
                                end
                                return
                            end
                        end

                        error("invalid property for " .. type)
                    elseif typeof(value) == check then
                        custom[index] = value

                        if index == "Center" then
                            proxy.Position = object.Position + object.Size/2 * (value and -1 or 1)
                        end
                    else
                        error("invalid property for " .. type)
                    end
                    return
                end
            end

            local type_of_index;
            local success, errormessage = pcall(function()
                return object[index]
            end)
            
            if success then
                type_of_index = object[index] and typeof(object[index])
            end
      
            -- Set multiple types
            if type_of_index == "Vector2" then
                local vector;
                if typeof(value) == "UDim2" then
                    vector = Convert(value)
                else
                    vector = value
                end

                if index == "Position" and proxy.Center then
                    vector = vector - object.Size / 2
                end

                object[index] = vector
                return
            end

            object[index] = value
        end

        setmetatable(proxy, mt)
        
        for k, v in pairs(args[2] or {}) do
            pcall(function()
                proxy[k] = v
            end)
        end

        Environment[proxy] = object
    end

    return proxy
end

hookfunction(Create, function(...)
    local args = { ... }
    local obj = args[1]

    if typeof(obj) == "table" and obj.__OBJECT then
        local Total = 0
        for _ in pairs(args[3]) do Total = Total + 1 end

        local OverallCounter = 0
        local Tweens = { }

        local Completed = Instance.new("BindableEvent")
        local CompletedEvent = Completed.Event
        local TweensIndex = { Completed = CompletedEvent }
        function TweensIndex:Play()
            for _, v in pairs(Tweens) do
                spawn(function()
                    v:Play()
                end)
            end
        end

        setmetatable(Tweens, {
            __index = TweensIndex
        })

        local function check()
            OverallCounter = OverallCounter + 1
            if OverallCounter == Total then
                Completed:Fire(tick())
            end
        end
        
        for k, v in pairs(args[3]) do
            local Type = typeof(obj[k])

            if Type == "number" then
                local Num = Instance.new("NumberValue")
                local Tween = TweenService:Create(Num, args[2], { Value = v })
                local con;

                if obj[k] then
                    Num.Value = obj[k]
                end

                con = Num:GetPropertyChangedSignal("Value"):Connect(function()
                    obj[k] = Num.Value
                end)

                Tween.Completed:Connect(function()
                    check()
                    con:Disconnect()
                end)

                Tweens[k] = Tween

            elseif Type == "Vector2" then
                local xNum, yNum = Instance.new("NumberValue"), Instance.new("NumberValue")
                local xCon, yCon;

                local xTween = TweenService:Create(xNum, args[2], { Value = v.X })
                local yTween = TweenService:Create(yNum, args[2], { Value = v.Y })
                local combinedVector = Vector2.new()

                print("ye - " .. tostring(obj.object[k]), "-", k)
                if obj[k] then
                    xNum.Value, yNum.Value = obj[k].X, obj[k].Y
                    combinedVector = Vector2.new(xNum.Value, yNum.Value)
                end

                print("combinedVector - " .. tostring(combinedVector))

                xCon = xNum:GetPropertyChangedSignal("Value"):Connect(function()
                    combinedVector = Vector2.new(xNum.Value, combinedVector.Y)
                    obj[k] = combinedVector
                end)

                yCon = yNum:GetPropertyChangedSignal("Value"):Connect(function()
                    combinedVector = Vector2.new(combinedVector.X, yNum.Value)
                    obj[k] = combinedVector
                end)
                
                local v2Completed = Instance.new("BindableEvent")
                local counter = 0
                xTween.Completed:Connect(function()
                    counter = counter + 1
                    if counter == 2 then v2Completed:Fire(tick()) end

                    xCon:Disconnect()
                end)

                yTween.Completed:Connect(function()
                    counter = counter + 1
                    if counter == 2 then v2Completed:Fire(tick()) end

                    yCon:Disconnect()
                end)

                local TweenTbl = { X = xTween, Y = yTween }

                local Index = { Completed = v2Completed.Event }
                function Index:Play()
                    TweenTbl.X:Play()
                    TweenTbl.Y:Play()
                end
                setmetatable(TweenTbl, {
                    __index = Index
                })

                TweenTbl.Completed:Connect(function()
                    check()
                end)
                Tweens[k] = TweenTbl

            elseif Type == "Color3" then
                local Color = Instance.new("Color3Value")
                local Tween = TweenService:Create(Color, args[2], { Value = v })
                local con;

                if obj[k] then
                    Color.Value = obj[k]
                end

                con = Color:GetPropertyChangedSignal("Value"):Connect(function()
                    obj[k] = Color.Value
                end)

                Tween.Completed:Connect(function()
                    check()
                    con:Disconnect()
                end)

                Tweens[k] = Tween
            end
        end

        return Tweens
    end
end)

function Clear()
    for _, v in pairs(Environment) do
        v:Remove()
    end
end

return { Create = Create; Draw = Draw; Environment = Environment; Clear = Clear; Convert = Convert}