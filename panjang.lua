-- SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local okCoreGui, CoreGui = pcall(function() return game:GetService("CoreGui") end)
if not okCoreGui then CoreGui = nil end

local okVirtualUser, VirtualUser = pcall(function() return game:GetService("VirtualUser") end)
if not okVirtualUser then VirtualUser = nil end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========================================================
-- CONFIGURATION & STATE
-- ========================================================
local isScriptRunning = true
local Connections = {}

-- 1. Auto Plant Configuration
local PlantConfig = {
    CROP_NAME = "Cabai",
    BUY_COUNT = 100,
    INTER_ACTION_DELAY = 0.15,
    CYCLE_COOLDOWN = 0.10,
    DEFAULT_LAHAN = "Semua Lahan",
    USE_TELEPORT = true,
    TP_SETTLE_DELAY = 0.05,
    TP_SAFETY_OFFSET = Vector3.new(0, 1.5, 0),
    PROMPT_TIMEOUT = 1.0,
    PLANT_MODE = "Normal",
    SPEED_DELAY = 0.02,
    RETRY_FAILED = true,
    MAX_RETRIES = 2
}

local PlantState = {
    IsRunning = false,
    SelectedLahan = "Semua Lahan",
    SelectedCrop = "Cabai",
    ActivePots = 0,
    SuccessCount = 0,
    FailCount = 0,
    CycleCount = 0
}

-- 2. Auto Clean Configuration
local CleanConfig = {
    CHECK_INTERVAL = 0.05,
    ACTION_COOLDOWN = 0.03,
    SEARCH_RADIUS = 300,
    SKIP_OWNED_BY_OTHERS = true,
    MAX_ATTEMPTS_PER_TARGET = 3,
    MAX_TARGETS_PER_CYCLE = 20
}

local CleanState = {
    IsRunning = false,
    CleanedCount = 0,
    ActiveTargets = 0,
    LastCleanTime = 0
}

-- 3. Auto Tenant / Penyewa Configuration
local TenantConfig = {
    DEFAULT_INTERVAL = 1.0,
    MAX_CONSECUTIVE_ERRORS = 5,
    BACKOFF_DURATION = 5.0,
    INTER_PROMPT_DELAY = 0.05
}

local TenantState = {
    IsRunning = false,
    AutoTerima = true,
    AutoTagih = true,
    TerimaCount = 0,
    TagihCount = 0,
    ConsecutiveErrors = 0,
    LastErrorTime = 0
}

-- 4. Auto Spin Configuration
local SpinConfig = {
    CHECK_INTERVAL = 1.0,
    CLAIM_INTERVAL = 0.5,
    MAX_RETRIES = 3,
    BURST_CALLS = 2
}

local SpinState = {
    IsRunning = false,
    TotalClaimed = 0,
    LastClaimTime = 0,
    FailedAttempts = 0
}

-- 5. Anti-AFK Configuration
local AntiAfkConfig = {
    IDLE_THRESHOLD = 900,
    HEARTBEAT_INTERVAL = 30,
    VIRTUAL_CLICK_ENABLED = true,
    ACTION_INTERVAL = 45
}

local AntiAfkState = {
    Enabled = true,
    LastActive = os.clock(),
    BypassCount = 0
}

-- Thread trackers
local plantingThread = nil
local cleaningThread = nil
local tenantThread = nil
local spinWatcherThread = nil
local antiAfkThread = nil

-- Remote Function Cache
local remoteCache = {}
local function getRemote(serviceName, remoteType, remoteName)
    local key = serviceName .. "." .. remoteType .. "." .. remoteName
    if remoteCache[key] and remoteCache[key].Parent then
        return remoteCache[key]
    end

    local ok, res = pcall(function()
        local svc = ReplicatedStorage:WaitForChild("NKSystem", 3)
            :WaitForChild("Packages", 3)
            :WaitForChild("Knit", 3)
            :WaitForChild("Services", 3)
            :WaitForChild(serviceName, 3)
        local folder = svc:WaitForChild(remoteType, 3)
        return folder:WaitForChild(remoteName, 3)
    end)

    if ok and res then
        remoteCache[key] = res
        return res
    end
    return nil
end

local function firePrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    if typeof(fireproximityprompt) == "function" then
        fireproximityprompt(prompt)
        return true
    elseif prompt:IsA("ProximityPrompt") then
        pcall(function() prompt:InputHoldBegin() end)
        task.wait(prompt.HoldDuration or 0)
        pcall(function() prompt:InputHoldEnd() end)
        return true
    end
    return false
end

local function safeTeleport(targetPos)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.CFrame = CFrame.new(targetPos)
    return true
end

local function ownerTokens()
    local tokens = { tostring(LocalPlayer.UserId) }
    local name = LocalPlayer.Name
    if name and name ~= "" then
        table.insert(tokens, string.lower(name))
    end
    local disp = LocalPlayer.DisplayName
    if disp and disp ~= "" and string.lower(disp) ~= string.lower(name) then
        table.insert(tokens, string.lower(disp))
    end
    return tokens
end

local function isOwnedByMe(model, tokens)
    tokens = tokens or ownerTokens()
    local str = string.lower(model.Name)
    for _, tk in ipairs(tokens) do
        if string.find(str, tk, 1, true) then return true end
    end
    return false
end

-- ========================================================
-- TERNAK & TRAKTOR HUB (+ AUTO ISI PAKAN TANPA MENDEKAT)
-- ========================================================
local TernakHub = (function()
    local cb = {
        traktor = function() end,
        dung = function() end,
        route = function() end,
        convert = function() end,
        pakan = function() end
    }
    local RunService = game:GetService("RunService")

    local TraktorConfig = {
        VehicleType = "Traktor",
        SpawnInterval = 5,
        SpawnWaitTimeout = 5,
        DriveInterval = 3,
        AutoBoard = true,
        BoardSettleDelay = 0.3,
        BoardRetries = 3
    }

    local TraktorState = {
        SpawnRunning = false,
        DriveRunning = false,
        SpawnCount = 0,
        DriveCount = 0,
        LastDrivenModel = nil,
        LastDrivenChar = nil
    }

    local traktorSpawnThread = nil
    local traktorDriveThread = nil
    local traktorRemotes = {}

    local function getTraktorRemote(kind, name)
        local key = kind .. "." .. name
        local cached = traktorRemotes[key]
        if cached and cached.Parent then return cached end

        local ok, remote = pcall(function()
            return ReplicatedStorage
                :WaitForChild("NKSystem", 5)
                :WaitForChild("Packages", 5)
                :WaitForChild("Knit", 5)
                :WaitForChild("Services", 5)
                :WaitForChild("TraktorService", 5)
                :WaitForChild(kind, 5)
                :WaitForChild(name, 5)
        end)
        if ok and remote then
            traktorRemotes[key] = remote
            return remote
        end
        return nil
    end

    local function findMyTraktor()
        local folder = Workspace:FindFirstChild("KendaraanTraktor")
        if not folder then return nil end

        local exact = folder:FindFirstChild("Traktor_" .. tostring(LocalPlayer.UserId))
        if exact then return exact end

        local tokens = ownerTokens()
        for _, child in ipairs(folder:GetChildren()) do
            local lname = string.lower(child.Name)
            for _, tk in ipairs(tokens) do
                if string.find(lname, tk, 1, true) then return child end
            end
        end
        return nil
    end

    local RouteConfig = {
        ModelName = "Traktor_Kotoran",
        Profiles = {
            {
                Name = "Rute",
                KandangNames = { "Kandang_1", "Kandang_2", "Kandang_3", "Kandang_4" },
                KandangSelected = { true, true, true, true },
                PlotKeywords = {}
            },
            {
                Name = "Plot 8",
                KandangNames = { "Kandang_1", "Kandang_2", "Kandang_3", "Kandang_4",
                                 "Kandang_5", "Kandang_6", "Kandang_7", "Kandang_8" },
                KandangSelected = { true, true, true, true, true, true, true, true },
                PlotKeywords = { "plot 8", "plot_8", "plot8" }
            }
        },
        Speed = 26,
        TurnSpeed = 7,
        ArriveDistance = 4,
        DwellTime = 0.2, -- Dwell time cepat rute kandang
        Loop = true,
        StartAtNearest = true,
        UseTargetY = false,
        HeightOffset = 0,
        RequireSeated = true,
        AutoStartDrive = true
    }

    local function findDriveTraktor()
        local folder = Workspace:FindFirstChild("KendaraanTraktor")
        if not folder then return nil end

        local want = string.lower(RouteConfig.ModelName)
        local tokens = ownerTokens()
        local exactMatch, ownedMatch = nil, nil

        for _, child in ipairs(folder:GetChildren()) do
            local lname = string.lower(child.Name)
            if lname == want then
                exactMatch = child
            elseif string.find(lname, want, 1, true) == 1 and isOwnedByMe(child, tokens) then
                ownedMatch = child
            end
        end

        return ownedMatch or exactMatch or findMyTraktor()
    end

    local function spawnTraktor()
        local rf = getTraktorRemote("RF", "Spawn")
        if not rf then
            warn("[Traktor] Remote TraktorService.Spawn tidak ditemukan")
            return false
        end

        local okCall, result = pcall(function()
            return rf:InvokeServer(TraktorConfig.VehicleType, nil)
        end)

        if okCall and type(result) == "table" and result.ok then
            TraktorState.SpawnCount += 1
            print("[Traktor] Spawn OK")
            return true
        end

        warn("[Traktor] Spawn gagal/ditolak server")
        return false
    end

    local function driveTraktor(model)
        if typeof(firesignal) ~= "function" then
            warn("[Traktor] Executor tidak mendukung firesignal, mengemudi otomatis tidak bisa dijalankan")
            return false
        end

        local re = getTraktorRemote("RE", "MulaiMengemudi")
        if not re then
            warn("[Traktor] Remote TraktorService.MulaiMengemudi tidak ditemukan")
            return false
        end

        local okFire, err = pcall(function()
            firesignal(re.OnClientEvent, model, {})
        end)
        if not okFire then
            warn("[Traktor Error]:", err)
            return false
        end

        TraktorState.DriveCount += 1
        print("[Traktor] Mulai mengemudi: " .. model.Name)
        return true
    end

    local function boardTraktor(model)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return false end

        local function seated()
            return hum.SeatPart ~= nil and hum.SeatPart:IsDescendantOf(model)
        end
        if seated() then return true end

        local seat = model:FindFirstChildWhichIsA("VehicleSeat", true) or model:FindFirstChildWhichIsA("Seat", true)
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        local basePos = seat and seat.Position or model:GetPivot().Position

        if not seat and not prompt then
            safeTeleport(basePos)
            task.wait(TraktorConfig.BoardSettleDelay)
            return true
        end

        for _ = 1, TraktorConfig.BoardRetries do
            if not isScriptRunning then return false end

            safeTeleport(basePos)
            task.wait(TraktorConfig.BoardSettleDelay)

            if seat then
                pcall(function() seat:Sit(hum) end)
                pcall(function() hrp.CFrame = seat.CFrame * CFrame.new(0, 2, 0) end)
                task.wait(TraktorConfig.BoardSettleDelay)
                if seated() then break end
            end

            if prompt and prompt.Enabled then
                pcall(function()
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = 999999
                    prompt.HoldDuration = 0
                end)
                pcall(firePrompt, prompt)
                task.wait(TraktorConfig.BoardSettleDelay)
                if seated() then break end
            end
        end

        if seated() then
            print("[Traktor] Duduk di traktor: " .. model.Name)
            return true
        end
        warn("[Traktor] Gagal naik ke traktor " .. model.Name .. " (kursi/prompt tidak merespons)")
        return false
    end

    local function startDriving(model)
        if TraktorConfig.AutoBoard and not boardTraktor(model) then
            return false
        end
        return driveTraktor(model)
    end

    local function startTraktorSpawnWorker()
        if traktorSpawnThread then return end
        traktorSpawnThread = task.spawn(function()
            while TraktorState.SpawnRunning and isScriptRunning do
                if not findDriveTraktor() then
                    if spawnTraktor() then
                        local waited = 0
                        while TraktorState.SpawnRunning and waited < TraktorConfig.SpawnWaitTimeout and not findDriveTraktor() do
                            task.wait(0.25)
                            waited += 0.25
                        end
                    end
                    cb.traktor()
                end
                task.wait(TraktorConfig.SpawnInterval)
            end
            traktorSpawnThread = nil
        end)
    end

    local function stopTraktorSpawnWorker()
        TraktorState.SpawnRunning = false
        if traktorSpawnThread then
            task.cancel(traktorSpawnThread)
            traktorSpawnThread = nil
        end
    end

    local function startTraktorDriveWorker()
        if traktorDriveThread then return end
        traktorDriveThread = task.spawn(function()
            while TraktorState.DriveRunning and isScriptRunning do
                local model = findDriveTraktor()
                local char = LocalPlayer.Character
                if model and char and (model ~= TraktorState.LastDrivenModel or char ~= TraktorState.LastDrivenChar) then
                    if startDriving(model) then
                        TraktorState.LastDrivenModel = model
                        TraktorState.LastDrivenChar = char
                        cb.traktor()
                    end
                end
                task.wait(TraktorConfig.DriveInterval)
            end
            traktorDriveThread = nil
        end)
    end

    local function stopTraktorDriveWorker()
        TraktorState.DriveRunning = false
        TraktorState.LastDrivenModel = nil
        TraktorState.LastDrivenChar = nil
        if traktorDriveThread then
            task.cancel(traktorDriveThread)
            traktorDriveThread = nil
        end
    end

    local ConvertConfig = {
        Interval = 3,
        MinGap = 0.5,
        TriggerDelay = 0.3,
        OnlyWhenDriving = true
    }

    local ConvertState = {
        Running = false,
        Count = 0,
        Fail = 0,
        Last = 0,
        Busy = false,
        LastSuccess = nil
    }

    local convertThread = nil
    local convertRF = nil

    local function getConvertRemote()
        if convertRF and convertRF.Parent then return convertRF end
        pcall(function()
            convertRF = ReplicatedStorage
                :WaitForChild("NKSystem", 5)
                :WaitForChild("Packages", 5)
                :WaitForChild("Knit", 5)
                :WaitForChild("Services", 5)
                :WaitForChild("ConvertService", 5)
                :WaitForChild("RF", 5)
                :WaitForChild("Masukkan", 5)
        end)
        return convertRF
    end

    local function drivingNow()
        local model = findDriveTraktor()
        if not model then return false end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if seat ~= nil and seat:IsDescendantOf(model) then return true end
        return not RouteConfig.RequireSeated
    end

    local function summarizeResult(result)
        if type(result) ~= "table" then return tostring(result) end
        local parts, n = {}, 0
        for k, v in pairs(result) do
            n += 1
            if n > 8 then break end
            table.insert(parts, tostring(k) .. "=" .. tostring(v))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    local function convertNow()
        if ConvertState.Busy then return false end
        if os.clock() - ConvertState.Last < ConvertConfig.MinGap then return false end

        local rf = getConvertRemote()
        if not rf then
            warn("[Convert] Remote ConvertService.Masukkan tidak ditemukan")
            return false
        end

        ConvertState.Busy = true
        ConvertState.Last = os.clock()
        local okCall, result = pcall(function()
            return rf:InvokeServer()
        end)
        ConvertState.Busy = false

        local success = okCall and result ~= nil and result ~= false
        if success and type(result) == "table" and result.ok == false then
            success = false
        end

        if success then
            ConvertState.Count += 1
        else
            ConvertState.Fail += 1
        end

        if ConvertState.LastSuccess ~= success then
            ConvertState.LastSuccess = success
            local text = okCall and summarizeResult(result) or tostring(result)
            if success then
                print("[Convert] Masukkan OK | " .. text)
            else
                warn("[Convert] Masukkan ditolak/gagal | " .. text)
            end
        end

        cb.convert()
        return success
    end

    local function startConvertWorker()
        if convertThread then return end
        convertThread = task.spawn(function()
            while ConvertState.Running and isScriptRunning do
                if not ConvertConfig.OnlyWhenDriving or drivingNow() then
                    convertNow()
                end
                task.wait(ConvertConfig.Interval)
            end
            convertThread = nil
        end)
    end

    local function stopConvertWorker()
        ConvertState.Running = false
        if convertThread then
            task.cancel(convertThread)
            convertThread = nil
        end
    end

    -- ========================================================
    -- AUTO ISI PAKAN TERNAK (INSTANT REMOTE - TANPA MENDEKAT)
    -- ========================================================
    local PakanConfig = {
        Interval = 2, -- Cepat: isi pakan setiap 2 detik sekali
        Radius = 999999, -- Radius jauh tanpa batas
        PalungList = {
            { id = 1, name = "Palung_1" },
            { id = 2, name = "Palung_2" }
        }
    }

    local PakanState = {
        Running = false,
        Palung1Info = "P1: -",
        Palung2Info = "P2: -",
        SuccessCount = 0
    }

    local pakanThread = nil
    local pakanRF = nil

    local function getPakanRemote()
        if pakanRF and pakanRF.Parent then return pakanRF end
        pcall(function()
            pakanRF = ReplicatedStorage
                :WaitForChild("NKSystem", 5)
                :WaitForChild("Packages", 5)
                :WaitForChild("Knit", 5)
                :WaitForChild("Services", 5)
                :WaitForChild("TernakService", 5)
                :WaitForChild("RF", 5)
                :WaitForChild("IsiPakan", 5)
        end)
        return pakanRF
    end

    local function detectPalungObject(targetName)
        local lowerTarget = string.lower(targetName)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local playerPos = hrp and hrp.Position or Vector3.zero

        for _, obj in ipairs(Workspace:GetDescendants()) do
            local lname = string.lower(obj.Name)
            if lname == lowerTarget or string.find(lname, lowerTarget, 1, true) then
                local objPos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj:GetPivot().Position or nil)
                if objPos then
                    local dist = (objPos - playerPos).Magnitude
                    if dist <= PakanConfig.Radius then
                        return obj
                    end
                else
                    return obj
                end
            end
        end
        return nil
    end

    local function bypassPalungPrompt(palungObj)
        if not palungObj then return end
        for _, prompt in ipairs(palungObj:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                pcall(function()
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = 999999
                    prompt.HoldDuration = 0
                    if prompt.Enabled then
                        firePrompt(prompt)
                    end
                end)
            end
        end
    end

    local function isiPakan(palungId, palungObj)
        if palungObj then
            bypassPalungPrompt(palungObj)
        end

        local rf = getPakanRemote()
        if not rf then
            warn("[IsiPakan]: Remote TernakService.RF.IsiPakan tidak ditemukan")
            return nil
        end

        local ok, res = pcall(function()
            return rf:InvokeServer(palungId)
        end)

        if ok and type(res) == "table" then
            PakanState.SuccessCount += 1
            local stok = res.stok or res.Stok or "-"
            local maxJml = res.jumlah or res.Jumlah or "-"
            local nama = res.nama or res.Nama or "Cabai"
            local infoStr = string.format("P%d: %s/%s (%s)", palungId, tostring(stok), tostring(maxJml), tostring(nama))
            if palungId == 1 then
                PakanState.Palung1Info = infoStr
            else
                PakanState.Palung2Info = infoStr
            end
            return res
        end
        return nil
    end

    local function startPakanWorker()
        if pakanThread then return end
        pakanThread = task.spawn(function()
            while PakanState.Running and isScriptRunning do
                for _, item in ipairs(PakanConfig.PalungList) do
                    if not PakanState.Running or not isScriptRunning then break end
                    local obj = detectPalungObject(item.name)
                    isiPakan(item.id, obj)
                    task.wait(0.2)
                end
                cb.pakan()
                task.wait(PakanConfig.Interval)
            end
            pakanThread = nil
        end)
    end

    local function stopPakanWorker()
        PakanState.Running = false
        if pakanThread then
            task.cancel(pakanThread)
            pakanThread = nil
        end
    end

    -- ========================================================
    -- DETEKSI KOTORAN CEPAT (TRAKTOR NGEBUT TANPA FREEZE)
    -- ========================================================
    local DungConfig = {
        TargetName = "Kotoran_Kambing__Kotoran",
        FuzzyPrefix = "kotoran_kambing",
        DetectInterval = 0.5, -- Dipercepat scan kotoran
        ArriveDistance = 4,
        RetryCooldown = 2,
        RequireOwned = false,
        OnlyWhenDriving = true,
        TextDelay = 0,        -- 0 detik: tidak ada jeda tulisan / tanpa freeze traktor
        DwellTime = 0.05      -- 0.05 detik: instan ambil kotoran dan langsung tancap gas
    }

    local DungState = {
        Running = false,
        Detected = 0,
        Collected = 0,
        Target = nil,
        StatusText = nil,
        LastLogged = nil,
        LastLogTime = 0,
        Recent = {}
    }

    local dungThread = nil

    local function objPosition(obj)
        if obj:IsA("BasePart") then return obj.Position end
        if obj:IsA("Attachment") then return obj.WorldPosition end
        if obj:IsA("ProximityPrompt") then return promptPosition(obj) end
        if obj:IsA("Model") then
            local ok, cf = pcall(function() return obj:GetPivot() end)
            if ok and cf then return cf.Position end
        end
        local sum, n = Vector3.zero, 0
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") then
                sum += d.Position
                n += 1
            end
        end
        return n > 0 and sum / n or nil
    end

    local function isSeatedIn(model)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        return seat ~= nil and seat:IsDescendantOf(model)
    end

    local function scanDung(fromPos)
        local exactName = string.lower(DungConfig.TargetName)
        local prefix = DungConfig.FuzzyPrefix ~= "" and string.lower(DungConfig.FuzzyPrefix) or nil
        local tokens = ownerTokens()
        local now = os.clock()

        local best, bestOwned, bestQuality, bestDist = nil, false, 0, math.huge
        local count = 0

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("ProximityPrompt") then
                local lname = string.lower(obj.Name)
                local isExact = (lname == exactName)
                local isFuzzy = (not isExact) and prefix and (string.find(lname, prefix, 1, true) ~= nil)

                if isExact or isFuzzy then
                    local recent = DungState.Recent[obj]
                    if not (recent and now - recent < DungConfig.RetryCooldown) then
                        local pos = objPosition(obj)
                        if pos then
                            local owned = isOwnedByMe(obj, tokens)
                            if owned or not DungConfig.RequireOwned then
                                count += 1
                                local dist = (pos - fromPos).Magnitude
                                local quality = isExact and 2 or 1

                                local better = false
                                if not best then
                                    better = true
                                elseif owned and not bestOwned then
                                    better = true
                                elseif owned == bestOwned then
                                    if quality > bestQuality then
                                        better = true
                                    elseif quality == bestQuality and dist < bestDist then
                                        better = true
                                    end
                                end

                                if better then
                                    best = obj
                                    bestOwned = owned
                                    bestQuality = quality
                                    bestDist = dist
                                end
                            end
                        end
                    end
                end
            end
        end

        return best, count
    end

    local function startDungWorker()
        if dungThread then return end
        dungThread = task.spawn(function()
            while DungState.Running and isScriptRunning do
                local driving = drivingNow()
                if driving or not DungConfig.OnlyWhenDriving then
                    local model = findDriveTraktor()
                    local char = LocalPlayer.Character
                    local fromPos = (model and model:GetPivot().Position)
                        or (char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position)

                    if fromPos then
                        local best, count = scanDung(fromPos)
                        DungState.Target = best
                        DungState.Detected = count

                        local now = os.clock()
                        if best and (now - DungState.LastLogTime >= DungConfig.TextDelay) and DungState.LastLogged ~= best then
                            DungState.LastLogged = best
                            DungState.LastLogTime = now
                            local p = objPosition(best)
                            local dStr = p and string.format("%.1f studs", (p - fromPos).Magnitude) or "?"
                            print("[Kotoran] Target: " .. best.Name .. " (" .. dStr .. ") | Total: " .. count)
                        end
                        cb.dung()
                    else
                        DungState.Target = nil
                        DungState.Detected = 0
                        cb.dung()
                    end
                else
                    DungState.Target = nil
                    cb.dung()
                end
                task.wait(DungConfig.DetectInterval)
            end
            dungThread = nil
        end)
    end

    local function stopDungWorker()
        DungState.Running = false
        DungState.Target = nil
        DungState.StatusText = nil
        if dungThread then
            task.cancel(dungThread)
            dungThread = nil
        end
    end

    local RouteState = {
        Running = false,
        Profile = 1,
        KIndex = 1,
        KandangPos = nil,
        Laps = 0,
        Finished = false,
        NeedInit = true,
        WarnedEmpty = false
    }

    local routeThread = nil

    local function selectedKandangNames()
        local prof = RouteConfig.Profiles[RouteState.Profile]
        if not prof then return {} end
        local res = {}
        for i, name in ipairs(prof.KandangNames) do
            if prof.KandangSelected[i] then
                table.insert(res, name)
            end
        end
        return res
    end

    local function findPlot8Kandang(name)
        local kandangFolder = Workspace:FindFirstChild("Kandang")
        if kandangFolder then
            local direct = kandangFolder:FindFirstChild(name)
            if direct then return direct end
        end

        local prof = RouteConfig.Profiles[2]
        local lowerName = string.lower(name)

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Folder") then
                local objLower = string.lower(obj.Name)
                local matchesKeyword = false
                for _, kw in ipairs(prof.PlotKeywords) do
                    if string.find(objLower, kw, 1, true) then
                        matchesKeyword = true
                        break
                    end
                end

                if matchesKeyword then
                    local target = obj:FindFirstChild(name)
                    if target then return target end
                    for _, child in ipairs(obj:GetDescendants()) do
                        if string.lower(child.Name) == lowerName then
                            return child
                        end
                    end
                end
            end
        end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if string.lower(obj.Name) == lowerName then
                return obj
            end
        end

        return nil
    end

    local function findKandangPos(name, fromPos)
        local obj = nil
        if RouteState.Profile == 2 then
            obj = findPlot8Kandang(name)
        else
            local folder = Workspace:FindFirstChild("Kandang")
            obj = folder and folder:FindFirstChild(name)
        end

        if not obj then return nil end
        if obj:IsA("BasePart") then return obj.Position end
        if obj:IsA("Model") then
            local pivotOk, cf = pcall(function() return obj:GetPivot() end)
            if pivotOk and cf then return cf.Position end
            local prim = obj.PrimaryPart
            if prim then return prim.Position end
        end
        return nil
    end

    local function stepToward(model, dt, targetPos, arriveDist)
        local cf = model:GetPivot()
        local pos = cf.Position

        local flatTarget = Vector3.new(targetPos.X, RouteConfig.UseTargetY and targetPos.Y or pos.Y, targetPos.Z)
        local toTarget = flatTarget - pos
        local dist = toTarget.Magnitude

        if dist <= arriveDist then
            return true
        end

        local dir = toTarget.Unit
        local desiredLook = CFrame.lookAt(pos, pos + dir)
        local newRot = cf.Rotation:Lerp(desiredLook.Rotation, math.clamp(RouteConfig.TurnSpeed * dt, 0, 1))

        local moveStep = math.min(RouteConfig.Speed * dt, dist)
        local newPos = pos + dir * moveStep

        local finalCFrame = CFrame.new(newPos) * newRot
        if RouteConfig.HeightOffset ~= 0 then
            finalCFrame = finalCFrame * CFrame.new(0, RouteConfig.HeightOffset, 0)
        end

        pcall(function() model:PivotTo(finalCFrame) end)
        return false
    end

    local function routeTick(model)
        local pos = model:GetPivot().Position

        -- Prioritas 1: Ambil Kotoran Cepat (Tanpa Freeze Traktor)
        if DungState.Running and DungState.Target then
            local obj = DungState.Target
            if obj.Parent then
                local goal = objPosition(obj)
                if goal then
                    local dt = RunService.Heartbeat:Wait()
                    if stepToward(model, dt, goal, DungConfig.ArriveDistance) then
                        DungState.Recent[obj] = os.clock()
                        DungState.Target = nil
                        DungState.Collected += 1

                        -- Ambil instan tanpa jeda / freeze traktor
                        task.spawn(function()
                            DungState.StatusText = "Kotoran Diambil!"
                            cb.dung()
                            task.wait(0.35)
                            if DungState.StatusText == "Kotoran Diambil!" then
                                DungState.StatusText = nil
                                cb.dung()
                            end
                        end)

                        if ConvertState.Running then
                            task.delay(ConvertConfig.TriggerDelay, convertNow)
                        end
                    end
                    return
                end
            end
            DungState.Target = nil
        end

        -- Prioritas 2: Rute Kandang
        local list = selectedKandangNames()
        if #list == 0 then
            if not RouteState.WarnedEmpty then
                RouteState.WarnedEmpty = true
                warn("[Rute Traktor] Tidak ada kandang yang dipilih. Pilih minimal satu kandang di tab Ternak")
            end
            task.wait(1)
            return
        end
        RouteState.WarnedEmpty = false

        if RouteState.NeedInit then
            RouteState.NeedInit = false
            if RouteConfig.StartAtNearest then
                local bestIdx, bestDist = 1, math.huge
                for i, name in ipairs(list) do
                    local kp = findKandangPos(name, pos)
                    if kp then
                        local d = (kp - pos).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestIdx = i
                        end
                    end
                end
                RouteState.KIndex = bestIdx
            else
                RouteState.KIndex = 1
            end
            RouteState.KandangPos = nil
            cb.route()
        end

        if not RouteState.KandangPos then
            local name = list[RouteState.KIndex]
            if not name then
                RouteState.KIndex = 1
                name = list[1]
            end
            RouteState.KandangPos = findKandangPos(name, pos)
            if not RouteState.KandangPos then
                warn("[Rute Traktor] " .. name .. " tidak ditemukan di workspace, dilewati")
                RouteState.KIndex += 1
                task.wait(1)
                return
            end
        end

        local dt = RunService.Heartbeat:Wait()
        if stepToward(model, dt, RouteState.KandangPos, RouteConfig.ArriveDistance) then
            task.wait(RouteConfig.DwellTime)
            RouteState.KandangPos = nil
            RouteState.KIndex += 1
            if RouteState.KIndex > #list then
                RouteState.Laps += 1
                if RouteConfig.Loop then
                    RouteState.KIndex = 1
                else
                    RouteState.KIndex = #list
                    RouteState.Finished = true
                end
            end
            cb.route()
        end
    end

    local function startRouteWorker()
        if routeThread then return end
        RouteState.NeedInit = true
        RouteState.Finished = false
        routeThread = task.spawn(function()
            while RouteState.Running and isScriptRunning do
                local model = findDriveTraktor()
                if not model then
                    task.wait(1)
                elseif RouteConfig.RequireSeated and not isSeatedIn(model) then
                    if RouteConfig.AutoStartDrive then
                        startDriving(model)
                    end
                    task.wait(0.5)
                else
                    if RouteState.Finished then
                        task.wait(1)
                    else
                        routeTick(model)
                    end
                end
            end
            routeThread = nil
        end)
    end

    local function stopRouteWorker()
        RouteState.Running = false
        RouteState.KandangPos = nil
        if routeThread then
            task.cancel(routeThread)
            routeThread = nil
        end
    end

    local function toggleRouteProfile(pIndex)
        RouteState.Profile = pIndex
        RouteState.KIndex = 1
        RouteState.KandangPos = nil
        RouteState.Finished = false
        RouteState.NeedInit = true
        cb.route()
    end

    local function stopAll()
        stopTraktorSpawnWorker()
        stopTraktorDriveWorker()
        stopConvertWorker()
        stopPakanWorker()
        stopDungWorker()
        stopRouteWorker()
    end

    return {
        cb = cb,
        TraktorConfig = TraktorConfig, TraktorState = TraktorState,
        ConvertConfig = ConvertConfig, ConvertState = ConvertState,
        PakanConfig = PakanConfig,     PakanState = PakanState,
        DungConfig = DungConfig,       DungState = DungState,
        RouteConfig = RouteConfig,     RouteState = RouteState,
        startTraktorSpawnWorker = startTraktorSpawnWorker, stopTraktorSpawnWorker = stopTraktorSpawnWorker,
        startTraktorDriveWorker = startTraktorDriveWorker, stopTraktorDriveWorker = stopTraktorDriveWorker,
        startConvertWorker = startConvertWorker,           stopConvertWorker = stopConvertWorker,
        startPakanWorker = startPakanWorker,               stopPakanWorker = stopPakanWorker,
        startDungWorker = startDungWorker,                 stopDungWorker = stopDungWorker,
        startRouteWorker = startRouteWorker,               stopRouteWorker = stopRouteWorker,
        toggleRouteProfile = toggleRouteProfile,
        stopAll = stopAll
    }
end)()

-- ========================================================
-- GACHA HUB (+ FIX KLAIM HADIAH BERHADIAH MASUK KE TAS)
-- ========================================================
local GachaHub = (function()
    local Config = {
        SpinInterval = 1.0,
        ClaimDelay = 0.15,
        CycleCooldown = 1.8,
        MinInterval = 0.05
    }

    local State = {
        Running = false,
        Phase = "IDLE",
        BoxesOpened = 0,
        TotalOpened = 0,
        CycleCount = 0,
        CurrentResults = {},
        LastResultText = "Belum ada result gacha"
    }

    local spinMoneyRF = nil
    local claimRF = nil

    local function getGachaRemote(name)
        local rf = nil
        pcall(function()
            rf = ReplicatedStorage
                :WaitForChild("NKSystem", 5)
                :WaitForChild("Packages", 5)
                :WaitForChild("Knit", 5)
                :WaitForChild("Services", 5)
                :WaitForChild("GachaService", 5)
                :WaitForChild("RF", 5)
                :WaitForChild(name, 5)
        end)
        return rf
    end

    local onUpdate = function() end

    local function parseItemNames(raw)
        local items = {}
        if type(raw) ~= "table" then return items end

        local function checkTable(t, depth)
            if depth > 4 then return end
            if type(t) ~= "table" then return end

            local name = t.nama or t.name or t.Nama or t.Name or t.Item or t.Reward
            if name then
                local qty = t.jumlah or t.count or t.amount or t.stok or 1
                table.insert(items, string.format("%s (x%s)", tostring(name), tostring(qty)))
                return
            end

            for _, val in pairs(t) do
                if type(val) == "table" then
                    checkTable(val, depth + 1)
                elseif type(val) == "string" and #val > 2 and not (val == "ok" or val == "true") then
                    table.insert(items, val)
                end
            end
        end

        checkTable(raw, 1)
        return items
    end

    local function doSpinWithMoney()
        if not spinMoneyRF or not spinMoneyRF.Parent then
            spinMoneyRF = getGachaRemote("SpinX10WithMoney")
        end
        if not spinMoneyRF then
            warn("[AutoGacha]: Remote GachaService.SpinX10WithMoney tidak ditemukan")
            return false, nil
        end

        local ok, res = pcall(function()
            return spinMoneyRF:InvokeServer()
        end)
        return ok, res
    end

    local function doClaimReward(boxIndex)
        if not claimRF or not claimRF.Parent then
            claimRF = getGachaRemote("ClaimOneMultiReward")
        end
        if not claimRF then
            warn("[AutoGacha]: Remote GachaService.ClaimOneMultiReward tidak ditemukan")
            return false, nil
        end

        local ok, res = pcall(function()
            return claimRF:InvokeServer(boxIndex or 1)
        end)
        return ok, res
    end

    local workerThread = nil

    local function runGachaCycle()
        State.Phase = "RESET"
        State.BoxesOpened = 0
        table.clear(State.CurrentResults)
        State.LastResultText = "Reset hasil lama... Mengambil data baru"
        onUpdate()
        task.wait(0.2)

        State.Phase = "SPINNING"
        State.LastResultText = "Memutar Gacha 10x (Pakai Uang)..."
        onUpdate()

        local okSpin, spinRes = doSpinWithMoney()
        if not okSpin or not spinRes then
            State.Phase = "ERROR"
            State.LastResultText = "Gagal memutar gacha! Cek uang / server response"
            onUpdate()
            return false
        end

        if type(spinRes) == "table" and spinRes.ok == false then
            State.Phase = "REJECTED"
            State.LastResultText = "Spin ditolak server: " .. tostring(spinRes.msg or "Uang tidak cukup")
            onUpdate()
            return false
        end

        local rawResults = (type(spinRes) == "table" and (spinRes.results or spinRes.Results)) or spinRes
        local parsedItems = parseItemNames(rawResults)
        State.CurrentResults = parsedItems

        State.Phase = "OPENING"
        State.LastResultText = "Membuka 10 Box Blindbox..."
        onUpdate()

        for boxIndex = 1, 10 do
            if not State.Running or not isScriptRunning then break end

            local okClaim, claimRes = doClaimReward(boxIndex)
            State.BoxesOpened = boxIndex
            State.TotalOpened += 1

            local curItem = parsedItems[boxIndex] or ("Box #" .. boxIndex)
            State.LastResultText = string.format("Membuka Box %d/10: %s", boxIndex, tostring(curItem))
            onUpdate()

            task.wait(Config.ClaimDelay)
        end

        State.Phase = "COMPLETED"
        State.CycleCount += 1

        if #parsedItems > 0 then
            local preview = {}
            for i = 1, math.min(5, #parsedItems) do
                table.insert(preview, parsedItems[i])
            end
            local text = table.concat(preview, ", ")
            if #parsedItems > 5 then
                text = text .. string.format(" (+%d lagi)", #parsedItems - 5)
            end
            State.LastResultText = string.format("Selesai 10 Box! Dapat: %s", text)
        else
            State.LastResultText = "Selesai 10 Box! Hadiah berhasil diklaim ke tas."
        end
        onUpdate()

        return true
    end

    local function startWorker()
        if workerThread then return end
        workerThread = task.spawn(function()
            while State.Running and isScriptRunning do
                local success = runGachaCycle()
                if not State.Running or not isScriptRunning then break end

                if success then
                    task.wait(Config.CycleCooldown)
                else
                    task.wait(2.5)
                end
            end
            State.Phase = "IDLE"
            workerThread = nil
            onUpdate()
        end)
    end

    local function stopWorker()
        State.Running = false
        if workerThread then
            task.cancel(workerThread)
            workerThread = nil
        end
        State.Phase = "IDLE"
        onUpdate()
    end

    local function setOnUpdate(fn)
        if type(fn) == "function" then
            onUpdate = fn
        end
    end

    return {
        Config = Config,
        State = State,
        startWorker = startWorker,
        stopWorker = stopWorker,
        stopAll = stopWorker,
        setOnUpdate = setOnUpdate
    }
end)()

-- ========================================================
-- CORE FUNCTIONS & WORKERS
-- ========================================================
local function buyCrop(cropName, amount)
    local rf = getRemote("TokoService", "RF", "Beli")
    if not rf then return false end
    local ok, res = pcall(function()
        return rf:InvokeServer(cropName, amount)
    end)
    return ok and res
end

local function plantCrop(potObject, cropName)
    local rf = getRemote("TanamanService", "RF", "Tanam")
    if not rf then return false end
    local ok, res = pcall(function()
        return rf:InvokeServer(potObject, cropName)
    end)
    return ok and res
end

local function startPlantingLoop()
    if plantingThread then return end
    PlantState.IsRunning = true
    plantingThread = task.spawn(function()
        while PlantState.IsRunning and isScriptRunning do
            buyCrop(PlantState.SelectedCrop, PlantConfig.BUY_COUNT)
            task.wait(PlantConfig.INTER_ACTION_DELAY)

            local plots = Workspace:FindFirstChild("Lahan")
            if plots then
                for _, plot in ipairs(plots:GetChildren()) do
                    if not PlantState.IsRunning or not isScriptRunning then break end
                    if PlantState.SelectedLahan == "Semua Lahan" or plot.Name == PlantState.SelectedLahan then
                        for _, pot in ipairs(plot:GetChildren()) do
                            if pot:IsA("Model") or pot:IsA("BasePart") then
                                if PlantConfig.USE_TELEPORT then
                                    local pPos = pot:IsA("BasePart") and pot.Position or pot:GetPivot().Position
                                    safeTeleport(pPos + PlantConfig.TP_SAFETY_OFFSET)
                                    task.wait(PlantConfig.TP_SETTLE_DELAY)
                                end
                                plantCrop(pot, PlantState.SelectedCrop)
                                PlantState.SuccessCount += 1
                                task.wait(PlantConfig.SPEED_DELAY)
                            end
                        end
                    end
                end
            end
            PlantState.CycleCount += 1
            task.wait(PlantConfig.CYCLE_COOLDOWN)
        end
        plantingThread = nil
    end)
end

local function stopPlantingLoop()
    PlantState.IsRunning = false
    if plantingThread then
        task.cancel(plantingThread)
        plantingThread = nil
    end
end

local function startCleaningLoop()
    if cleaningThread then return end
    CleanState.IsRunning = true
    cleaningThread = task.spawn(function()
        while CleanState.IsRunning and isScriptRunning do
            local sampahFolder = Workspace:FindFirstChild("Sampah")
            if sampahFolder then
                for _, item in ipairs(sampahFolder:GetChildren()) do
                    if not CleanState.IsRunning or not isScriptRunning then break end
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        pcall(function()
                            prompt.RequiresLineOfSight = false
                            prompt.MaxActivationDistance = 999999
                            prompt.HoldDuration = 0
                        end)
                        firePrompt(prompt)
                        CleanState.CleanedCount += 1
                        task.wait(CleanConfig.ACTION_COOLDOWN)
                    end
                end
            end
            task.wait(CleanConfig.CHECK_INTERVAL)
        end
        cleaningThread = nil
    end)
end

local function stopCleaningLoop()
    CleanState.IsRunning = false
    if cleaningThread then
        task.cancel(cleaningThread)
        cleaningThread = nil
    end
end

local function startTenantWorker()
    if tenantThread then return end
    TenantState.IsRunning = true
    tenantThread = task.spawn(function()
        while TenantState.IsRunning and isScriptRunning do
            if TenantState.AutoTerima then
                local rfTerima = getRemote("PenyewaService", "RF", "TerimaPenyewa")
                if rfTerima then
                    pcall(function()
                        rfTerima:InvokeServer()
                        TenantState.TerimaCount += 1
                    end)
                end
            end
            task.wait(0.2)
            if TenantState.AutoTagih then
                local rfTagih = getRemote("PenyewaService", "RF", "TagihUangSewa")
                if rfTagih then
                    pcall(function()
                        rfTagih:InvokeServer()
                        TenantState.TagihCount += 1
                    end)
                end
            end
            task.wait(TenantConfig.DEFAULT_INTERVAL)
        end
        tenantThread = nil
    end)
end

local function stopTenantWorker()
    TenantState.IsRunning = false
    if tenantThread then
        task.cancel(tenantThread)
        tenantThread = nil
    end
end

local function startSpinWatcher()
    if spinWatcherThread then return end
    SpinState.IsRunning = true
    spinWatcherThread = task.spawn(function()
        while SpinState.IsRunning and isScriptRunning do
            local rfSpin = getRemote("SpinWheelService", "RF", "ClaimFreeSpin")
            if rfSpin then
                pcall(function()
                    rfSpin:InvokeServer()
                    SpinState.TotalClaimed += 1
                end)
            end
            task.wait(SpinConfig.CHECK_INTERVAL)
        end
        spinWatcherThread = nil
    end)
end

local function stopSpinWatcher()
    SpinState.IsRunning = false
    if spinWatcherThread then
        task.cancel(spinWatcherThread)
        spinWatcherThread = nil
    end
end

local function startAntiAfk()
    if antiAfkThread then return end
    AntiAfkState.Enabled = true
    antiAfkThread = task.spawn(function()
        while AntiAfkState.Enabled and isScriptRunning do
            if VirtualUser then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end
            task.wait(AntiAfkConfig.ACTION_INTERVAL)
        end
        antiAfkThread = nil
    end)
end

local function stopAntiAfk()
    AntiAfkState.Enabled = false
    if antiAfkThread then
        task.cancel(antiAfkThread)
        antiAfkThread = nil
    end
end

-- ========================================================
-- CYBERPUNK MODERN UI (BY SMITH GANTENG)
-- ========================================================
local TWEEN_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IndoKostUltraHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if CoreGui and pcall(function() ScreenGui.Parent = CoreGui end) then
else
    ScreenGui.Parent = PlayerGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 360)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 255, 204)
Stroke.Thickness = 1.2
Stroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(22, 25, 38)
Header.BorderSizePixel = 0
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.Text = "INDO KOST ULTRA HUB - SMITH GANTENG"
Title.TextColor3 = Color3.fromRGB(0, 255, 204)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 11
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 28)
TabBar.Position = UDim2.new(0, 10, 0, 44)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.Parent = TabBar

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -82)
ContentFrame.Position = UDim2.new(0, 10, 0, 76)
ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 23, 34)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame
Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 8)

local TabButtons = {}
local TabPages = {}

local function createTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 78, 1, 0)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(160, 165, 185)
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 204)
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 420)
    page.Parent = ContentFrame

    TabButtons[name] = btn
    TabPages[name] = page
    return btn, page
end

local function selectTab(activeName)
    for name, btn in pairs(TabButtons) do
        local isTarget = (name == activeName)
        TweenService:Create(btn, TWEEN_FAST, {
            BackgroundColor3 = isTarget and Color3.fromRGB(0, 255, 204) or Color3.fromRGB(30, 34, 48),
            TextColor3 = isTarget and Color3.fromRGB(15, 17, 26) or Color3.fromRGB(160, 165, 185)
        }):Play()
    end
    for name, page in pairs(TabPages) do
        page.Visible = (name == activeName)
    end
end

local function createModernCard(parent, height, posY)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(26, 30, 44)
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    return card
end

-- TABS
local plantTabBtn, PlantPage = createTab("🌱 TANAM", 1)
local cleanTabBtn, CleanPage = createTab("🧹 BERSIH", 2)
local tenantTabBtn, TenantPage = createTab("👥 SEWA", 3)
local ternakTabBtn, TernakPage = createTab("🚜 TERNAK", 4)
local gachaTabBtn, GachaPage = createTab("🎁 GACHA", 5)
local afkTabBtn, AfkPage = createTab("⚡ AFK", 6)

for tabName, btn in pairs(TabButtons) do
    table.insert(Connections, btn.Activated:Connect(function()
        selectTab(tabName)
    end))
end

-- ========================================================
-- BUILD UI: TAB TERNAK (+ AUTO ISI PALUNG TANPA MENDEKAT)
-- ========================================================
local function buildTernakPage()
    local H = TernakHub
    local TraktorState = H.TraktorState
    local ConvertState, startConvertWorker, stopConvertWorker = H.ConvertState, H.startConvertWorker, H.stopConvertWorker
    local startTraktorSpawnWorker, stopTraktorSpawnWorker = H.startTraktorSpawnWorker, H.stopTraktorSpawnWorker
    local startTraktorDriveWorker, stopTraktorDriveWorker = H.startTraktorDriveWorker, H.stopTraktorDriveWorker
    local PakanState, startPakanWorker, stopPakanWorker = H.PakanState, H.startPakanWorker, H.stopPakanWorker
    local DungState, startDungWorker, stopDungWorker = H.DungState, H.startDungWorker, H.stopDungWorker
    local RouteConfig, RouteState = H.RouteConfig, H.RouteState
    local toggleRouteProfile = H.toggleRouteProfile

    local traktorCard = createModernCard(TernakPage, 76, 0)

    local function makeSwitchRow(col, row, labelText)
        local posY = 4 + row * 24

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, -60, 0, 20)
        lbl.Position = UDim2.new(col * 0.5, 8, 0, posY)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(230, 230, 245)
        lbl.TextSize = 9
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = traktorCard

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 44, 0, 20)
        btn.Position = UDim2.new(col * 0.5 + 0.5, -52, 0, posY)
        btn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.Text = "OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 9
        btn.AutoButtonColor = false
        btn.Parent = traktorCard
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return lbl, btn
    end

    local function paintSwitch(btn, on)
        local col = on and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
        TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = col }):Play()
        btn.Text = on and "ON" or "OFF"
    end

    local spawnLbl, spawnBtn = makeSwitchRow(0, 0, "🚜 Spawn Traktor")
    local driveLbl, driveBtn = makeSwitchRow(1, 0, "🚗 TP & Naik")
    local routeLbl, routeBtn = makeSwitchRow(0, 1, "🛞 Setir Rute")
    local dungLbl, dungBtn = makeSwitchRow(1, 1, "💨 Kotoran Cepat")

    local prof1 = RouteConfig.Profiles[1]
    for i, kName in ipairs(prof1.KandangNames) do
        local kBtn = Instance.new("TextButton")
        kBtn.Size = UDim2.new(0.25, -8, 0, 20)
        kBtn.Position = UDim2.new((i - 1) * 0.25, 5, 0, 52)
        kBtn.BorderSizePixel = 0
        kBtn.Font = Enum.Font.GothamBold
        kBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        kBtn.TextSize = 9
        kBtn.AutoButtonColor = false
        kBtn.Parent = traktorCard
        Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0, 6)

        local function paintKandang()
            local on = prof1.KandangSelected[i]
            kBtn.BackgroundColor3 = on and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
            kBtn.Text = (on and "✔ " or "") .. string.gsub(kName, "_", " ")
        end
        paintKandang()

        table.insert(Connections, kBtn.Activated:Connect(function()
            prof1.KandangSelected[i] = not prof1.KandangSelected[i]
            paintKandang()
            if RouteState.Profile == 1 then
                RouteState.KandangPos = nil
                RouteState.Finished = false
                RouteState.NeedInit = true
            end
        end))
    end

    H.cb.traktor = function()
        spawnLbl.Text = string.format("🚜 Spawn Traktor (%dx)", TraktorState.SpawnCount)
        driveLbl.Text = string.format("🚗 TP & Naik (%dx)", TraktorState.DriveCount)
    end

    H.cb.dung = function()
        if DungState.StatusText then
            dungLbl.Text = string.format("💨 %s (%dx)", DungState.StatusText, DungState.Collected)
        else
            dungLbl.Text = string.format("💨 Kotoran Cepat (%d | %dx)", DungState.Detected, DungState.Collected)
        end
    end

    table.insert(Connections, dungBtn.Activated:Connect(function()
        DungState.Running = not DungState.Running
        paintSwitch(dungBtn, DungState.Running)
        if DungState.Running then
            startDungWorker()
        else
            stopDungWorker()
        end
    end))

    table.insert(Connections, spawnBtn.Activated:Connect(function()
        TraktorState.SpawnRunning = not TraktorState.SpawnRunning
        paintSwitch(spawnBtn, TraktorState.SpawnRunning)
        if TraktorState.SpawnRunning then
            startTraktorSpawnWorker()
        else
            stopTraktorSpawnWorker()
        end
    end))

    table.insert(Connections, driveBtn.Activated:Connect(function()
        TraktorState.DriveRunning = not TraktorState.DriveRunning
        paintSwitch(driveBtn, TraktorState.DriveRunning)
        if TraktorState.DriveRunning then
            startTraktorDriveWorker()
        else
            stopTraktorDriveWorker()
        end
    end))

    table.insert(Connections, routeBtn.Activated:Connect(function()
        RouteState.Running = not RouteState.Running
        paintSwitch(routeBtn, RouteState.Running)
        if RouteState.Running then
            startRouteWorker()
        else
            stopRouteWorker()
        end
    end))

    -- Mesin Convert Card
    local convertCard = createModernCard(TernakPage, 30, 82)

    local convertLbl = Instance.new("TextLabel")
    convertLbl.Size = UDim2.new(1, -76, 1, 0)
    convertLbl.Position = UDim2.new(0, 10, 0, 0)
    convertLbl.BackgroundTransparency = 1
    convertLbl.Font = Enum.Font.GothamBold
    convertLbl.Text = "♻️ Masukkan ke Mesin Convert"
    convertLbl.TextColor3 = Color3.fromRGB(230, 230, 245)
    convertLbl.TextSize = 9
    convertLbl.TextTruncate = Enum.TextTruncate.AtEnd
    convertLbl.TextXAlignment = Enum.TextXAlignment.Left
    convertLbl.Parent = convertCard

    local convertBtn = Instance.new("TextButton")
    convertBtn.Size = UDim2.new(0, 44, 0, 20)
    convertBtn.Position = UDim2.new(1, -54, 0.5, -10)
    convertBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
    convertBtn.BorderSizePixel = 0
    convertBtn.Font = Enum.Font.GothamBold
    convertBtn.Text = "OFF"
    convertBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    convertBtn.TextSize = 9
    convertBtn.AutoButtonColor = false
    convertBtn.Parent = convertCard
    Instance.new("UICorner", convertBtn).CornerRadius = UDim.new(0, 6)

    H.cb.convert = function()
        convertLbl.Text = string.format("♻️ Masukkan ke Mesin Convert (%d ok | %d gagal)", ConvertState.Count, ConvertState.Fail)
    end

    table.insert(Connections, convertBtn.Activated:Connect(function()
        ConvertState.Running = not ConvertState.Running
        paintSwitch(convertBtn, ConvertState.Running)
        if ConvertState.Running then
            startConvertWorker()
        else
            stopConvertWorker()
        end
    end))

    -- CARD: AUTO ISI PALUNG (TANPA MENDEKAT)
    local pakanCard = createModernCard(TernakPage, 40, 118)

    local pakanTitle = Instance.new("TextLabel")
    pakanTitle.Size = UDim2.new(1, -76, 0, 18)
    pakanTitle.Position = UDim2.new(0, 10, 0, 2)
    pakanTitle.BackgroundTransparency = 1
    pakanTitle.Font = Enum.Font.GothamBold
    pakanTitle.Text = "🌾 Auto Isi Palung (Tanpa Mendekat)"
    pakanTitle.TextColor3 = Color3.fromRGB(230, 230, 245)
    pakanTitle.TextSize = 9
    pakanTitle.TextXAlignment = Enum.TextXAlignment.Left
    pakanTitle.Parent = pakanCard

    local pakanSub = Instance.new("TextLabel")
    pakanSub.Size = UDim2.new(1, -76, 0, 16)
    pakanSub.Position = UDim2.new(0, 10, 0, 20)
    pakanSub.BackgroundTransparency = 1
    pakanSub.Font = Enum.Font.GothamMedium
    pakanSub.Text = "P1: - | P2: -"
    pakanSub.TextColor3 = Color3.fromRGB(150, 155, 175)
    pakanSub.TextSize = 8
    pakanSub.TextXAlignment = Enum.TextXAlignment.Left
    pakanSub.Parent = pakanCard

    local pakanBtn = Instance.new("TextButton")
    pakanBtn.Size = UDim2.new(0, 44, 0, 22)
    pakanBtn.Position = UDim2.new(1, -54, 0.5, -11)
    pakanBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
    pakanBtn.BorderSizePixel = 0
    pakanBtn.Font = Enum.Font.GothamBold
    pakanBtn.Text = "OFF"
    pakanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    pakanBtn.TextSize = 9
    pakanBtn.AutoButtonColor = false
    pakanBtn.Parent = pakanCard
    Instance.new("UICorner", pakanBtn).CornerRadius = UDim.new(0, 6)

    H.cb.pakan = function()
        pakanSub.Text = string.format("%s | %s", PakanState.Palung1Info, PakanState.Palung2Info)
    end

    table.insert(Connections, pakanBtn.Activated:Connect(function()
        PakanState.Running = not PakanState.Running
        paintSwitch(pakanBtn, PakanState.Running)
        if PakanState.Running then
            startPakanWorker()
        else
            stopPakanWorker()
        end
    end))

    -- Plot 8 Card
    local plot8Card = createModernCard(TernakPage, 76, 164)
    local prof2 = RouteConfig.Profiles[2]

    local plot8Lbl = Instance.new("TextLabel")
    plot8Lbl.Size = UDim2.new(1, -20, 0, 20)
    plot8Lbl.Position = UDim2.new(0, 8, 0, 4)
    plot8Lbl.BackgroundTransparency = 1
    plot8Lbl.Font = Enum.Font.GothamBold
    plot8Lbl.Text = "🚜 Rute Kandang Plot 8"
    plot8Lbl.TextColor3 = Color3.fromRGB(230, 230, 245)
    plot8Lbl.TextSize = 9
    plot8Lbl.TextXAlignment = Enum.TextXAlignment.Left
    plot8Lbl.Parent = plot8Card

    for i = 1, 8 do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        local kBtn = Instance.new("TextButton")
        kBtn.Size = UDim2.new(0.25, -6, 0, 20)
        kBtn.Position = UDim2.new(col * 0.25, 4, 0, 26 + row * 23)
        kBtn.BorderSizePixel = 0
        kBtn.Font = Enum.Font.GothamBold
        kBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        kBtn.TextSize = 8
        kBtn.AutoButtonColor = false
        kBtn.Parent = plot8Card
        Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0, 6)

        local function paintPlot8Kandang()
            local on = prof2.KandangSelected[i]
            kBtn.BackgroundColor3 = on and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
            kBtn.Text = (on and "✔ " or "") .. "K " .. tostring(i)
        end
        paintPlot8Kandang()

        table.insert(Connections, kBtn.Activated:Connect(function()
            prof2.KandangSelected[i] = not prof2.KandangSelected[i]
            paintPlot8Kandang()
            if RouteState.Profile == 2 then
                RouteState.KandangPos = nil
                RouteState.Finished = false
                RouteState.NeedInit = true
            end
        end))
    end
end

-- ========================================================
-- BUILD UI: TAB GACHA
-- ========================================================
local function buildGachaPage()
    local G = GachaHub
    local State = G.State
    local Config = G.Config

    local gachaCard = createModernCard(GachaPage, 84, 0)

    local gachaTitle = Instance.new("TextLabel")
    gachaTitle.Size = UDim2.new(1, -76, 0, 22)
    gachaTitle.Position = UDim2.new(0, 10, 0, 6)
    gachaTitle.BackgroundTransparency = 1
    gachaTitle.Font = Enum.Font.GothamBlack
    gachaTitle.Text = "🎁 Auto Gacha 10x Blindbox (Pakai Uang)"
    gachaTitle.TextColor3 = Color3.fromRGB(0, 255, 204)
    gachaTitle.TextSize = 11
    gachaTitle.TextXAlignment = Enum.TextXAlignment.Left
    gachaTitle.Parent = gachaCard

    local gachaSub = Instance.new("TextLabel")
    gachaSub.Size = UDim2.new(1, -76, 0, 48)
    gachaSub.Position = UDim2.new(0, 10, 0, 30)
    gachaSub.BackgroundTransparency = 1
    gachaSub.Font = Enum.Font.Gotham
    gachaSub.Text = "Status: IDLE | Box Terbuka: 0/10\nPutaran: 0 | Total Box: 0\nReset otomatis saat hasil keluar"
    gachaSub.TextColor3 = Color3.fromRGB(170, 175, 195)
    gachaSub.TextSize = 9
    gachaSub.TextWrapped = true
    gachaSub.TextXAlignment = Enum.TextXAlignment.Left
    gachaSub.TextYAlignment = Enum.TextYAlignment.Top
    gachaSub.Parent = gachaCard

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 52, 0, 26)
    toggleBtn.Position = UDim2.new(1, -62, 0, 10)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 10
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = gachaCard
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

    local resultCard = createModernCard(GachaPage, 80, 92)

    local resTitle = Instance.new("TextLabel")
    resTitle.Size = UDim2.new(1, -20, 0, 20)
    resTitle.Position = UDim2.new(0, 10, 0, 4)
    resTitle.BackgroundTransparency = 1
    resTitle.Font = Enum.Font.GothamBold
    resTitle.Text = "📋 Live Result & Deteksi 10 Box:"
    resTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    resTitle.TextSize = 10
    resTitle.TextXAlignment = Enum.TextXAlignment.Left
    resTitle.Parent = resultCard

    local resDesc = Instance.new("TextLabel")
    resDesc.Size = UDim2.new(1, -20, 0, 50)
    resDesc.Position = UDim2.new(0, 10, 0, 24)
    resDesc.BackgroundTransparency = 1
    resDesc.Font = Enum.Font.Gotham
    resDesc.Text = "Belum ada result gacha. Tekan ON untuk mulai memutar dan membuka 10 box."
    resDesc.TextColor3 = Color3.fromRGB(220, 225, 240)
    resDesc.TextSize = 9
    resDesc.TextWrapped = true
    resDesc.TextXAlignment = Enum.TextXAlignment.Left
    resDesc.TextYAlignment = Enum.TextYAlignment.Top
    resDesc.Parent = resultCard

    local function refreshUI()
        local phaseStr = State.Phase
        if phaseStr == "SPINNING" then
            phaseStr = "MEMUTAR GACHA (UANG)..."
        elseif phaseStr == "OPENING" then
            phaseStr = string.format("MEMBUKA BOX (%d/10)...", State.BoxesOpened)
        elseif phaseStr == "COMPLETED" then
            phaseStr = "10 BOX SELESAI!"
        elseif phaseStr == "RESET" then
            phaseStr = "RESET DATA LAMA..."
        end

        gachaSub.Text = string.format(
            "Status: %s\nBox Terbuka: %d/10 | Putaran: %d (Total: %d)\nDelay Buka: %.2fs | Jeda Siklus: %.1fs",
            phaseStr, State.BoxesOpened, State.CycleCount, State.TotalOpened,
            Config.ClaimDelay, Config.CycleCooldown
        )
        resDesc.Text = State.LastResultText
    end

    G.setOnUpdate(refreshUI)

    table.insert(Connections, toggleBtn.Activated:Connect(function()
        State.Running = not State.Running
        local on = State.Running
        TweenService:Create(toggleBtn, TWEEN_FAST, {
            BackgroundColor3 = on and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
        }):Play()
        toggleBtn.Text = on and "ON" or "OFF"

        if on then
            G.startWorker()
        else
            G.stopWorker()
        end
        refreshUI()
    end))
end

-- ========================================================
-- BUILD OTHER PAGES (PLANT, CLEAN, TENANT, AFK)
-- ========================================================
local function buildOtherPages()
    -- Plant Page
    local plantCard = createModernCard(PlantPage, 60, 0)
    local pLbl = Instance.new("TextLabel")
    pLbl.Size = UDim2.new(1, -70, 1, 0)
    pLbl.Position = UDim2.new(0, 10, 0, 0)
    pLbl.BackgroundTransparency = 1
    pLbl.Font = Enum.Font.GothamBold
    pLbl.Text = "🌱 Auto Tanam & Beli (" .. PlantConfig.CROP_NAME .. ")"
    pLbl.TextColor3 = Color3.fromRGB(230, 230, 245)
    pLbl.TextSize = 10
    pLbl.TextXAlignment = Enum.TextXAlignment.Left
    pLbl.Parent = plantCard

    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0, 48, 0, 24)
    pBtn.Position = UDim2.new(1, -58, 0.5, -12)
    pBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
    pBtn.BorderSizePixel = 0
    pBtn.Font = Enum.Font.GothamBold
    pBtn.Text = "OFF"
    pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    pBtn.TextSize = 10
    pBtn.Parent = plantCard
    Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)

    table.insert(Connections, pBtn.Activated:Connect(function()
        if PlantState.IsRunning then
            stopPlantingLoop()
            pBtn.Text = "OFF"
            pBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
        else
            startPlantingLoop()
            pBtn.Text = "ON"
            pBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        end
    end))

    -- Clean Page
    local cleanCard = createModernCard(CleanPage, 60, 0)
    local cLbl = Instance.new("TextLabel")
    cLbl.Size = UDim2.new(1, -70, 1, 0)
    cLbl.Position = UDim2.new(0, 10, 0, 0)
    cLbl.BackgroundTransparency = 1
    cLbl.Font = Enum.Font.GothamBold
    cLbl.Text = "🧹 Auto Bersih Sampah Kamar"
    cLbl.TextColor3 = Color3.fromRGB(230, 230, 245)
    cLbl.TextSize = 10
    cLbl.TextXAlignment = Enum.TextXAlignment.Left
    cLbl.Parent = cleanCard

    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 48, 0, 24)
    cBtn.Position = UDim2.new(1, -58, 0.5, -12)
    cBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
    cBtn.BorderSizePixel = 0
    cBtn.Font = Enum.Font.GothamBold
    cBtn.Text = "OFF"
    cBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cBtn.TextSize = 10
    cBtn.Parent = cleanCard
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)

    table.insert(Connections, cBtn.Activated:Connect(function()
        if CleanState.IsRunning then
            stopCleaningLoop()
            cBtn.Text = "OFF"
            cBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
        else
            startCleaningLoop()
            cBtn.Text = "ON"
            cBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        end
    end))

    -- Tenant Page
    local tenantCard = createModernCard(TenantPage, 60, 0)
    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -70, 1, 0)
    tLbl.Position = UDim2.new(0, 10, 0, 0)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = "👥 Auto Terima & Tagih Sewa"
    tLbl.TextColor3 = Color3.fromRGB(230, 230, 245)
    tLbl.TextSize = 10
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = tenantCard

    local tBtn = Instance.new("TextButton")
    tBtn.Size = UDim2.new(0, 48, 0, 24)
    tBtn.Position = UDim2.new(1, -58, 0.5, -12)
    tBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
    tBtn.BorderSizePixel = 0
    tBtn.Font = Enum.Font.GothamBold
    tBtn.Text = "OFF"
    tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tBtn.TextSize = 10
    tBtn.Parent = tenantCard
    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)

    table.insert(Connections, tBtn.Activated:Connect(function()
        if TenantState.IsRunning then
            stopTenantWorker()
            tBtn.Text = "OFF"
            tBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
        else
            startTenantWorker()
            tBtn.Text = "ON"
            tBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        end
    end))

    -- AFK Page
    local afkCard = createModernCard(AfkPage, 60, 0)
    local aLbl = Instance.new("TextLabel")
    aLbl.Size = UDim2.new(1, -70, 1, 0)
    aLbl.Position = UDim2.new(0, 10, 0, 0)
    aLbl.BackgroundTransparency = 1
    aLbl.Font = Enum.Font.GothamBold
    aLbl.Text = "⚡ Anti-AFK (Virtual Click & Disconnect Bypass)"
    aLbl.TextColor3 = Color3.fromRGB(230, 230, 245)
    aLbl.TextSize = 10
    aLbl.TextXAlignment = Enum.TextXAlignment.Left
    aLbl.Parent = afkCard

    local aBtn = Instance.new("TextButton")
    aBtn.Size = UDim2.new(0, 48, 0, 24)
    aBtn.Position = UDim2.new(1, -58, 0.5, -12)
    aBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    aBtn.BorderSizePixel = 0
    aBtn.Font = Enum.Font.GothamBold
    aBtn.Text = "ON"
    aBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    aBtn.TextSize = 10
    aBtn.Parent = afkCard
    Instance.new("UICorner", aBtn).CornerRadius = UDim.new(0, 6)

    table.insert(Connections, aBtn.Activated:Connect(function()
        if AntiAfkState.Enabled then
            stopAntiAfk()
            aBtn.Text = "OFF"
            aBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
        else
            startAntiAfk()
            aBtn.Text = "ON"
            aBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        end
    end))
end

-- Initialize Pages
buildOtherPages()
buildTernakPage()
buildGachaPage()
selectTab("🚜 TERNAK")
startAntiAfk()

-- Drag System
do
    local dragging = false
    local dragInput, dragStart, startPos

    table.insert(Connections, Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end))

    table.insert(Connections, Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput and dragStart then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- Close & Complete Cleanup
local function shutdown()
    isScriptRunning = false
    pcall(stopPlantingLoop)
    pcall(stopCleaningLoop)
    pcall(stopTenantWorker)
    pcall(stopSpinWatcher)
    pcall(stopAntiAfk)
    pcall(TernakHub.stopAll)
    pcall(GachaHub.stopAll)

    for _, conn in ipairs(Connections) do
        if conn and conn.Disconnect then pcall(function() conn:Disconnect() end) end
    end
    table.clear(Connections)

    pcall(function() ScreenGui:Destroy() end)
end

table.insert(Connections, CloseBtn.Activated:Connect(shutdown))

do
    local genv = (typeof(getgenv) == "function" and getgenv()) or _G
    genv.__IndoKostShutdown = shutdown
end
