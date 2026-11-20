
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
    USE_TELEPORT = true, -- Auto TP: teleport ke tiap plot sebelum menanam
    TP_SETTLE_DELAY = 0.05, -- jeda singkat setelah teleport sebelum tanam
    PLOT4_RADIUS = 1000 -- radius (studs) auto plant khusus Plot 4; plot di luar radius dilewati
}

local LAHAN_LIST = {
    ["Plot 4 Kanan 1"] = {
        Vector3.new(-524.1873168945312, 15.5, -308.36993408203125),
        Vector3.new(-539.720703125, 15.5, -309.0425720214844),
        Vector3.new(-557.5257568359375, 15.5, -310.53521728515625),
        Vector3.new(-575.1414794921875, 15.5, -312.2712097167969),
        Vector3.new(-594.4540405273438, 15.5, -311.93402099609375),
        Vector3.new(-627.4417114257812, 15.499998092651367, -313.681640625),
        Vector3.new(-610.0003662109375, 15.5, -309.58355712890625),
    },
    ["Plot 4 Kanan 2"] = {
        Vector3.new(-481.1759033203125, 15.5, -312.5938720703125),
        Vector3.new(-447.9565734863281, 15.500000953674316, -313.7166748046875),
        Vector3.new(-429.1582946777344, 15.500000953674316, -313.7612609863281),
        Vector3.new(-413.0259094238281, 15.5, -314.4434814453125),
        Vector3.new(-395.03643798828125, 15.5, -314.36480712890625),
        Vector3.new(-378.6339111328125, 15.500000953674316, -315.72528076171875),
    },
    ["Plot 4 Kiri A"] = {
        Vector3.new(-376.51953125, 15.499998092651367, -238.30813598632812),
        Vector3.new(-395.7886657714844, 15.5, -238.7544403076172),
        Vector3.new(-411.9199523925781, 15.5, -238.71746826171875),
        Vector3.new(-430.12469482421875, 15.5, -238.633544921875),
        Vector3.new(-446.92437744140625, 15.5, -238.82785034179688),
        Vector3.new(-464.1773986816406, 15.5, -238.52267456054688),
        Vector3.new(-479.4200439453125, 15.5, -237.79177856445312),
    },
    ["Plot 4 Kiri B"] = {
        Vector3.new(-626.8344116210938, 15.5, -230.7158660888672),
        Vector3.new(-523.2505493164062, 15.5, -229.5054931640625),
        Vector3.new(-540.0543823242188, 15.5, -229.42343139648438),
        Vector3.new(-558.4065551757812, 15.5, -228.7265167236328),
        Vector3.new(-574.9323120117188, 15.5, -229.35032653808594),
        Vector3.new(-592.9701538085938, 15.5, -228.72628784179688),
        Vector3.new(-609.5208740234375, 15.5, -228.6973114013672),
    },
    ["Lahan Kanan 1"] = {
        Vector3.new(-618.5881958007812, 15.499999046325684, -252.45172119140625),
        Vector3.new(-632.3125, 15.499999046325684, -253.161865234375),
        Vector3.new(-590.6769409179688, 15.500000953674316, -247.18519592285156),
        Vector3.new(-603.5460815429688, 15.500000953674316, -251.08877563476562),
    },
    ["Lahan Kanan 2"] = {
        Vector3.new(-517.0890502929688, 15.5, -250.7201690673828),
        Vector3.new(-531.0599975585938, 15.500000953674316, -252.03182983398438),
        Vector3.new(-544.1796264648438, 15.5, -251.0286407470703),
        Vector3.new(-556.2644653320312, 15.5, -244.6540069580078),
    },
    ["Lahan Kanan 3"] = {
        Vector3.new(-482.7235107421875, 15.499999046325684, -248.57882690429688),
        Vector3.new(-470.6371765136719, 15.5, -249.12124633789062),
        Vector3.new(-456.2996520996094, 15.5, -248.90750122070312),
        Vector3.new(-443.5169982910156, 15.5, -249.10556030273438),
    },
    ["Lahan Kanan 4"] = {
        Vector3.new(-408.9349060058594, 15.5, -252.46971130371094),
        Vector3.new(-397.1911315917969, 15.5, -249.8361358642578),
        Vector3.new(-382.33148193359375, 15.5, -242.9317626953125),
        Vector3.new(-370.10791015625, 15.5, -239.33607482910156),
    },
    ["Lahan Kiri 1"] = {
        Vector3.new(-630.9166259765625, 15.5, -321.91656494140625),
        Vector3.new(-618.759521484375, 15.5, -324.889892578125),
        Vector3.new(-604.3545532226562, 15.5, -323.1783752441406),
        Vector3.new(-590.7984619140625, 15.5, -320.9075012207031),
    },
    ["Lahan Kiri 2"] = {
        Vector3.new(-557.5001831054688, 15.5, -314.1703186035156),
        Vector3.new(-544.183837890625, 15.5, -316.4648132324219),
        Vector3.new(-530.4700927734375, 15.5, -317.07122802734375),
        Vector3.new(-516.580322265625, 15.500000953674316, -316.50634765625),
    },
    ["Lahan Kiri 3"] = {
        Vector3.new(-516.580322265625, 15.500000953674316, -316.50634765625),
        Vector3.new(-470.6393127441406, 15.5, -326.2953186035156),
        Vector3.new(-456.388916015625, 15.500000953674316, -322.6510925292969),
        Vector3.new(-443.1785888671875, 15.5, -319.5091247558594),
    },
    ["Lahan Kiri 4"] = {
        Vector3.new(-410.2164306640625, 15.5, -298.1622619628906),
        Vector3.new(-396.0249938964844, 15.499999046325684, -300.63201904296875),
        Vector3.new(-382.8375244140625, 15.5, -301.8544006347656),
        Vector3.new(-368.1260070800781, 15.5, -305.3680419921875),
    },
}

local function mergePlotGroups(names)
    local combined = {}
    for _, name in ipairs(names) do
        local plots = LAHAN_LIST[name]
        if plots then
            for _, pos in ipairs(plots) do
                table.insert(combined, pos)
            end
        end
    end
    return combined
end

local LAHAN_CATEGORIES = {
    "Semua Lahan",
    "Semua Kanan",
    "Semua Kiri",
    "Lahan Kanan 1",
    "Lahan Kanan 2",
    "Lahan Kanan 3",
    "Lahan Kanan 4",
    "Lahan Kiri 1",
    "Lahan Kiri 2",
    "Lahan Kiri 3",
    "Lahan Kiri 4",
    "Semua Plot 4",
    "Plot 4 Kanan 1",
    "Plot 4 Kanan 2",
    "Plot 4 Kiri A",
    "Plot 4 Kiri B"
}

local LAHAN_PRESETS = {
    ["Semua Lahan"] = mergePlotGroups({
        "Lahan Kanan 1", "Lahan Kanan 2", "Lahan Kanan 3", "Lahan Kanan 4",
        "Lahan Kiri 1", "Lahan Kiri 2", "Lahan Kiri 3", "Lahan Kiri 4"
    }),
    ["Semua Kanan"] = mergePlotGroups({"Lahan Kanan 1", "Lahan Kanan 2", "Lahan Kanan 3", "Lahan Kanan 4"}),
    ["Semua Kiri"]  = mergePlotGroups({"Lahan Kiri 1", "Lahan Kiri 2", "Lahan Kiri 3", "Lahan Kiri 4"}),
    ["Lahan Kanan 1"] = LAHAN_LIST["Lahan Kanan 1"],
    ["Lahan Kanan 2"] = LAHAN_LIST["Lahan Kanan 2"],
    ["Lahan Kanan 3"] = LAHAN_LIST["Lahan Kanan 3"],
    ["Lahan Kanan 4"] = LAHAN_LIST["Lahan Kanan 4"],
    ["Lahan Kiri 1"]  = LAHAN_LIST["Lahan Kiri 1"],
    ["Lahan Kiri 2"]  = LAHAN_LIST["Lahan Kiri 2"],
    ["Lahan Kiri 3"]  = LAHAN_LIST["Lahan Kiri 3"],
    ["Lahan Kiri 4"]  = LAHAN_LIST["Lahan Kiri 4"],
    -- Plot 4: terpisah, tidak masuk "Semua Lahan"
    ["Semua Plot 4"]  = mergePlotGroups({"Plot 4 Kanan 1", "Plot 4 Kanan 2", "Plot 4 Kiri A", "Plot 4 Kiri B"}),
    ["Plot 4 Kanan 1"] = LAHAN_LIST["Plot 4 Kanan 1"],
    ["Plot 4 Kanan 2"] = LAHAN_LIST["Plot 4 Kanan 2"],
    ["Plot 4 Kiri A"]  = LAHAN_LIST["Plot 4 Kiri A"],
    ["Plot 4 Kiri B"]  = LAHAN_LIST["Plot 4 Kiri B"],
}

local currentLahanIndex = 1
for idx, name in ipairs(LAHAN_CATEGORIES) do
    if name == PlantConfig.DEFAULT_LAHAN then
        currentLahanIndex = idx
        break
    end
end

local function getActivePlots()
    local name = LAHAN_CATEGORIES[currentLahanIndex]
    return LAHAN_PRESETS[name] or {}
end

-- 2. Auto Clean Configuration
local CleanConfig = {
    TargetName = "kotoran",
    TargetMaterial = Enum.Material.Plastic,
    DefaultKosanID = "8833771934_19",
    DefaultRadius = 9999, -- Default Jarak Jauh (9999 studs untuk jangkauan global)
    DefaultLoop = 0.5,
    MinLoopInterval = 0.05,
}

local CleanState = {
    CurrentKosanID = CleanConfig.DefaultKosanID,
    KosanOwner = "",
    RoomNumber = "",
    Radius = CleanConfig.DefaultRadius,
    LoopInterval = CleanConfig.DefaultLoop,
    USE_TELEPORT = true -- Mode Jarak Jauh (Auto TP ke kotoran)
}

local function parseKosanID(idString)
    local parts = string.split(tostring(idString), "_")
    return parts[1] or "-", parts[2] or "-"
end
CleanState.KosanOwner, CleanState.RoomNumber = parseKosanID(CleanState.CurrentKosanID)

-- ========================================================
-- HELPER: SAFE TELEPORT (JARAK JAUH)
-- ========================================================
local function safeTeleport(targetPos: Vector3)
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if hum and hum.Sit then
        hum.Sit = false
    end

    if hrp then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    end
end

-- ========================================================
-- COMPAT LAYER (MULTI-EXECUTOR)
-- ========================================================
-- Menekan ProximityPrompt: pakai fireproximityprompt bila ada,
-- jika tidak ada pakai simulasi tahan tombol (InputHoldBegin/End)
local function firePrompt(prompt)
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true end
    end

    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait((prompt.HoldDuration or 0) + 0.05)
        prompt:InputHoldEnd()
    end)
    return ok
end

local function getExecutorName()
    if typeof(identifyexecutor) == "function" then
        local ok, name, version = pcall(identifyexecutor)
        if ok and name then
            return tostring(name) .. (version and (" " .. tostring(version)) or "")
        end
    end
    return "Unknown"
end

print(string.format("[IndoKost] Executor: %s | fireproximityprompt: %s | firesignal: %s | gethui: %s",
    getExecutorName(),
    typeof(fireproximityprompt) == "function" and "ya" or "fallback",
    typeof(firesignal) == "function" and "ya" or "fallback",
    typeof(gethui) == "function" and "ya" or "CoreGui/PlayerGui"))

-- ========================================================
-- NETWORK RESOLVERS
-- ========================================================
-- Knit Tanam Service
local function resolvePlantRemote(remoteName: string)
    local success, remote = pcall(function()
        return ReplicatedStorage
            :WaitForChild("NKSystem", 5)
            :WaitForChild("Packages", 5)
            :WaitForChild("Knit", 5)
            :WaitForChild("Services", 5)
            :WaitForChild("TanamService", 5)
            :WaitForChild("RF", 5)
            :WaitForChild(remoteName, 5)
    end)
    return if success then remote else nil
end

local beliBibitRF = resolvePlantRemote("BeliBibit")
local tanamRF = resolvePlantRemote("Tanam")

-- Kosan Clean Remote
local CleanEvent = nil
pcall(function()
    CleanEvent = ReplicatedStorage
        :WaitForChild("NKSystem", 5)
        :WaitForChild("Packages", 5)
        :WaitForChild("Knit", 5)
        :WaitForChild("Services", 5)
        :WaitForChild("KosanStateService", 5)
        :WaitForChild("RE", 5)
        :WaitForChild("CleanProgress", 5)
end)

local function fireCleanSignal(targetId)
    if not CleanEvent then return end
    if typeof(firesignal) == "function" then
        firesignal(CleanEvent.OnClientEvent, targetId, "Kotor", true)
    else
        pcall(function() CleanEvent:FireServer(targetId, "Kotor", true) end)
    end
end

local function findNearestDirt()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPos = char.HumanoidRootPart.Position

    local nearest, minDist = nil, CleanState.Radius
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower() == CleanConfig.TargetName:lower() then
            if obj.Material == CleanConfig.TargetMaterial then
                local dist = (obj.Position - rootPos).Magnitude
                if dist <= minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

-- ========================================================
-- AUTO SAMPAH (BAGIAN DARI AUTO CLEAN): AMBIL + BUANG
-- ========================================================
local TrashConfig = {
    -- Kata kunci (huruf kecil). Dicocokkan dengan nama/teks ProximityPrompt
    -- dan nama 3 parent di atasnya. Sesuaikan dengan nama objek di game.
    PickupKeywords  = { "sampah", "trash", "garbage", "litter" },
    DisposeKeywords = { "tong sampah", "tempat sampah", "trashcan", "trash can", "trash bin", "dustbin", "buang", "dispose" },
    CleanDoneStreak = 3, -- berapa kali cek berturut-turut tanpa kotoran sebelum cek persen kebersihan

    -- Tunggu kebersihan rumah 100% sebelum lanjut ke sampah
    RequireFullClean = true,
    CleanPercentKeywords = { "bersih", "clean", "kebersihan", "kotor" }, -- teks/nama UI persen kebersihan
    CleanPercentTimeout = 0, -- detik. 0 = tunggu 100% tanpa batas waktu; isi mis. 120 agar tidak macet

    -- Deteksi "penuh" (mode gabungan: ambil sampai penuh dulu, baru buang)
    MaxCarry = 5, -- kapasitas bawa sampah. SESUAIKAN dengan game
    FullKeywords = { "penuh", "inventory full", "backpack full", "bag full" },
    NoPromptLimit = 3,        -- berapa kali berturut-turut tidak ada target sebelum ganti fase
    DisposePhaseTimeout = 20, -- detik, batas maksimal fase buang sebelum balik ambil

    -- Kecepatan buang sampah (burst: 1x cari tong + 1x TP, lalu tembak berturut-turut)
    DisposeSettleDelay = 0.03,  -- jeda setelah TP ke tong sebelum mulai buang
    DisposeFireDelay = 0.04,    -- jeda antar buang sampah di tong yang sama
    DisposeLoopInterval = 0.1,  -- jeda antar loop selama fase BUANG (menggantikan LoopInterval)

    -- Buang hanya ke tong milik kosan sendiri
    OwnBinOnly = true,          -- true = hanya tong yang cocok dengan ID kosan / owner kita
    DisposeFallbackRadius = 150 -- studs. Bila tidak ada tong yang cocok owner, pakai tong terdekat
                                -- dari lokasi ambil sampah dalam radius ini. 0 = tanpa fallback
}

local TrashState = {
    Enabled = true,         -- ikut alur sampah setelah rumah bersih
    Phase = "BERSIH",       -- "BERSIH" > "TUNGGU" > "AMBIL" > "BUANG"
    PickupCount = 0,
    DisposeCount = 0,
    PickedSinceDispose = 0,
    DisposedThisPhase = 0,
    ToolDetected = false,   -- true bila sampah terdeteksi sebagai Tool di Backpack
    NoticeCached = false,
    HomePos = nil,          -- lokasi terakhir ambil sampah (jangkar kosan sendiri)
    LastBinLogged = nil
}

local onTrashUpdate = function() end -- diisi oleh GUI

local function hasKeyword(text, list)
    for _, kw in ipairs(list) do
        if string.find(text, kw, 1, true) then
            return true
        end
    end
    return false
end

local function promptSignature(prompt)
    local parts = { prompt.Name, prompt.ActionText, prompt.ObjectText }
    local inst = prompt.Parent
    for _ = 1, 3 do
        if not inst or inst == Workspace then break end
        table.insert(parts, inst.Name)
        inst = inst.Parent
    end
    return string.lower(table.concat(parts, " "))
end

local function promptPosition(prompt)
    local parent = prompt.Parent
    if not parent then return nil end
    if parent:IsA("BasePart") then
        return parent.Position
    elseif parent:IsA("Attachment") then
        return parent.WorldPosition
    elseif parent:IsA("Model") then
        local ok, pivot = pcall(function() return parent:GetPivot() end)
        if ok then return pivot.Position end
    end
    return nil
end

-- Token identitas kosan sendiri (huruf kecil, minimal 4 karakter agar tidak salah cocok)
local function ownerTokens()
    local tokens = {}
    local function add(v)
        v = string.lower(tostring(v or ""))
        if #v >= 4 and v ~= "-" then table.insert(tokens, v) end
    end
    add(CleanState.CurrentKosanID) -- UserID_RoomID lengkap
    add(CleanState.KosanOwner)     -- UserID pemilik
    add(LocalPlayer.UserId)
    add(LocalPlayer.Name)
    add(LocalPlayer.DisplayName)
    return tokens
end

-- Apakah objek (atau salah satu parent-nya sampai Workspace) milik kosan kita?
-- Dicek lewat nama dan Attribute (mis. Owner / UserId / KosanID).
local function isOwnedByMe(inst, tokens)
    local node = inst
    while node and node ~= Workspace and node ~= game do
        local lname = string.lower(node.Name)
        for _, tk in ipairs(tokens) do
            if string.find(lname, tk, 1, true) then return true end
        end

        local okAttr, attrs = pcall(function() return node:GetAttributes() end)
        if okAttr and attrs then
            for _, value in pairs(attrs) do
                local sv = string.lower(tostring(value))
                for _, tk in ipairs(tokens) do
                    if sv == tk or string.find(sv, tk, 1, true) then return true end
                end
            end
        end

        node = node.Parent
    end
    return false
end

local function logBinChoice(prompt, owned)
    if prompt == TrashState.LastBinLogged then return end
    TrashState.LastBinLogged = prompt
    if prompt then
        print(string.format("[IndoKost] Tong dipilih (%s): %s",
            owned and "cocok owner" or "fallback terdekat", prompt:GetFullName()))
    else
        warn("[IndoKost] Tidak ada tong milik kosan sendiri yang ditemukan (cek ID kosan / DisposeFallbackRadius)")
    end
end

local function findNearestTrashPrompt(isDispose)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local ownOnly = isDispose and TrashConfig.OwnBinOnly
    local tokens = ownOnly and ownerTokens() or nil
    local anchor = TrashState.HomePos or hrp.Position

    local best, bestDist = nil, math.huge   -- terdekat (atau terdekat milik sendiri)
    local fb, fbDist = nil, math.huge       -- cadangan: terdekat dari jangkar kosan

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local sig = promptSignature(obj)
            local isBin = hasKeyword(sig, TrashConfig.DisposeKeywords)
            local match
            if isDispose then
                match = isBin
            else
                -- Pick up: cocok "sampah" tapi BUKAN tempat sampah
                match = (not isBin) and hasKeyword(sig, TrashConfig.PickupKeywords)
            end

            if match then
                local pos = promptPosition(obj)
                if pos then
                    local dist = (pos - hrp.Position).Magnitude
                    if ownOnly then
                        if isOwnedByMe(obj, tokens) then
                            if dist < bestDist then
                                bestDist = dist
                                best = obj
                            end
                        elseif TrashConfig.DisposeFallbackRadius > 0 then
                            local d2 = (pos - anchor).Magnitude
                            if d2 <= TrashConfig.DisposeFallbackRadius and d2 < fbDist then
                                fbDist = d2
                                fb = obj
                            end
                        end
                    elseif dist < bestDist then
                        bestDist = dist
                        best = obj
                    end
                end
            end
        end
    end

    if ownOnly then
        local chosen = best or fb
        logBinChoice(chosen, best ~= nil)
        return chosen
    end
    return best
end

-- Hitung sampah yang sedang dibawa (Tool di Backpack / Character)
local function getCarriedTrash()
    local n = 0
    local function scan(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and hasKeyword(string.lower(item.Name), TrashConfig.PickupKeywords) then
                n += 1
            end
        end
    end
    scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
    scan(LocalPlayer.Character)
    return n
end

-- Cek notifikasi "penuh" yang tampil di layar
local function guiShown(obj)
    local inst = obj
    while inst and inst ~= PlayerGui do
        if inst.Name == "IndoKostUltraHub" then return false end
        if inst:IsA("GuiObject") and not inst.Visible then return false end
        if inst:IsA("ScreenGui") and not inst.Enabled then return false end
        inst = inst.Parent
    end
    return true
end

local lastNoticeScan = 0
local function fullNoticeVisible()
    if os.clock() - lastNoticeScan < 1 then
        return TrashState.NoticeCached
    end
    lastNoticeScan = os.clock()

    local found = false
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text ~= "" and obj.TextTransparency < 1 and guiShown(obj) then
            if hasKeyword(string.lower(obj.Text), TrashConfig.FullKeywords) then
                found = true
                break
            end
        end
    end
    TrashState.NoticeCached = found
    return found
end

local function isTrashFull()
    local carried = getCarriedTrash()
    if carried > 0 then TrashState.ToolDetected = true end

    -- 1) Jumlah sampah di tas mencapai kapasitas
    if carried >= TrashConfig.MaxCarry then return true end
    -- 2) Muncul notifikasi tas penuh di layar
    if fullNoticeVisible() then return true end
    -- 3) Cadangan (sampah bukan Tool): hitung jumlah pick up
    if not TrashState.ToolDetected and TrashState.PickedSinceDispose >= TrashConfig.MaxCarry then
        return true
    end
    return false
end

local function isTrashEmpty()
    if TrashState.DisposedThisPhase < 1 then return false end
    if TrashState.ToolDetected then
        return getCarriedTrash() == 0
    end
    local need = math.clamp(TrashState.PickedSinceDispose, 1, TrashConfig.MaxCarry)
    return TrashState.DisposedThisPhase >= need
end

-- Baca persen kebersihan rumah dari UI game (teks berisi angka + "%")
-- Return: angka 0-100, atau nil bila tidak ditemukan
local lastPctScan = 0
local cachedPct = nil
local function readCleanPercent()
    if os.clock() - lastPctScan < 0.5 then
        return cachedPct
    end
    lastPctScan = os.clock()

    local found = nil
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text ~= "" and guiShown(obj) then
            local text = string.lower(obj.Text)
            local num = string.match(text, "(%d+%.?%d*)%s*%%")
            if num then
                -- Cocokkan teks + nama objek & 3 parent dengan kata kunci kebersihan
                local parts = { text, obj.Name }
                local inst = obj.Parent
                for _ = 1, 3 do
                    if not inst or inst == PlayerGui then break end
                    table.insert(parts, string.lower(inst.Name))
                    inst = inst.Parent
                end
                if hasKeyword(table.concat(parts, " "), TrashConfig.CleanPercentKeywords) then
                    found = tonumber(num)
                    break
                end
            end
        end
    end

    cachedPct = found
    return found
end

-- Return: "noprompt" | "nofire" | "ok"
local function trashStep(isDispose)
    local prompt = findNearestTrashPrompt(isDispose)
    if not prompt then return "noprompt" end

    if CleanState.USE_TELEPORT then
        local pos = promptPosition(prompt)
        if pos then
            safeTeleport(pos)
            task.wait(0.06)
        end
    end

    local ok = pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 999999
        prompt.HoldDuration = 0
        if not firePrompt(prompt) then error("firePrompt gagal") end
    end)

    if not ok then return "nofire" end

    if isDispose then
        TrashState.DisposeCount += 1
        TrashState.DisposedThisPhase += 1
    else
        local hp = promptPosition(prompt)
        if hp then TrashState.HomePos = hp end
        TrashState.PickupCount += 1
        TrashState.PickedSinceDispose += 1
    end
    return "ok"
end

local isCleanRunning = false
local cleanThread = nil

-- Buang cepat: cari tong 1x, TP 1x, lalu buang semua sampah berturut-turut
-- Return: "noprompt" | "nofire" | "ok"
local function disposeBurst()
    local prompt = findNearestTrashPrompt(true)
    if not prompt then return "noprompt" end

    if CleanState.USE_TELEPORT then
        local pos = promptPosition(prompt)
        if pos then
            safeTeleport(pos)
            task.wait(TrashConfig.DisposeSettleDelay)
        end
    end

    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 999999
        prompt.HoldDuration = 0
    end)

    local shots
    if TrashState.ToolDetected then
        shots = math.max(getCarriedTrash(), 1)
    else
        shots = math.clamp(TrashState.PickedSinceDispose, 1, TrashConfig.MaxCarry)
    end

    local fired = 0
    for _ = 1, shots do
        if not isCleanRunning or not isScriptRunning then break end
        if not prompt.Parent or not prompt.Enabled then break end

        if not firePrompt(prompt) then break end
        fired += 1
        TrashState.DisposeCount += 1
        TrashState.DisposedThisPhase += 1

        if TrashState.ToolDetected and getCarriedTrash() == 0 then break end
        task.wait(TrashConfig.DisposeFireDelay)
    end

    return fired > 0 and "ok" or "nofire"
end

local function setCleanPhase(phase)
    local prev = TrashState.Phase
    TrashState.Phase = phase
    if phase == "BUANG" then
        TrashState.DisposedThisPhase = 0
    elseif phase == "BERSIH" and prev == "BUANG" then
        TrashState.PickedSinceDispose = 0
    end
    onTrashUpdate()
end

-- ========================================================
-- BACKGROUND WORKERS (DILENGKAPI JARAK JAUH)
-- ========================================================
local isPlantRunning = false
local plantThread = nil

local function executePlantCycle()
    local activePlots = getActivePlots()
    if #activePlots == 0 then return end

    -- Radius khusus Plot 4: hanya tanam plot yang berjarak <= PLOT4_RADIUS dari karakter
    local lahanName = LAHAN_CATEGORIES[currentLahanIndex] or ""
    -- (dilewati bila Auto TP aktif, karena karakter akan teleport ke plotnya sendiri)
    if not PlantConfig.USE_TELEPORT and string.sub(lahanName, 1, 6) == "Plot 4" then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local inRange = {}
            for _, plotPos in ipairs(activePlots) do
                if (plotPos - hrp.Position).Magnitude <= PlantConfig.PLOT4_RADIUS then
                    table.insert(inRange, plotPos)
                end
            end
            activePlots = inRange
        end

        if #activePlots == 0 then
            task.wait(1) -- tidak ada plot dalam radius, cek lagi sebentar
            return
        end
    end

    if beliBibitRF then
        local buySuccess, buyErr = pcall(function()
            return beliBibitRF:InvokeServer(PlantConfig.CROP_NAME, PlantConfig.BUY_COUNT)
        end)
        if not buySuccess then
            warn("[AutoFarm Error]: Beli bibit gagal:", buyErr)
        end
    end

    task.wait(PlantConfig.INTER_ACTION_DELAY)

    for index, plotPos in ipairs(activePlots) do
        if not isPlantRunning or not isScriptRunning then break end

        if PlantConfig.USE_TELEPORT then
            safeTeleport(plotPos)
            task.wait(PlantConfig.TP_SETTLE_DELAY)
            if not isPlantRunning or not isScriptRunning then break end
        end

        if tanamRF then
            local plantSuccess, plantErr = pcall(function()
                return tanamRF:InvokeServer(PlantConfig.CROP_NAME, plotPos)
            end)
            if not plantSuccess then
                warn(string.format("[AutoFarm Error]: Plot #%d gagal: %s", index, tostring(plantErr)))
            end
        end

        task.wait(PlantConfig.INTER_ACTION_DELAY)
    end
end

local function startPlantingLoop()
    plantThread = task.spawn(function()
        while isPlantRunning and isScriptRunning do
            executePlantCycle()
            task.wait(PlantConfig.CYCLE_COOLDOWN)
        end
    end)
end

local function stopPlantingLoop()
    isPlantRunning = false
    if plantThread then
        task.cancel(plantThread)
        plantThread = nil
    end
end

local function cleanDirtStep(target)
    -- Mode Jarak Jauh: Teleport ke dekat kotoran
    if CleanState.USE_TELEPORT then
        safeTeleport(target.Position)
        task.wait(0.06)
    end

    fireCleanSignal(CleanState.CurrentKosanID)

    -- Bypass jarak ProximityPrompt kotoran
    local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 999999
        prompt.HoldDuration = 0
        if prompt.Enabled then
            pcall(firePrompt, prompt)
        end
    end
end

-- Alur: BERSIH (kotoran) > TUNGGU (sampah muncul) > AMBIL (sampai penuh) > BUANG > BERSIH ...
local function startCleaningLoop()
    cleanThread = task.spawn(function()
        local noDirtStreak = 0
        local noPromptStreak = 0
        local disposeStart = 0
        local waitFullStart = nil

        setCleanPhase("BERSIH")

        while isCleanRunning and isScriptRunning do
            local phase = TrashState.Phase

            if not TrashState.Enabled then
                -- Mode sampah dimatikan: hanya bersihkan kotoran seperti biasa
                phase = "BERSIH"
                if TrashState.Phase ~= "BERSIH" then setCleanPhase("BERSIH") end
            end

            if phase == "BERSIH" then
                if TrashState.Enabled then
                    TrashState.CleanPercent = readCleanPercent()
                end

                local target = findNearestDirt()
                if target then
                    noDirtStreak = 0
                    waitFullStart = nil
                    cleanDirtStep(target)
                else
                    noDirtStreak += 1
                    if TrashState.Enabled and noDirtStreak >= TrashConfig.CleanDoneStreak then
                        -- Tidak ada kotoran: pastikan kebersihan sudah 100% dulu
                        local pct = TrashConfig.RequireFullClean and TrashState.CleanPercent or nil
                        local done = (pct == nil) or (pct >= 100)

                        if not done and TrashConfig.CleanPercentTimeout > 0 then
                            waitFullStart = waitFullStart or os.clock()
                            if os.clock() - waitFullStart >= TrashConfig.CleanPercentTimeout then
                                done = true
                            end
                        end

                        if done then
                            noDirtStreak = 0
                            waitFullStart = nil
                            -- Rumah 100% bersih -> tunggu sampah muncul
                            setCleanPhase("TUNGGU")
                        end
                    end
                end

            elseif phase == "TUNGGU" then
                if findNearestDirt() then
                    -- Ada kotoran baru: bersihkan dulu
                    setCleanPhase("BERSIH")
                elseif findNearestTrashPrompt(false) then
                    -- Sampah sudah muncul: mulai ambil
                    noPromptStreak = 0
                    setCleanPhase("AMBIL")
                end

            elseif phase == "AMBIL" then
                local result = trashStep(false)
                noPromptStreak = (result == "ok") and 0 or (noPromptStreak + 1)

                local full = isTrashFull()
                local noMore = noPromptStreak >= TrashConfig.NoPromptLimit
                local carrying = getCarriedTrash() > 0 or TrashState.PickedSinceDispose > 0

                if full or (noMore and carrying) then
                    -- Penuh (atau sampah habis tapi masih bawa) -> buang
                    noPromptStreak = 0
                    disposeStart = os.clock()
                    setCleanPhase("BUANG")
                elseif noMore then
                    -- Tidak ada sampah lagi dan tidak membawa apa-apa -> tunggu lagi
                    noPromptStreak = 0
                    setCleanPhase("TUNGGU")
                end

            elseif phase == "BUANG" then
                local result = disposeBurst()
                noPromptStreak = (result == "ok") and 0 or (noPromptStreak + 1)

                local timedOut = (os.clock() - disposeStart) >= TrashConfig.DisposePhaseTimeout
                local noBin = noPromptStreak >= TrashConfig.NoPromptLimit
                if isTrashEmpty() or timedOut or noBin then
                    noPromptStreak = 0
                    noDirtStreak = 0
                    setCleanPhase("BERSIH")
                end
            end

            onTrashUpdate()
            if TrashState.Phase == "BUANG" then
                task.wait(math.min(CleanState.LoopInterval, TrashConfig.DisposeLoopInterval))
            else
                task.wait(CleanState.LoopInterval)
            end
        end
    end)
end

local function stopCleaningLoop()
    isCleanRunning = false
    if cleanThread then
        task.cancel(cleanThread)
        cleanThread = nil
    end
    TrashState.Phase = "BERSIH"
    TrashState.PickedSinceDispose = 0
    TrashState.DisposedThisPhase = 0
    TrashState.CleanPercent = nil
    onTrashUpdate()
end

-- ========================================================
-- AUTO ACC PENYEWA
-- ========================================================
local TenantConfig = {
    Interval = 1,          -- detik antar permintaan terima penyewa
    SpinAt = 10,           -- spin gratis saat jumlah penyewa mencapai angka ini
    SpinPollInterval = 2,  -- detik antar pengecekan jumlah penyewa
    -- Kata kunci untuk mencari jumlah penyewa di UI / attribute (huruf kecil)
    TenantKeywords = { "penyewa", "tenant" }
}

local TenantState = {
    Running = false,
    CallCount = 0,
    AcceptCount = 0,
    SpinEnabled = false,
    SpinArmed = true,      -- siap spin; aktif lagi setelah jumlah penyewa turun di bawah SpinAt
    SpinBaseline = 0,      -- cadangan: jumlah penyewa diterima yang sudah dipakai untuk spin
    SpinCount = 0,
    DetectedTenants = nil, -- jumlah penyewa terdeteksi
    DetectSource = "-"
}

local tenantRF = nil
local tenantThread = nil
local onTenantUpdate = function() end -- diisi oleh GUI

local function getTenantRemote()
    if tenantRF and tenantRF.Parent then return tenantRF end
    pcall(function()
        tenantRF = ReplicatedStorage
            :WaitForChild("NKSystem", 5)
            :WaitForChild("Packages", 5)
            :WaitForChild("Knit", 5)
            :WaitForChild("Services", 5)
            :WaitForChild("PenyewaService", 5)
            :WaitForChild("RF", 5)
            :WaitForChild("Respond", 5)
    end)
    return tenantRF
end

local spinRF = nil
local function getSpinRemote()
    if spinRF and spinRF.Parent then return spinRF end
    pcall(function()
        spinRF = ReplicatedStorage
            :WaitForChild("NKSystem", 5)
            :WaitForChild("Packages", 5)
            :WaitForChild("Knit", 5)
            :WaitForChild("Services", 5)
            :WaitForChild("GachaService", 5)
            :WaitForChild("RF", 5)
            :WaitForChild("SpinX10WithFree", 5)
    end)
    return spinRF
end

-- Deteksi jumlah penyewa saat ini.
-- Return: jumlah (angka), sumber ("UI" / "Attr"), atau nil bila tidak ditemukan
local function readTenantCount()
    -- 1) UI: teks seperti "Penyewa: 10/10" atau "Penyewa 10"
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text ~= "" and guiShown(obj) then
            local text = string.lower(obj.Text)

            local parts = { text, string.lower(obj.Name) }
            local inst = obj.Parent
            for _ = 1, 3 do
                if not inst or inst == PlayerGui then break end
                table.insert(parts, string.lower(inst.Name))
                inst = inst.Parent
            end

            if hasKeyword(table.concat(parts, " "), TenantConfig.TenantKeywords) then
                -- Format "x/y" (mis. 10/10)
                local cur = string.match(text, "(%d+)%s*/%s*%d+")
                if cur then return tonumber(cur), "UI" end

                -- Format "penyewa: 10"
                for _, kw in ipairs(TenantConfig.TenantKeywords) do
                    local n = string.match(text, kw .. "%D*(%d+)")
                    if n then return tonumber(n), "UI" end
                end
            end
        end
    end

    -- 2) Attribute pemain
    local okAttr, attrs = pcall(function() return LocalPlayer:GetAttributes() end)
    if okAttr and attrs then
        for name, value in pairs(attrs) do
            if type(value) == "number" and hasKeyword(string.lower(name), TenantConfig.TenantKeywords) then
                return value, "Attr"
            end
        end
    end

    -- 3) leaderstats / Value di dalam pemain
    for _, child in ipairs(LocalPlayer:GetDescendants()) do
        if (child:IsA("NumberValue") or child:IsA("IntValue"))
            and hasKeyword(string.lower(child.Name), TenantConfig.TenantKeywords) then
            return child.Value, "Value"
        end
    end

    return nil, "-"
end

local spinRF = nil
local function getSpinRemote()
    if spinRF and spinRF.Parent then return spinRF end
    pcall(function()
        spinRF = ReplicatedStorage
            :WaitForChild("NKSystem", 5)
            :WaitForChild("Packages", 5)
            :WaitForChild("Knit", 5)
            :WaitForChild("Services", 5)
            :WaitForChild("GachaService", 5)
            :WaitForChild("RF", 5)
            :WaitForChild("SpinX10WithFree", 5)
    end)
    return spinRF
end

local function doSpin()
    local rf = getSpinRemote()
    if not rf then
        warn("[AutoSpin]: Remote GachaService.SpinX10WithFree tidak ditemukan")
        return false
    end

    local ok, result = pcall(function()
        return rf:InvokeServer()
    end)
    if ok then
        TenantState.SpinCount += 1
    else
        warn("[AutoSpin Error]:", result)
    end
    return ok
end

-- Watcher: spin gacha otomatis saat penyewa sudah 10
local spinWatcher = nil

local function startSpinWatcher()
    if spinWatcher then return end
    spinWatcher = task.spawn(function()
        while TenantState.SpinEnabled and isScriptRunning do
            local count, source = readTenantCount()
            TenantState.DetectedTenants = count
            TenantState.DetectSource = source

            if count ~= nil then
                if count >= TenantConfig.SpinAt then
                    if TenantState.SpinArmed then
                        TenantState.SpinArmed = false -- cegah spin berulang selama penyewa masih >= 10
                        doSpin()
                    end
                else
                    TenantState.SpinArmed = true -- penyewa turun: siap spin lagi saat mencapai 10
                end
            else
                -- Cadangan: jumlah penyewa tidak terbaca -> hitung dari yang diterima script
                if TenantState.AcceptCount - TenantState.SpinBaseline >= TenantConfig.SpinAt then
                    TenantState.SpinBaseline += TenantConfig.SpinAt
                    doSpin()
                end
            end

            onTenantUpdate()
            task.wait(TenantConfig.SpinPollInterval)
        end
        spinWatcher = nil
    end)
end

local function stopSpinWatcher()
    TenantState.SpinEnabled = false
    if spinWatcher then
        task.cancel(spinWatcher)
        spinWatcher = nil
    end
end

local function startTenantWorker()
    if tenantThread then return end
    tenantThread = task.spawn(function()
        while TenantState.Running and isScriptRunning do
            local rf = getTenantRemote()
            if rf then
                local ok, result = pcall(function()
                    return rf:InvokeServer(true) -- true = terima penyewa
                end)
                if ok then
                    TenantState.CallCount += 1
                    if result == true then
                        TenantState.AcceptCount += 1
                    end
                    onTenantUpdate()
                else
                    warn("[AutoAccPenyewa Error]:", result)
                end
            else
                warn("[AutoAccPenyewa]: Remote PenyewaService.Respond tidak ditemukan")
            end
            task.wait(TenantConfig.Interval)
        end
        tenantThread = nil
    end)
end

local function stopTenantWorker()
    TenantState.Running = false
    if tenantThread then
        task.cancel(tenantThread)
        tenantThread = nil
    end
end

-- ========================================================
-- ANTI-AFK (CEGAH KICK IDLE 20 MENIT)
-- ========================================================
local isAntiAfkRunning = false
local antiAfkConn = nil
local antiAfkThread = nil
local ANTI_AFK_INTERVAL = 55 -- detik, sinyal cadangan berkala

local function antiAfkPulse()
    local ok = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)

    if not ok then
        -- Cadangan bila VirtualUser tidak tersedia di executor
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 1, true, game, 0)
            task.wait(0.05)
            vim:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        end)
    end
end

local function startAntiAfk()
    if antiAfkConn then return end

    -- Respon saat Roblox mendeteksi karakter idle
    antiAfkConn = LocalPlayer.Idled:Connect(antiAfkPulse)

    -- Sinyal cadangan berkala
    antiAfkThread = task.spawn(function()
        while isAntiAfkRunning and isScriptRunning do
            task.wait(ANTI_AFK_INTERVAL)
            if not isAntiAfkRunning or not isScriptRunning then break end
            antiAfkPulse()
        end
    end)
end

local function stopAntiAfk()
    isAntiAfkRunning = false
    if antiAfkConn then
        antiAfkConn:Disconnect()
        antiAfkConn = nil
    end
    if antiAfkThread then
        task.cancel(antiAfkThread)
        antiAfkThread = nil
    end
end

-- Semua logika ternak/traktor/kotoran/rute dibungkus satu fungsi agar tidak
-- melebihi batas 200 variabel local di tingkat atas. Antarmuka lewat tabel TernakHub.
local TernakHub = (function()
    local cb = {
        traktor = function() end,
        dung = function() end,
        route = function() end,
        convert = function() end
    }
    local RunService = game:GetService("RunService")

    -- ========================================================
    -- AUTO SPAWN & MENGEMUDI TRAKTOR (TraktorService)
    -- Dua fitur terpisah: Auto Spawn dan Auto Mengemudi punya tombol ON/OFF masing-masing
    -- ========================================================
    local TraktorConfig = {
        VehicleType = "Traktor",  -- argumen pertama Spawn
        SpawnInterval = 5,        -- detik cek traktor sudah ada atau belum
        SpawnWaitTimeout = 5,     -- detik menunggu traktor muncul setelah Spawn
        DriveInterval = 3,        -- detik cek perlu mulai mengemudi atau tidak
        AutoBoard = true,         -- TP ke traktor lalu duduk di kursinya sebelum MulaiMengemudi
        BoardSettleDelay = 0.3,   -- jeda setelah TP / mencoba duduk sebelum dicek
        BoardRetries = 3          -- jumlah percobaan naik per traktor
    }

    local TraktorState = {
        SpawnRunning = false,
        DriveRunning = false,
        SpawnCount = 0,
        DriveCount = 0,
        LastDrivenModel = nil,   -- traktor terakhir yang sudah dikemudikan
        LastDrivenChar = nil     -- karakter saat itu (bila respawn, mengemudi diulang)
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

    -- Traktor milik sendiri: workspace.KendaraanTraktor.Traktor_<UserId>
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

    -- Pengaturan rute menyetir + nama model traktor yang dikemudikan
    local RouteConfig = {
        ModelName = "Traktor_Kotoran", -- nama/id model di workspace.KendaraanTraktor (nama persis, atau awalan + ID kita)
        -- Profil rute (satu aktif sekali waktu karena memakai traktor yang sama):
        Profiles = {
            { -- 1: rute awal, Kandang_1 .. Kandang_4
                Name = "Rute",
                KandangNames = { "Kandang_1", "Kandang_2", "Kandang_3", "Kandang_4" },
                KandangSelected = { true, true, true, true }, -- diubah lewat tombol di tab Ternak
                PlotKeywords = {}
            },
            { -- 2: rute Plot 8, Kandang_1 .. Kandang_8
                Name = "Plot 8",
                KandangNames = { "Kandang_1", "Kandang_2", "Kandang_3", "Kandang_4",
                                 "Kandang_5", "Kandang_6", "Kandang_7", "Kandang_8" },
                KandangSelected = { true, true, true, true, true, true, true, true },
                -- Bila nama Kandang_N sama di beberapa plot: utamakan yang berada di bawah objek
                -- bernama mengandung kata kunci ini (huruf kecil). Hanya preferensi, bukan syarat.
                PlotKeywords = { "plot 8", "plot_8", "plot8" }
            }
        },
        Speed = 25,             -- studs/detik
        TurnSpeed = 6,          -- kecepatan menghadap arah jalan (makin besar makin cepat)
        ArriveDistance = 4,     -- jarak (studs) dianggap sudah sampai di kandang
        DwellTime = 1.5,        -- detik berhenti di tiap kandang sebelum lanjut
        Loop = true,            -- true = ulangi terus (kandang terakhir -> pertama)
        StartAtNearest = true,  -- mulai dari kandang terpilih yang terdekat
        UseTargetY = false,     -- true = ikuti Y tujuan; false = pertahankan tinggi traktor sekarang
        HeightOffset = 0,       -- tambahan tinggi bila UseTargetY = true
        RequireSeated = true,   -- hanya gerak bila karakter duduk di traktor (agar posisi tersinkron ke server)
        AutoStartDrive = true   -- bila belum duduk, jalankan MulaiMengemudi otomatis (sekali per traktor)
    }

    -- Traktor yang dikemudikan: milik sendiri berawalan ModelName > nama persis ModelName > Traktor_<UserId>
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

    -- TP ke traktor yang di-spawn lalu duduk di kursinya.
    -- Return true bila sudah duduk (atau bila tidak ada kursi/prompt yang bisa dicek)
    local function boardTraktor(model)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return false end

        local function seated()
            return hum.SeatPart ~= nil and hum.SeatPart:IsDescendantOf(model)
        end
        if seated() then return true end -- sudah duduk, jangan TP (TP melepas dari kursi)

        local seat = model:FindFirstChildWhichIsA("VehicleSeat", true) or model:FindFirstChildWhichIsA("Seat", true)
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        local basePos = seat and seat.Position or model:GetPivot().Position

        if not seat and not prompt then
            -- Kursi/prompt tidak terdeteksi: cukup TP ke traktor, sisanya ditangani MulaiMengemudi
            safeTeleport(basePos)
            task.wait(TraktorConfig.BoardSettleDelay)
            return true
        end

        for _ = 1, TraktorConfig.BoardRetries do
            if not isScriptRunning then return false end

            safeTeleport(basePos)
            task.wait(TraktorConfig.BoardSettleDelay)

            if seat then
                pcall(function() seat:Sit(hum) end) -- bila API tersedia di executor/game
                pcall(function() hrp.CFrame = seat.CFrame * CFrame.new(0, 2, 0) end) -- menyentuh kursi -> duduk otomatis
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

    -- Naik traktor (bila AutoBoard) lalu mulai mengemudi
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
                -- Mengemudi sekali per traktor / per karakter (hindari memicu event berulang)
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


    -- ========================================================
    -- MASUKKAN KOTORAN KE MESIN CONVERT (ConvertService.Masukkan)
    -- Dipanggil hanya saat memakai traktor. Tombol ON/OFF terpisah.
    -- ========================================================
    local ConvertConfig = {
        Interval = 3,            -- detik antar pemanggilan Masukkan
        MinGap = 0.5,            -- jeda minimum antar pemanggilan (agar pemicu dari rute tidak menumpuk)
        TriggerDelay = 0.3,      -- detik setelah traktor mencapai kotoran sebelum Masukkan dipicu
        OnlyWhenDriving = true   -- true = hanya saat duduk di traktor
    }

    local ConvertState = {
        Running = false,
        Count = 0,               -- jumlah Masukkan yang berhasil
        Fail = 0,                -- jumlah yang ditolak/gagal
        Last = 0,
        Busy = false,
        LastSuccess = nil        -- untuk log saat hasil berubah
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

    -- Sedang memakai traktor milik sendiri (duduk di kursinya)
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

    -- Masukkan kotoran ke mesin convert. Return true bila server menganggap berhasil
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

        -- Format jawaban belum diketahui: anggap berhasil bila ada jawaban selain nil/false
        -- dan (bila berupa tabel) field ok tidak bernilai false
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
    -- DETEKSI KOTORAN KAMBING (SAAT MEMAKAI TRAKTOR)
    -- Target: objek bernama "Kotoran_Kambing__Kotoran"
    -- Kotoran yang terdeteksi didatangi lebih dulu oleh Setir Rute (bila aktif)
    -- ========================================================
    local DungConfig = {
        TargetName = "Kotoran_Kambing__Kotoran",
        FuzzyPrefix = "kotoran_kambing", -- cadangan bila nama persis tidak ada (mis. ada angka/ID tambahan). "" = nonaktif
        DetectInterval = 1,   -- detik antar pemindaian
        ArriveDistance = 4,   -- jarak (studs) traktor dianggap sudah sampai di kotoran
        RetryCooldown = 4,    -- detik sebelum kotoran yang sama dianggap lagi
        RequireOwned = false, -- true = hanya kotoran milik kosan sendiri
        OnlyWhenDriving = true -- true = mendeteksi hanya saat sedang memakai traktor
    }

    local DungState = {
        Running = false,
        Detected = 0,         -- jumlah kotoran terdeteksi saat ini
        Collected = 0,        -- jumlah kotoran yang sudah didatangi traktor
        Target = nil,         -- kotoran yang sedang dituju
        LastLogged = nil,
        Recent = {}
    }

    local dungThread = nil

    -- Posisi umum sebuah objek (Part / Model / Attachment / Prompt / Folder)
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

    -- Pindai kotoran: milik sendiri > nama persis > terdekat dari posisi traktor
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
                local quality = 0
                if lname == exactName then
                    quality = 2
                elseif prefix and string.find(lname, prefix, 1, true) == 1 then
                    quality = 1
                end

                if quality > 0 then
                    local recent = DungState.Recent[obj]
                    if not (recent and now - recent < DungConfig.RetryCooldown) then
                        local pos = objPosition(obj)
                        if pos then
                            local owned = isOwnedByMe(obj, tokens)
                            if owned or not DungConfig.RequireOwned then
                                count += 1
                                local dist = (pos - fromPos).Magnitude
                                local better
                                if owned ~= bestOwned then
                                    better = owned
                                elseif quality ~= bestQuality then
                                    better = quality > bestQuality
                                else
                                    better = dist < bestDist
                                end
                                if not best or better then
                                    best, bestOwned, bestQuality, bestDist = obj, owned, quality, dist
                                end
                            end
                        end
                    end
                end
            end
        end

        return best, count, bestOwned
    end

    local function startDungWorker()
        if dungThread then return end
        dungThread = task.spawn(function()
            while DungState.Running and isScriptRunning do
                local model = findDriveTraktor()
                local driving = model ~= nil and (isSeatedIn(model) or not RouteConfig.RequireSeated)

                if driving or not DungConfig.OnlyWhenDriving then
                    local fromPos = nil
                    if model then
                        fromPos = model:GetPivot().Position
                    else
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        fromPos = hrp and hrp.Position
                    end

                    if fromPos then
                        local best, count, owned = scanDung(fromPos)
                        DungState.Detected = count

                        -- Pertahankan target yang sedang dituju agar tidak berpindah-pindah
                        local cur = DungState.Target
                        if not (cur and cur.Parent) then
                            DungState.Target = best
                            if best and DungState.LastLogged ~= best then
                                DungState.LastLogged = best
                                print(string.format("[Kotoran Kambing] Terdeteksi (%s): %s",
                                    owned and "cocok owner" or "terdekat", best:GetFullName()))
                            end
                        end
                    end
                else
                    DungState.Target = nil
                    DungState.Detected = 0
                end

                cb.dung()
                task.wait(DungConfig.DetectInterval)
            end
            dungThread = nil
        end)
    end

    local function stopDungWorker()
        DungState.Running = false
        if dungThread then
            task.cancel(dungThread)
            dungThread = nil
        end
        DungState.Target = nil
        DungState.Detected = 0
        table.clear(DungState.Recent)
    end

    -- ========================================================
    -- AUTO SETIR TRAKTOR KE KANDANG (PILIHAN Kandang_1 .. Kandang_4)
    -- Prioritas: kotoran terdeteksi > kandang terpilih (berurutan)
    -- ========================================================
    local RouteState = {
        Running = false,
        Profile = 1,            -- indeks profil rute yang aktif (RouteConfig.Profiles)
        KIndex = 1,
        Laps = 0,
        Finished = false,
        NeedInit = true,
        KandangName = nil,
        KandangPos = nil,
        WarnedEmpty = false,
        Logged = {}
    }

    local routeThread = nil

    local function selectedKandangNames()
        local list = {}
        local prof = RouteConfig.Profiles[RouteState.Profile]
        if not prof then return list end
        for i, name in ipairs(prof.KandangNames) do
            if prof.KandangSelected[i] then
                table.insert(list, name)
            end
        end
        return list
    end

    -- Apakah salah satu parent objek bernama mengandung kata kunci plot (mis. "plot 8")?
    local function matchesPlot(obj, keywords)
        if not keywords or #keywords == 0 then return false end
        local node = obj.Parent
        while node and node ~= Workspace and node ~= game do
            local lname = string.lower(node.Name)
            for _, kw in ipairs(keywords) do
                if string.find(lname, kw, 1, true) then return true end
            end
            node = node.Parent
        end
        return false
    end

    -- Cari kandang bernama persis (mis. "Kandang_1"): milik sendiri > cocok kata kunci plot > terdekat
    local function findKandangPos(name, fromPos)
        local lname = string.lower(name)
        local tokens = ownerTokens()
        local prof = RouteConfig.Profiles[RouteState.Profile]
        local keywords = prof and prof.PlotKeywords or nil
        local bestPos, bestObj, bestScore, bestDist, bestOwned = nil, nil, -1, math.huge, false

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if string.lower(obj.Name) == lname and (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Folder")) then
                local pos = objPosition(obj)
                if pos then
                    local owned = isOwnedByMe(obj, tokens)
                    local score = (owned and 2 or 0) + (matchesPlot(obj, keywords) and 1 or 0)
                    local dist = (pos - fromPos).Magnitude
                    if score > bestScore or (score == bestScore and dist < bestDist) then
                        bestPos, bestObj, bestScore, bestDist, bestOwned = pos, obj, score, dist, owned
                    end
                end
            end
        end

        local logKey = tostring(RouteState.Profile) .. ":" .. name
        if bestObj and RouteState.Logged[logKey] ~= bestObj then
            RouteState.Logged[logKey] = bestObj
            print(string.format("[Rute Traktor] %s (%s): %s", name,
                bestOwned and "cocok owner" or "terdekat", bestObj:GetFullName()))
        end
        return bestPos
    end

    -- Satu langkah gerak menuju target. Return true bila sudah sampai.
    local function stepToward(model, dt, target, arriveDist)
        local pivot = model:GetPivot()
        local pos = pivot.Position
        local goalY = RouteConfig.UseTargetY and (target.Y + RouteConfig.HeightOffset) or pos.Y
        local goal = Vector3.new(target.X, goalY, target.Z)

        local delta = goal - pos
        local flat = Vector3.new(delta.X, 0, delta.Z)
        local dist = RouteConfig.UseTargetY and delta.Magnitude or flat.Magnitude
        if dist <= arriveDist then
            return true
        end

        local stepLen = math.min(RouteConfig.Speed * dt, delta.Magnitude)
        local newPos = pos + delta.Unit * stepLen

        local rot = pivot.Rotation
        if flat.Magnitude > 0.1 then
            local targetRot = CFrame.lookAt(Vector3.zero, flat.Unit, Vector3.yAxis)
            rot = rot:Lerp(targetRot, math.clamp(dt * RouteConfig.TurnSpeed, 0, 1))
        end

        model:PivotTo(CFrame.new(newPos) * rot)

        local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        return false
    end

    local function routeTick(model)
        local pos = model:GetPivot().Position

        -- Prioritas 1: kotoran yang terdeteksi
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
                        cb.dung()
                        if ConvertState.Running then
                            task.delay(ConvertConfig.TriggerDelay, convertNow)
                        end
                    end
                    return
                end
            end
            DungState.Target = nil
        end

        -- Prioritas 2: kandang terpilih secara berurutan
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
            RouteState.KIndex = 1
            RouteState.KandangPos = nil
            if RouteConfig.StartAtNearest then
                local bestI, bestD = 1, math.huge
                for i, name in ipairs(list) do
                    local p = findKandangPos(name, pos)
                    if p then
                        local d = (p - pos).Magnitude
                        if d < bestD then
                            bestI, bestD = i, d
                        end
                    end
                end
                RouteState.KIndex = bestI
            end
        end

        if RouteState.KIndex > #list then RouteState.KIndex = 1 end
        local name = list[RouteState.KIndex]

        if not RouteState.KandangPos or RouteState.KandangName ~= name then
            RouteState.KandangName = name
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
            local warnedSeat = false

            while RouteState.Running and isScriptRunning do
                local model = findDriveTraktor()
                local char = LocalPlayer.Character

                if not model or not char then
                    task.wait(1)
                else
                    -- Belum mengemudi: mulai otomatis sekali per traktor/karakter
                    if RouteConfig.AutoStartDrive and (model ~= TraktorState.LastDrivenModel or char ~= TraktorState.LastDrivenChar) then
                        if startDriving(model) then
                            TraktorState.LastDrivenModel = model
                            TraktorState.LastDrivenChar = char
                            cb.traktor()
                            task.wait(1)
                        end
                    end

                    if RouteConfig.RequireSeated and not isSeatedIn(model) then
                        if not warnedSeat then
                            warnedSeat = true
                            warn("[Rute Traktor] Karakter belum duduk di traktor. Nyalakan Auto Mengemudi / duduk manual, atau set RouteConfig.RequireSeated = false")
                        end
                        task.wait(1)
                    elseif RouteState.Finished then
                        task.wait(0.5)
                    else
                        warnedSeat = false
                        routeTick(model)
                    end
                end
            end
            routeThread = nil
        end)
    end

    local function stopRouteWorker()
        RouteState.Running = false
        if routeThread then
            task.cancel(routeThread)
            routeThread = nil
        end
    end

    -- Nyalakan rute profil idx (mematikan profil lain), atau matikan bila profil itu sudah aktif
    -- Return: indeks profil yang aktif, atau nil bila rute mati
    local function toggleRouteProfile(idx)
        if RouteState.Running and RouteState.Profile == idx then
            stopRouteWorker()
            return nil
        end
        RouteState.Profile = idx
        RouteState.KIndex = 1
        RouteState.KandangPos = nil
        RouteState.KandangName = nil
        RouteState.Finished = false
        RouteState.NeedInit = true
        RouteState.WarnedEmpty = false
        RouteState.Laps = 0
        RouteState.Running = true
        startRouteWorker()
        return idx
    end

    return {
        cb = cb,
        ConvertState = ConvertState,
        startConvertWorker = startConvertWorker, stopConvertWorker = stopConvertWorker,
        TraktorState = TraktorState,
        startTraktorSpawnWorker = startTraktorSpawnWorker, stopTraktorSpawnWorker = stopTraktorSpawnWorker,
        startTraktorDriveWorker = startTraktorDriveWorker, stopTraktorDriveWorker = stopTraktorDriveWorker,
        DungConfig = DungConfig, DungState = DungState,
        startDungWorker = startDungWorker, stopDungWorker = stopDungWorker,
        RouteConfig = RouteConfig, RouteState = RouteState,
        startRouteWorker = startRouteWorker, stopRouteWorker = stopRouteWorker,
        toggleRouteProfile = toggleRouteProfile,
        stopAll = function()
            pcall(stopTraktorSpawnWorker)
            pcall(stopTraktorDriveWorker)
            pcall(stopConvertWorker)
            pcall(stopDungWorker)
            pcall(stopRouteWorker)
        end
    }
end)()

-- ========================================================
-- AUTO GACHA PAKAI UANG (GachaService.SpinX10WithMoney)
-- Dibungkus satu fungsi agar tidak menambah variabel local di tingkat atas.
-- ========================================================
local GachaHub = (function()
    local GachaConfig = {
        Interval = 1.5,        -- detik antar spin x10
        MaxSpins = 0,          -- batas jumlah spin x10 per sesi (0 = tanpa batas)
        StopAfterFails = 3,    -- berhenti otomatis setelah N gagal berturut-turut (mis. uang habis)
        LogEveryResult = true  -- cetak ringkasan hasil tiap spin ke console
    }

    local GachaState = {
        Running = false,
        Spins = 0,             -- jumlah spin x10 yang berhasil (total)
        Fails = 0,             -- jumlah yang ditolak/gagal
        SessionSpins = 0,      -- spin berhasil sejak tombol START ditekan
        FailStreak = 0,        -- gagal berturut-turut
        Busy = false,
        LastSuccess = nil
    }

    local cb = { gacha = function() end } -- diisi oleh GUI
    local gachaThread = nil
    local gachaRF = nil

    local function getGachaRemote()
        if gachaRF and gachaRF.Parent then return gachaRF end
        pcall(function()
            gachaRF = ReplicatedStorage
                :WaitForChild("NKSystem", 5)
                :WaitForChild("Packages", 5)
                :WaitForChild("Knit", 5)
                :WaitForChild("Services", 5)
                :WaitForChild("GachaService", 5)
                :WaitForChild("RF", 5)
                :WaitForChild("SpinX10WithMoney", 5)
        end)
        return gachaRF
    end

    local function summarize(value, depth)
        depth = depth or 0
        if type(value) ~= "table" then return tostring(value) end
        if depth >= 2 then return "{...}" end
        local parts, n = {}, 0
        for k, v in pairs(value) do
            n += 1
            if n > 8 then
                table.insert(parts, "...")
                break
            end
            table.insert(parts, tostring(k) .. "=" .. summarize(v, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    -- Satu spin x10 pakai uang. Return true bila server menganggap berhasil
    local function spinOnce()
        if GachaState.Busy then return false end

        local rf = getGachaRemote()
        if not rf then
            warn("[Gacha] Remote GachaService.SpinX10WithMoney tidak ditemukan")
            return false
        end

        GachaState.Busy = true
        local okCall, result = pcall(function()
            return rf:InvokeServer()
        end)
        GachaState.Busy = false

        -- Format jawaban belum diketahui: berhasil bila ada jawaban selain nil/false dan
        -- (bila tabel) field ok / success tidak bernilai false
        local success = okCall and result ~= nil and result ~= false
        if success and type(result) == "table" and (result.ok == false or result.success == false) then
            success = false
        end

        if success then
            GachaState.Spins += 1
            GachaState.SessionSpins += 1
            GachaState.FailStreak = 0
        else
            GachaState.Fails += 1
            GachaState.FailStreak += 1
        end

        if GachaConfig.LogEveryResult or GachaState.LastSuccess ~= success then
            local text = okCall and summarize(result) or tostring(result)
            if #text > 240 then text = string.sub(text, 1, 240) .. "..." end
            if success then
                print("[Gacha] Spin x10 OK | " .. text)
            else
                warn("[Gacha] Spin x10 ditolak/gagal | " .. text)
            end
        end
        GachaState.LastSuccess = success

        cb.gacha()
        return success
    end

    local function startGachaWorker()
        if gachaThread then return end
        GachaState.SessionSpins = 0
        GachaState.FailStreak = 0

        gachaThread = task.spawn(function()
            while GachaState.Running and isScriptRunning do
                spinOnce()

                if GachaState.FailStreak >= GachaConfig.StopAfterFails then
                    warn("[Gacha] Berhenti otomatis: gagal berturut-turut (uang tidak cukup?)")
                    GachaState.Running = false
                    break
                end
                if GachaConfig.MaxSpins > 0 and GachaState.SessionSpins >= GachaConfig.MaxSpins then
                    print("[Gacha] Batas spin tercapai: " .. GachaState.SessionSpins .. " x10")
                    GachaState.Running = false
                    break
                end

                task.wait(GachaConfig.Interval)
            end
            gachaThread = nil
            cb.gacha() -- segarkan tampilan (bisa saja berhenti otomatis)
        end)
    end

    local function stopGachaWorker()
        GachaState.Running = false
        if gachaThread then
            task.cancel(gachaThread)
            gachaThread = nil
        end
        cb.gacha()
    end

    return {
        cb = cb,
        GachaConfig = GachaConfig, GachaState = GachaState,
        spinOnce = spinOnce,
        startGachaWorker = startGachaWorker, stopGachaWorker = stopGachaWorker,
        stopAll = stopGachaWorker
    }
end)()

-- ========================================================
-- HIGH-END CYBER GUI DESIGN (SMITH GANTENG)
-- ========================================================
-- Ukuran GUI sedang (menyesuaikan layar, tidak lebih kecil dari 340x445)
local viewport = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
local WIN_WIDTH = math.clamp(400, 340, math.max(340, viewport.X - 20))
local WIN_HEIGHT = math.clamp(500, 445, math.max(445, viewport.Y - 40))
local MINI_HEIGHT = 46

local TWEEN_SMOOTH = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_FAST   = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Matikan instance lama bila script dijalankan ulang
do
    local genv = (typeof(getgenv) == "function" and getgenv()) or _G
    if genv.__IndoKostShutdown then
        pcall(genv.__IndoKostShutdown)
        genv.__IndoKostShutdown = nil
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IndoKostUltraHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Pasang GUI: gethui > CoreGui > PlayerGui (otomatis pilih yang tersedia)
do
    if syn and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, ScreenGui)
    end

    local mounted = false

    if typeof(gethui) == "function" then
        local okHui, hui = pcall(gethui)
        if okHui and hui then
            pcall(function() ScreenGui.Parent = hui end)
            mounted = ScreenGui.Parent ~= nil
        end
    end

    if not mounted and CoreGui then
        pcall(function() ScreenGui.Parent = CoreGui end)
        mounted = ScreenGui.Parent ~= nil
    end

    if not mounted then
        ScreenGui.Parent = PlayerGui
    end
end

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, WIN_WIDTH, 0, WIN_HEIGHT)
MainFrame.Position = UDim2.new(0.5, -WIN_WIDTH / 2, 0.18, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(48, 52, 74)
MainStroke.Thickness = 1.4

local MainGradient = Instance.new("UIGradient", MainFrame)
MainGradient.Rotation = 45
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(18, 20, 29)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(11, 13, 19))
})

-- ========================================================
-- HEADER BAR
-- ========================================================
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, MINI_HEIGHT)
Header.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 14)

local HeaderStroke = Instance.new("UIStroke", Header)
HeaderStroke.Color = Color3.fromRGB(38, 42, 60)
HeaderStroke.Thickness = 1

-- Logo Icon Box
local LogoBox = Instance.new("Frame")
LogoBox.Size = UDim2.new(0, 28, 0, 28)
LogoBox.Position = UDim2.new(0, 12, 0.5, -14)
LogoBox.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
LogoBox.BorderSizePixel = 0
LogoBox.Parent = Header
Instance.new("UICorner", LogoBox).CornerRadius = UDim.new(0, 7)

local LogoGrad = Instance.new("UIGradient", LogoBox)
LogoGrad.Rotation = 45
LogoGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246))
})

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Font = Enum.Font.GothamBold
LogoText.Text = "⚡"
LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
LogoText.TextSize = 14
LogoText.Parent = LogoBox

-- Title & Creator Subtitle (Smith Ganteng)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -160, 0, 18)
TitleLabel.Position = UDim2.new(0, 48, 0, 7)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.Text = "INDO-KOST HUB"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(1, -160, 0, 14)
SubTitleLabel.Position = UDim2.new(0, 48, 0, 25)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Font = Enum.Font.GothamBold
SubTitleLabel.Text = "👑 SMITH GANTENG"
SubTitleLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
SubTitleLabel.TextSize = 9
SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLabel.Parent = Header

-- Control Buttons (Minimize & Close)
local HeaderControls = Instance.new("Frame")
HeaderControls.Size = UDim2.new(0, 68, 1, 0)
HeaderControls.Position = UDim2.new(1, -74, 0, 0)
HeaderControls.BackgroundTransparency = 1
HeaderControls.Parent = Header

local ControlsLayout = Instance.new("UIListLayout", HeaderControls)
ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ControlsLayout.Padding = UDim.new(0, 6)

local function createHeaderIconBtn(symbol, bgHover, txtColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(29, 32, 46)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = symbol
    btn.TextColor3 = txtColor or Color3.fromRGB(180, 185, 205)
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = HeaderControls
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local st = Instance.new("UIStroke", btn)
    st.Color = Color3.fromRGB(45, 48, 68)
    st.Thickness = 1

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = bgHover }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(29, 32, 46) }):Play()
    end)

    return btn
end

local MiniBtn = createHeaderIconBtn("—", Color3.fromRGB(48, 52, 75))
local CloseBtn = createHeaderIconBtn("✕", Color3.fromRGB(225, 29, 72), Color3.fromRGB(255, 120, 140))

-- ========================================================
-- TAB BAR (PILL SEGMENTED CONTROLS)
-- ========================================================
-- Bagian UI di bawah dibungkus satu fungsi agar variabelnya tidak menumpuk di fungsi utama
-- (batas Lua/Luau: 200 variabel local per fungsi, dan sebagian executor menambah local sendiri).
local _ = (function()
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -24, 0, 36)
TabBar.Position = UDim2.new(0, 12, 0, MINI_HEIGHT + 8)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)
local tabStroke = Instance.new("UIStroke", TabBar)
tabStroke.Color = Color3.fromRGB(36, 40, 58)
tabStroke.Thickness = 1

local TabListLayout = Instance.new("UIListLayout", TabBar)
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabListLayout.Padding = UDim.new(0, 6)

local function createTabPill(title)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / 6, -6, 1, -6)
    btn.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = title
    btn.TextColor3 = Color3.fromRGB(130, 135, 155)
    btn.TextSize = 10
    btn.TextScaled = true
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    local sizeLimit = Instance.new("UITextSizeConstraint", btn)
    sizeLimit.MaxTextSize = 10
    sizeLimit.MinTextSize = 6
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local TabPlantBtn = createTabPill("🌱 PLANT")
local TabCleanBtn = createTabPill("🧹 CLEAN")
local TabTenantBtn = createTabPill("🏠 SEWA")
local TabAfkBtn   = createTabPill("🛡️ AFK")
local TabTernakBtn = createTabPill("🐑 TERNAK")

-- ========================================================
-- CONTENT CONTAINER
-- ========================================================
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -24, 1, -(MINI_HEIGHT + 80))
ContentFrame.Position = UDim2.new(0, 12, 0, MINI_HEIGHT + 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local function createModernCard(parent, height, posY)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(21, 23, 33)
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(36, 40, 58)
    stroke.Thickness = 1
    return card
end

-- ========================================================
-- TAB 1: AUTO PLANT PAGE
-- ========================================================
local PlantPage = Instance.new("Frame")
PlantPage.Name = "PlantPage"
PlantPage.Size = UDim2.new(1, 0, 1, 0)
PlantPage.BackgroundTransparency = 1
PlantPage.Visible = true
PlantPage.Parent = ContentFrame

-- Card 1: Target Bibit & Live Status
local PlantStatusCard = createModernCard(PlantPage, 48, 0)

local PlantCardIcon = Instance.new("TextLabel")
PlantCardIcon.Size = UDim2.new(0, 24, 0, 24)
PlantCardIcon.Position = UDim2.new(0, 12, 0.5, -12)
PlantCardIcon.BackgroundTransparency = 1
PlantCardIcon.Font = Enum.Font.GothamBold
PlantCardIcon.Text = "🌶️"
PlantCardIcon.TextSize = 16
PlantCardIcon.Parent = PlantStatusCard

local PlantTargetLabel = Instance.new("TextLabel")
PlantTargetLabel.Size = UDim2.new(1, -120, 0, 16)
PlantTargetLabel.Position = UDim2.new(0, 42, 0, 8)
PlantTargetLabel.BackgroundTransparency = 1
PlantTargetLabel.Font = Enum.Font.GothamBold
PlantTargetLabel.Text = "Tanaman: " .. PlantConfig.CROP_NAME
PlantTargetLabel.TextColor3 = Color3.fromRGB(240, 240, 250)
PlantTargetLabel.TextSize = 11
PlantTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
PlantTargetLabel.Parent = PlantStatusCard

local PlantSubStatus = Instance.new("TextLabel")
PlantSubStatus.Size = UDim2.new(1, -120, 0, 14)
PlantSubStatus.Position = UDim2.new(0, 42, 0, 25)
PlantSubStatus.BackgroundTransparency = 1
PlantSubStatus.Font = Enum.Font.Gotham
PlantSubStatus.Text = "Status: Siap Beroperasi"
PlantSubStatus.TextColor3 = Color3.fromRGB(140, 145, 165)
PlantSubStatus.TextSize = 10
PlantSubStatus.TextXAlignment = Enum.TextXAlignment.Left
PlantSubStatus.Parent = PlantStatusCard

local PlantStatusBadge = Instance.new("Frame")
PlantStatusBadge.Size = UDim2.new(0, 68, 0, 22)
PlantStatusBadge.Position = UDim2.new(1, -78, 0.5, -11)
PlantStatusBadge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
PlantStatusBadge.BorderSizePixel = 0
PlantStatusBadge.Parent = PlantStatusCard
Instance.new("UICorner", PlantStatusBadge).CornerRadius = UDim.new(0, 6)

local PlantBadgeText = Instance.new("TextLabel")
PlantBadgeText.Size = UDim2.new(1, 0, 1, 0)
PlantBadgeText.BackgroundTransparency = 1
PlantBadgeText.Font = Enum.Font.GothamBold
PlantBadgeText.Text = "● IDLE"
PlantBadgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
PlantBadgeText.TextSize = 9
PlantBadgeText.Parent = PlantStatusBadge

-- Card 2: Lahan Selector (Interactive Stepper)
local LahanCard = createModernCard(PlantPage, 84, 54)

local LahanCardTitle = Instance.new("TextLabel")
LahanCardTitle.Size = UDim2.new(1, -24, 0, 16)
LahanCardTitle.Position = UDim2.new(0, 12, 0, 8)
LahanCardTitle.BackgroundTransparency = 1
LahanCardTitle.Font = Enum.Font.GothamBold
LahanCardTitle.Text = "LOKASI LAHAN AKTIF"
LahanCardTitle.TextColor3 = Color3.fromRGB(99, 102, 241)
LahanCardTitle.TextSize = 9
LahanCardTitle.TextXAlignment = Enum.TextXAlignment.Left
LahanCardTitle.Parent = LahanCard

local LahanStepperBox = Instance.new("Frame")
LahanStepperBox.Size = UDim2.new(1, -24, 0, 34)
LahanStepperBox.Position = UDim2.new(0, 12, 0, 26)
LahanStepperBox.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
LahanStepperBox.BorderSizePixel = 0
LahanStepperBox.Parent = LahanCard
Instance.new("UICorner", LahanStepperBox).CornerRadius = UDim.new(0, 6)
local stpStroke = Instance.new("UIStroke", LahanStepperBox)
stpStroke.Color = Color3.fromRGB(42, 46, 66)
stpStroke.Thickness = 1

local PrevLahanBtn = Instance.new("TextButton")
PrevLahanBtn.Size = UDim2.new(0, 32, 1, 0)
PrevLahanBtn.Position = UDim2.new(0, 0, 0, 0)
PrevLahanBtn.BackgroundTransparency = 1
PrevLahanBtn.Font = Enum.Font.GothamBold
PrevLahanBtn.Text = "◀"
PrevLahanBtn.TextColor3 = Color3.fromRGB(180, 185, 210)
PrevLahanBtn.TextSize = 11
PrevLahanBtn.AutoButtonColor = false
PrevLahanBtn.Parent = LahanStepperBox

local NextLahanBtn = Instance.new("TextButton")
NextLahanBtn.Size = UDim2.new(0, 32, 1, 0)
NextLahanBtn.Position = UDim2.new(1, -32, 0, 0)
NextLahanBtn.BackgroundTransparency = 1
NextLahanBtn.Font = Enum.Font.GothamBold
NextLahanBtn.Text = "▶"
NextLahanBtn.TextColor3 = Color3.fromRGB(180, 185, 210)
NextLahanBtn.TextSize = 11
NextLahanBtn.AutoButtonColor = false
NextLahanBtn.Parent = LahanStepperBox

local LahanDisplayBtn = Instance.new("TextButton")
LahanDisplayBtn.Size = UDim2.new(1, -64, 1, 0)
LahanDisplayBtn.Position = UDim2.new(0, 32, 0, 0)
LahanDisplayBtn.BackgroundTransparency = 1
LahanDisplayBtn.Font = Enum.Font.GothamBold
LahanDisplayBtn.Text = "📍 " .. LAHAN_CATEGORIES[currentLahanIndex] .. " (" .. #getActivePlots() .. " Plots)"
LahanDisplayBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
LahanDisplayBtn.TextSize = 10
LahanDisplayBtn.AutoButtonColor = false
LahanDisplayBtn.Parent = LahanStepperBox

local LahanSubInfo = Instance.new("TextLabel")
LahanSubInfo.Size = UDim2.new(1, -24, 0, 14)
LahanSubInfo.Position = UDim2.new(0, 12, 0, 64)
LahanSubInfo.BackgroundTransparency = 1
LahanSubInfo.Font = Enum.Font.Gotham
LahanSubInfo.Text = "Tekan panah atau klik teks untuk mengganti lahan"
LahanSubInfo.TextColor3 = Color3.fromRGB(120, 125, 145)
LahanSubInfo.TextSize = 9
LahanSubInfo.TextXAlignment = Enum.TextXAlignment.Left
LahanSubInfo.Parent = LahanCard

-- Card 3: Parameter Tanam
local PlantConfigCard = createModernCard(PlantPage, 32, 144)

local ConfigInfoLabel = Instance.new("TextLabel")
ConfigInfoLabel.Size = UDim2.new(1, -24, 1, 0)
ConfigInfoLabel.Position = UDim2.new(0, 12, 0, 0)
ConfigInfoLabel.BackgroundTransparency = 1
ConfigInfoLabel.Font = Enum.Font.GothamMedium
ConfigInfoLabel.Text = string.format("⚡ Beli: %d | Delay: %.2fs | Cooldown: %.2fs | R4: %d", PlantConfig.BUY_COUNT, PlantConfig.INTER_ACTION_DELAY, PlantConfig.CYCLE_COOLDOWN, PlantConfig.PLOT4_RADIUS)
ConfigInfoLabel.TextColor3 = Color3.fromRGB(150, 155, 175)
ConfigInfoLabel.TextSize = 9
ConfigInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
ConfigInfoLabel.Parent = PlantConfigCard

-- Card 4: Toggle Auto TP (Plant)
local PlantTpCard = createModernCard(PlantPage, 40, 182)

local PlantTpLabel = Instance.new("TextLabel")
PlantTpLabel.Size = UDim2.new(1, -90, 1, 0)
PlantTpLabel.Position = UDim2.new(0, 12, 0, 0)
PlantTpLabel.BackgroundTransparency = 1
PlantTpLabel.Font = Enum.Font.GothamBold
PlantTpLabel.Text = "🚀 Auto TP ke Plot"
PlantTpLabel.TextColor3 = Color3.fromRGB(230, 230, 245)
PlantTpLabel.TextSize = 10
PlantTpLabel.TextXAlignment = Enum.TextXAlignment.Left
PlantTpLabel.Parent = PlantTpCard

local TpPlantBtn = Instance.new("TextButton")
TpPlantBtn.Name = "TpPlantBtn"
TpPlantBtn.Size = UDim2.new(0, 60, 0, 24)
TpPlantBtn.Position = UDim2.new(1, -72, 0.5, -12)
TpPlantBtn.BackgroundColor3 = PlantConfig.USE_TELEPORT and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
TpPlantBtn.BorderSizePixel = 0
TpPlantBtn.Font = Enum.Font.GothamBold
TpPlantBtn.Text = PlantConfig.USE_TELEPORT and "ON" or "OFF"
TpPlantBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TpPlantBtn.TextSize = 10
TpPlantBtn.AutoButtonColor = false
TpPlantBtn.Parent = PlantTpCard
Instance.new("UICorner", TpPlantBtn).CornerRadius = UDim.new(0, 6)

-- Toggle Auto Plant Hero Button
local TogglePlantBtn = Instance.new("TextButton")
TogglePlantBtn.Name = "TogglePlantBtn"
TogglePlantBtn.Size = UDim2.new(1, 0, 0, 42)
TogglePlantBtn.Position = UDim2.new(0, 0, 1, -44)
TogglePlantBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
TogglePlantBtn.BorderSizePixel = 0
TogglePlantBtn.Font = Enum.Font.GothamBold
TogglePlantBtn.Text = "▶  START AUTO PLANT"
TogglePlantBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TogglePlantBtn.TextSize = 11
TogglePlantBtn.AutoButtonColor = false
TogglePlantBtn.Parent = PlantPage
Instance.new("UICorner", TogglePlantBtn).CornerRadius = UDim.new(0, 10)

local PlantBtnGrad = Instance.new("UIGradient", TogglePlantBtn)
PlantBtnGrad.Rotation = 45
PlantBtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
})

-- ========================================================
-- TAB 2: AUTO CLEAN PAGE
-- ========================================================
local CleanPage = Instance.new("Frame")
CleanPage.Name = "CleanPage"
CleanPage.Size = UDim2.new(1, 0, 1, 0)
CleanPage.BackgroundTransparency = 1
CleanPage.Visible = false
CleanPage.Parent = ContentFrame

-- Card 1: Clean Status & Room
local CleanStatusCard = createModernCard(CleanPage, 48, 0)

local CleanCardIcon = Instance.new("TextLabel")
CleanCardIcon.Size = UDim2.new(0, 24, 0, 24)
CleanCardIcon.Position = UDim2.new(0, 12, 0.5, -12)
CleanCardIcon.BackgroundTransparency = 1
CleanCardIcon.Font = Enum.Font.GothamBold
CleanCardIcon.Text = "🧹"
CleanCardIcon.TextSize = 16
CleanCardIcon.Parent = CleanStatusCard

local CleanOwnerLabel = Instance.new("TextLabel")
CleanOwnerLabel.Size = UDim2.new(1, -120, 0, 16)
CleanOwnerLabel.Position = UDim2.new(0, 42, 0, 8)
CleanOwnerLabel.BackgroundTransparency = 1
CleanOwnerLabel.Font = Enum.Font.GothamBold
CleanOwnerLabel.Text = string.format("Owner: %s | Room: %s", CleanState.KosanOwner, CleanState.RoomNumber)
CleanOwnerLabel.TextColor3 = Color3.fromRGB(240, 240, 250)
CleanOwnerLabel.TextSize = 11
CleanOwnerLabel.TextXAlignment = Enum.TextXAlignment.Left
CleanOwnerLabel.Parent = CleanStatusCard

local CleanSubStatus = Instance.new("TextLabel")
CleanSubStatus.Size = UDim2.new(1, -120, 0, 14)
CleanSubStatus.Position = UDim2.new(0, 42, 0, 25)
CleanSubStatus.BackgroundTransparency = 1
CleanSubStatus.Font = Enum.Font.Gotham
CleanSubStatus.Text = "Target: Objek Kotoran (Plastic)"
CleanSubStatus.TextColor3 = Color3.fromRGB(140, 145, 165)
CleanSubStatus.TextSize = 10
CleanSubStatus.TextXAlignment = Enum.TextXAlignment.Left
CleanSubStatus.Parent = CleanStatusCard

local CleanStatusBadge = Instance.new("Frame")
CleanStatusBadge.Size = UDim2.new(0, 68, 0, 22)
CleanStatusBadge.Position = UDim2.new(1, -78, 0.5, -11)
CleanStatusBadge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
CleanStatusBadge.BorderSizePixel = 0
CleanStatusBadge.Parent = CleanStatusCard
Instance.new("UICorner", CleanStatusBadge).CornerRadius = UDim.new(0, 6)

local CleanBadgeText = Instance.new("TextLabel")
CleanBadgeText.Size = UDim2.new(1, 0, 1, 0)
CleanBadgeText.BackgroundTransparency = 1
CleanBadgeText.Font = Enum.Font.GothamBold
CleanBadgeText.Text = "● IDLE"
CleanBadgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
CleanBadgeText.TextSize = 9
CleanBadgeText.Parent = CleanStatusBadge

-- Card 2: Toggle Jarak Jauh (Auto TP Kotoran)
local CleanTpCard = createModernCard(CleanPage, 40, 54)

local CleanTpLabel = Instance.new("TextLabel")
CleanTpLabel.Size = UDim2.new(1, -90, 1, 0)
CleanTpLabel.Position = UDim2.new(0, 12, 0, 0)
CleanTpLabel.BackgroundTransparency = 1
CleanTpLabel.Font = Enum.Font.GothamBold
CleanTpLabel.Text = "🚀 Mode Jarak Jauh (Auto TP)"
CleanTpLabel.TextColor3 = Color3.fromRGB(230, 230, 245)
CleanTpLabel.TextSize = 10
CleanTpLabel.TextXAlignment = Enum.TextXAlignment.Left
CleanTpLabel.Parent = CleanTpCard

local TpCleanBtn = Instance.new("TextButton")
TpCleanBtn.Name = "TpCleanBtn"
TpCleanBtn.Size = UDim2.new(0, 60, 0, 24)
TpCleanBtn.Position = UDim2.new(1, -72, 0.5, -12)
TpCleanBtn.BackgroundColor3 = CleanState.USE_TELEPORT and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
TpCleanBtn.BorderSizePixel = 0
TpCleanBtn.Font = Enum.Font.GothamBold
TpCleanBtn.Text = CleanState.USE_TELEPORT and "ON" or "OFF"
TpCleanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TpCleanBtn.TextSize = 10
TpCleanBtn.AutoButtonColor = false
TpCleanBtn.Parent = CleanTpCard
Instance.new("UICorner", TpCleanBtn).CornerRadius = UDim.new(0, 6)

-- Card 3: Modern Inputs Container
local InputsCard = createModernCard(CleanPage, 126, 100)

local function createCyberInput(name, placeholder, defaultValue, labelText, posY)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 12)
    lbl.Position = UDim2.new(0, 12, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(99, 102, 241)
    lbl.TextSize = 8
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = InputsCard

    local box = Instance.new("TextBox")
    box.Name = name
    box.Size = UDim2.new(1, -24, 0, 24)
    box.Position = UDim2.new(0, 12, 0, posY + 14)
    box.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    box.BorderSizePixel = 0
    box.TextColor3 = Color3.fromRGB(240, 240, 250)
    box.Text = tostring(defaultValue)
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(100, 105, 125)
    box.Font = Enum.Font.Gotham
    box.TextSize = 10
    box.ClearTextOnFocus = false
    box.Parent = InputsCard
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    local bStroke = Instance.new("UIStroke", box)
    bStroke.Color = Color3.fromRGB(42, 46, 66)
    bStroke.Thickness = 1

    box.Focused:Connect(function()
        TweenService:Create(bStroke, TWEEN_FAST, { Color = Color3.fromRGB(99, 102, 241) }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(bStroke, TWEEN_FAST, { Color = Color3.fromRGB(42, 46, 66) }):Play()
    end)

    return box
end

local IdInput     = createCyberInput("IdInput", "Contoh: UserID_RoomID", CleanState.CurrentKosanID, "ID KOSAN (USERID_ROOMID):", 6)
local RadiusInput = createCyberInput("RadiusInput", "Jarak deteksi studs", CleanState.Radius, "RADIUS DETEKSI (STUDS):", 46)
local LoopInput   = createCyberInput("LoopInput", "Delay loop detik", CleanState.LoopInterval, "LOOP INTERVAL (DETIK):", 86)

-- Card: Sampah Otomatis (Ambil + Buang) setelah rumah bersih
do
    local trashCard = createModernCard(CleanPage, 36, 232)

    local trashLabel = Instance.new("TextLabel")
    trashLabel.Size = UDim2.new(1, -90, 1, 0)
    trashLabel.Position = UDim2.new(0, 12, 0, 0)
    trashLabel.BackgroundTransparency = 1
    trashLabel.Font = Enum.Font.GothamBold
    trashLabel.Text = "🗑️ Sampah: Tunggu > Ambil > Buang"
    trashLabel.TextColor3 = Color3.fromRGB(230, 230, 245)
    trashLabel.TextSize = 10
    trashLabel.TextXAlignment = Enum.TextXAlignment.Left
    trashLabel.Parent = trashCard

    local trashBtn = Instance.new("TextButton")
    trashBtn.Name = "TrashToggleBtn"
    trashBtn.Size = UDim2.new(0, 60, 0, 22)
    trashBtn.Position = UDim2.new(1, -72, 0.5, -11)
    trashBtn.BackgroundColor3 = TrashState.Enabled and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
    trashBtn.BorderSizePixel = 0
    trashBtn.Font = Enum.Font.GothamBold
    trashBtn.Text = TrashState.Enabled and "ON" or "OFF"
    trashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    trashBtn.TextSize = 10
    trashBtn.AutoButtonColor = false
    trashBtn.Parent = trashCard
    Instance.new("UICorner", trashBtn).CornerRadius = UDim.new(0, 6)

    local PHASE_LABELS = {
        BERSIH = "BERSIHKAN",
        TUNGGU = "TUNGGU SAMPAH",
        AMBIL  = "AMBIL SAMPAH",
        BUANG  = "BUANG SAMPAH"
    }

    onTrashUpdate = function()
        if not isCleanRunning then
            CleanSubStatus.Text = "Target: Objek Kotoran (Plastic)"
            return
        end
        if not TrashState.Enabled then
            CleanSubStatus.Text = "Fase: BERSIHKAN (sampah OFF)"
            return
        end
        local label = PHASE_LABELS[TrashState.Phase] or TrashState.Phase
        if TrashState.Phase == "BERSIH" and TrashState.CleanPercent then
            label = string.format("%s %d%%", label, math.floor(TrashState.CleanPercent))
        end
        CleanSubStatus.Text = string.format("Fase: %s | Bawa: %d/%d", label, getCarriedTrash(), TrashConfig.MaxCarry)
    end

    table.insert(Connections, trashBtn.Activated:Connect(function()
        TrashState.Enabled = not TrashState.Enabled
        local col = TrashState.Enabled and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
        TweenService:Create(trashBtn, TWEEN_FAST, { BackgroundColor3 = col }):Play()
        trashBtn.Text = TrashState.Enabled and "ON" or "OFF"
        onTrashUpdate()
    end))
end

-- Toggle Auto Clean Hero Button
local ToggleCleanBtn = Instance.new("TextButton")
ToggleCleanBtn.Name = "ToggleCleanBtn"
ToggleCleanBtn.Size = UDim2.new(1, 0, 0, 42)
ToggleCleanBtn.Position = UDim2.new(0, 0, 1, -44)
ToggleCleanBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
ToggleCleanBtn.BorderSizePixel = 0
ToggleCleanBtn.Font = Enum.Font.GothamBold
ToggleCleanBtn.Text = "▶  START AUTO CLEAN"
ToggleCleanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleCleanBtn.TextSize = 11
ToggleCleanBtn.AutoButtonColor = false
ToggleCleanBtn.Parent = CleanPage
Instance.new("UICorner", ToggleCleanBtn).CornerRadius = UDim.new(0, 10)

local CleanBtnGrad = Instance.new("UIGradient", ToggleCleanBtn)
CleanBtnGrad.Rotation = 45
CleanBtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
})

-- ========================================================
-- TAB 3: ANTI-AFK PAGE (TERPISAH)
-- ========================================================
local AfkPage = Instance.new("Frame")
AfkPage.Name = "AfkPage"
AfkPage.Size = UDim2.new(1, 0, 1, 0)
AfkPage.BackgroundTransparency = 1
AfkPage.Visible = false
AfkPage.Parent = ContentFrame

-- Card 1: Status Anti-AFK
local AfkStatusCard = createModernCard(AfkPage, 48, 0)

local AfkCardIcon = Instance.new("TextLabel")
AfkCardIcon.Size = UDim2.new(0, 24, 0, 24)
AfkCardIcon.Position = UDim2.new(0, 12, 0.5, -12)
AfkCardIcon.BackgroundTransparency = 1
AfkCardIcon.Font = Enum.Font.GothamBold
AfkCardIcon.Text = "🛡️"
AfkCardIcon.TextSize = 16
AfkCardIcon.Parent = AfkStatusCard

local AfkTitleLabel = Instance.new("TextLabel")
AfkTitleLabel.Size = UDim2.new(1, -120, 0, 16)
AfkTitleLabel.Position = UDim2.new(0, 42, 0, 8)
AfkTitleLabel.BackgroundTransparency = 1
AfkTitleLabel.Font = Enum.Font.GothamBold
AfkTitleLabel.Text = "Anti-AFK"
AfkTitleLabel.TextColor3 = Color3.fromRGB(240, 240, 250)
AfkTitleLabel.TextSize = 11
AfkTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
AfkTitleLabel.Parent = AfkStatusCard

local AfkSubStatus = Instance.new("TextLabel")
AfkSubStatus.Size = UDim2.new(1, -120, 0, 14)
AfkSubStatus.Position = UDim2.new(0, 42, 0, 25)
AfkSubStatus.BackgroundTransparency = 1
AfkSubStatus.Font = Enum.Font.Gotham
AfkSubStatus.Text = "Cegah kick idle 20 menit"
AfkSubStatus.TextColor3 = Color3.fromRGB(140, 145, 165)
AfkSubStatus.TextSize = 10
AfkSubStatus.TextXAlignment = Enum.TextXAlignment.Left
AfkSubStatus.Parent = AfkStatusCard

local AfkStatusBadge = Instance.new("Frame")
AfkStatusBadge.Size = UDim2.new(0, 68, 0, 22)
AfkStatusBadge.Position = UDim2.new(1, -78, 0.5, -11)
AfkStatusBadge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
AfkStatusBadge.BorderSizePixel = 0
AfkStatusBadge.Parent = AfkStatusCard
Instance.new("UICorner", AfkStatusBadge).CornerRadius = UDim.new(0, 6)

local AfkBadgeText = Instance.new("TextLabel")
AfkBadgeText.Size = UDim2.new(1, 0, 1, 0)
AfkBadgeText.BackgroundTransparency = 1
AfkBadgeText.Font = Enum.Font.GothamBold
AfkBadgeText.Text = "● OFF"
AfkBadgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
AfkBadgeText.TextSize = 9
AfkBadgeText.Parent = AfkStatusBadge

-- Card 2: Info
local AfkInfoCard = createModernCard(AfkPage, 48, 54)

local AfkInfoLabel = Instance.new("TextLabel")
AfkInfoLabel.Size = UDim2.new(1, -24, 1, 0)
AfkInfoLabel.Position = UDim2.new(0, 12, 0, 0)
AfkInfoLabel.BackgroundTransparency = 1
AfkInfoLabel.Font = Enum.Font.GothamMedium
AfkInfoLabel.Text = "Berjalan terpisah dari Auto Plant & Auto Clean. Bisa dinyalakan sendiri."
AfkInfoLabel.TextColor3 = Color3.fromRGB(150, 155, 175)
AfkInfoLabel.TextSize = 9
AfkInfoLabel.TextWrapped = true
AfkInfoLabel.TextXAlignment = Enum.TextXAlignment.Center
AfkInfoLabel.Parent = AfkInfoCard

-- Toggle Anti-AFK Hero Button
local ToggleAfkBtn = Instance.new("TextButton")
ToggleAfkBtn.Name = "ToggleAfkBtn"
ToggleAfkBtn.Size = UDim2.new(1, 0, 0, 42)
ToggleAfkBtn.Position = UDim2.new(0, 0, 1, -44)
ToggleAfkBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
ToggleAfkBtn.BorderSizePixel = 0
ToggleAfkBtn.Font = Enum.Font.GothamBold
ToggleAfkBtn.Text = "▶  START ANTI AFK"
ToggleAfkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleAfkBtn.TextSize = 11
ToggleAfkBtn.AutoButtonColor = false
ToggleAfkBtn.Parent = AfkPage
Instance.new("UICorner", ToggleAfkBtn).CornerRadius = UDim.new(0, 10)

local AfkBtnGrad = Instance.new("UIGradient", ToggleAfkBtn)
AfkBtnGrad.Rotation = 45
AfkBtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
})

-- Helper tombol START/STOP besar (dipakai tab Penyewa)
local function createHeroToggle(parent, name, text, posY)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.Position = UDim2.new(0, 0, 1, posY)
    btn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local grad = Instance.new("UIGradient", btn)
    grad.Rotation = 45
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
    })
    return btn, grad
end


-- ========================================================
-- TAB: AUTO ACC PENYEWA (TOMBOL TERPISAH)
-- ========================================================
local TenantPage = Instance.new("Frame")
TenantPage.Name = "TenantPage"
TenantPage.Size = UDim2.new(1, 0, 1, 0)
TenantPage.BackgroundTransparency = 1
TenantPage.Visible = false
TenantPage.Parent = ContentFrame

do
    local statusCard = createModernCard(TenantPage, 48, 0)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 12, 0.5, -12)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.GothamBold
    icon.Text = "🏠"
    icon.TextSize = 16
    icon.Parent = statusCard

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 0, 16)
    title.Position = UDim2.new(0, 42, 0, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "Auto Acc Penyewa"
    title.TextColor3 = Color3.fromRGB(240, 240, 250)
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = statusCard

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -120, 0, 14)
    sub.Position = UDim2.new(0, 42, 0, 25)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.Text = "Diterima: 0 | Req: 0 | Spin: 0"
    sub.TextColor3 = Color3.fromRGB(140, 145, 165)
    sub.TextSize = 10
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = statusCard

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 68, 0, 22)
    badge.Position = UDim2.new(1, -78, 0.5, -11)
    badge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
    badge.BorderSizePixel = 0
    badge.Parent = statusCard
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Font = Enum.Font.GothamBold
    badgeText.Text = "● OFF"
    badgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
    badgeText.TextSize = 9
    badgeText.Parent = badge

    local infoCard = createModernCard(TenantPage, 48, 54)
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -24, 1, 0)
    info.Position = UDim2.new(0, 12, 0, 0)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.GothamMedium
    info.Text = "Penyewa: belum terdeteksi\nSpin otomatis saat penyewa sudah 10"
    info.TextColor3 = Color3.fromRGB(150, 155, 175)
    info.TextSize = 9
    info.TextWrapped = true
    info.Parent = infoCard

    local toggleBtn, toggleGrad = createHeroToggle(TenantPage, "ToggleTenantBtn", "▶  START AUTO ACC PENYEWA", -92)
    local spinBtn, spinGrad = createHeroToggle(TenantPage, "ToggleSpinBtn", "▶  START AUTO SPIN (SAAT 10 PENYEWA)", -44)

    onTenantUpdate = function()
        sub.Text = string.format("Diterima: %d | Req: %d | Spin: %d", TenantState.AcceptCount, TenantState.CallCount, TenantState.SpinCount)
        if TenantState.DetectedTenants ~= nil then
            info.Text = string.format("Penyewa: %d/%d (%s)\nSpin otomatis saat penyewa sudah %d",
                TenantState.DetectedTenants, TenantConfig.SpinAt, TenantState.DetectSource, TenantConfig.SpinAt)
        else
            info.Text = string.format("Penyewa: belum terdeteksi (hitung dari diterima)\nSpin otomatis tiap %d penyewa", TenantConfig.SpinAt)
        end
    end

    table.insert(Connections, toggleBtn.Activated:Connect(function()
        TenantState.Running = not TenantState.Running

        if TenantState.Running then
            toggleGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 211, 153)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 185, 129))
            })
            toggleBtn.Text = "■  STOP AUTO ACC PENYEWA (RUNNING)"
            badgeText.Text = "● ACTIVE"
            badgeText.TextColor3 = Color3.fromRGB(52, 211, 153)
            badge.BackgroundColor3 = Color3.fromRGB(20, 45, 35)
            startTenantWorker()
        else
            toggleGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
            })
            toggleBtn.Text = "▶  START AUTO ACC PENYEWA"
            badgeText.Text = "● OFF"
            badgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
            badge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
            stopTenantWorker()
        end
    end))

    table.insert(Connections, spinBtn.Activated:Connect(function()
        TenantState.SpinEnabled = not TenantState.SpinEnabled

        if TenantState.SpinEnabled then
            spinGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 211, 153)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 185, 129))
            })
            spinBtn.Text = "■  STOP AUTO SPIN (RUNNING)"
            TenantState.SpinArmed = true
            startSpinWatcher()
        else
            spinGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
            })
            spinBtn.Text = "▶  START AUTO SPIN (SAAT 10 PENYEWA)"
            stopSpinWatcher()
        end
    end))
end

-- ========================================================
-- TERNAK PAGE (TRAKTOR, KOTORAN, RUTE KANDANG)
-- ========================================================
local TernakPage = Instance.new("Frame")
TernakPage.Name = "TernakPage"
TernakPage.Size = UDim2.new(1, 0, 1, 0)
TernakPage.BackgroundTransparency = 1
TernakPage.Visible = false
TernakPage.Parent = ContentFrame

local function buildTernakPage()
    local H = TernakHub
    local TraktorState = H.TraktorState
    local ConvertState, startConvertWorker, stopConvertWorker = H.ConvertState, H.startConvertWorker, H.stopConvertWorker
    local startTraktorSpawnWorker, stopTraktorSpawnWorker = H.startTraktorSpawnWorker, H.stopTraktorSpawnWorker
    local startTraktorDriveWorker, stopTraktorDriveWorker = H.startTraktorDriveWorker, H.stopTraktorDriveWorker
    local DungState, startDungWorker, stopDungWorker = H.DungState, H.startDungWorker, H.stopDungWorker
    local RouteConfig, RouteState = H.RouteConfig, H.RouteState
    local startRouteWorker, stopRouteWorker = H.startRouteWorker, H.stopRouteWorker
    local toggleRouteProfile = H.toggleRouteProfile

    -- Card: tombol terpisah Auto Spawn Traktor & Auto Mengemudi
    local traktorCard = createModernCard(TernakPage, 76, 0)

    -- Grid 2 kolom x 2 baris: tiap fitur punya tombol ON/OFF sendiri
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
    local dungLbl, dungBtn = makeSwitchRow(1, 1, "🔍 Deteksi Kotoran")

    -- Pilihan kandang tujuan (bisa pilih lebih dari satu)
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
            -- Hitung ulang segmen rute dengan pilihan baru (bila profil ini yang aktif)
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
        dungLbl.Text = string.format("🔍 Kotoran (%d | %dx)", DungState.Detected, DungState.Collected)
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

    -- Card: Masukkan kotoran ke mesin convert (hanya saat memakai traktor)
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

    -- Card: Rute Plot 8 (Kandang_1 .. Kandang_8), terpisah dari rute awal
    local plot8Card = createModernCard(TernakPage, 76, 118)
    local prof2 = RouteConfig.Profiles[2]

    local plot8Lbl = Instance.new("TextLabel")
    plot8Lbl.Size = UDim2.new(1, -76, 0, 20)
    plot8Lbl.Position = UDim2.new(0, 10, 0, 4)
    plot8Lbl.BackgroundTransparency = 1
    plot8Lbl.Font = Enum.Font.GothamBold
    plot8Lbl.Text = "🛞 Rute Plot 8"
    plot8Lbl.TextColor3 = Color3.fromRGB(230, 230, 245)
    plot8Lbl.TextSize = 9
    plot8Lbl.TextTruncate = Enum.TextTruncate.AtEnd
    plot8Lbl.TextXAlignment = Enum.TextXAlignment.Left
    plot8Lbl.Parent = plot8Card

    local plot8Btn = Instance.new("TextButton")
    plot8Btn.Size = UDim2.new(0, 44, 0, 20)
    plot8Btn.Position = UDim2.new(1, -54, 0, 4)
    plot8Btn.BackgroundColor3 = Color3.fromRGB(45, 48, 65)
    plot8Btn.BorderSizePixel = 0
    plot8Btn.Font = Enum.Font.GothamBold
    plot8Btn.Text = "OFF"
    plot8Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    plot8Btn.TextSize = 9
    plot8Btn.AutoButtonColor = false
    plot8Btn.Parent = plot8Card
    Instance.new("UICorner", plot8Btn).CornerRadius = UDim.new(0, 6)

    -- Pilihan Kandang 1..8 (2 baris x 4 kolom)
    for i, kName in ipairs(prof2.KandangNames) do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)

        local kBtn = Instance.new("TextButton")
        kBtn.Size = UDim2.new(0.25, -8, 0, 20)
        kBtn.Position = UDim2.new(col * 0.25, 5, 0, 28 + row * 24)
        kBtn.BorderSizePixel = 0
        kBtn.Font = Enum.Font.GothamBold
        kBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        kBtn.TextSize = 9
        kBtn.AutoButtonColor = false
        kBtn.Parent = plot8Card
        Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0, 6)

        local function paintKandang8()
            local on = prof2.KandangSelected[i]
            kBtn.BackgroundColor3 = on and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
            kBtn.Text = (on and "✔ " or "") .. string.gsub(kName, "_", " ")
        end
        paintKandang8()

        table.insert(Connections, kBtn.Activated:Connect(function()
            prof2.KandangSelected[i] = not prof2.KandangSelected[i]
            paintKandang8()
            if RouteState.Profile == 2 then
                RouteState.KandangPos = nil
                RouteState.Finished = false
                RouteState.NeedInit = true
            end
        end))
    end

    -- Label + tombol kedua rute mengikuti profil yang aktif (hanya satu yang bisa ON)
    H.cb.route = function()
        local active = RouteState.Running and RouteState.Profile or nil
        routeLbl.Text = active == 1 and string.format("🛞 Setir Rute (%d putaran)", RouteState.Laps) or "🛞 Setir Rute"
        plot8Lbl.Text = active == 2 and string.format("🛞 Rute Plot 8 (%d putaran)", RouteState.Laps) or "🛞 Rute Plot 8"
    end

    local function repaintRoutes()
        local active = RouteState.Running and RouteState.Profile or nil
        paintSwitch(routeBtn, active == 1)
        paintSwitch(plot8Btn, active == 2)
        H.cb.route()
    end

    table.insert(Connections, routeBtn.Activated:Connect(function()
        toggleRouteProfile(1)
        repaintRoutes()
    end))

    table.insert(Connections, plot8Btn.Activated:Connect(function()
        toggleRouteProfile(2)
        repaintRoutes()
    end))
end
buildTernakPage()

-- ========================================================
-- GACHA PAGE (AUTO GACHA PAKAI UANG)
-- ========================================================
local GachaPage = (function()
    local G = GachaHub
    local GachaConfig, GachaState = G.GachaConfig, G.GachaState

    local page = Instance.new("Frame")
    page.Name = "GachaPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = ContentFrame

    local statusCard = createModernCard(page, 48, 0)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 12, 0.5, -12)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.GothamBold
    icon.Text = "🎰"
    icon.TextSize = 16
    icon.Parent = statusCard

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 0, 16)
    title.Position = UDim2.new(0, 42, 0, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "Auto Gacha (Pakai Uang) x10"
    title.TextColor3 = Color3.fromRGB(240, 240, 250)
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = statusCard

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -120, 0, 14)
    sub.Position = UDim2.new(0, 42, 0, 25)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.Text = "Spin x10: 0 | Gagal: 0 | Tarikan: 0"
    sub.TextColor3 = Color3.fromRGB(140, 145, 165)
    sub.TextSize = 10
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = statusCard

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 68, 0, 22)
    badge.Position = UDim2.new(1, -78, 0.5, -11)
    badge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
    badge.BorderSizePixel = 0
    badge.Parent = statusCard
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Font = Enum.Font.GothamBold
    badgeText.Text = "● OFF"
    badgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
    badgeText.TextSize = 9
    badgeText.Parent = badge

    -- Card input: jeda & batas spin
    local inputsCard = createModernCard(page, 90, 54)

    local function makeInput(name, placeholder, defaultValue, labelText, posY)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -24, 0, 12)
        lbl.Position = UDim2.new(0, 12, 0, posY)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(99, 102, 241)
        lbl.TextSize = 8
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = inputsCard

        local box = Instance.new("TextBox")
        box.Name = name
        box.Size = UDim2.new(1, -24, 0, 24)
        box.Position = UDim2.new(0, 12, 0, posY + 14)
        box.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
        box.BorderSizePixel = 0
        box.TextColor3 = Color3.fromRGB(240, 240, 250)
        box.Text = tostring(defaultValue)
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = Color3.fromRGB(100, 105, 125)
        box.Font = Enum.Font.Gotham
        box.TextSize = 10
        box.ClearTextOnFocus = false
        box.Parent = inputsCard
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
        local bStroke = Instance.new("UIStroke", box)
        bStroke.Color = Color3.fromRGB(42, 46, 66)
        bStroke.Thickness = 1

        table.insert(Connections, box.Focused:Connect(function()
            TweenService:Create(bStroke, TWEEN_FAST, { Color = Color3.fromRGB(99, 102, 241) }):Play()
        end))
        table.insert(Connections, box.FocusLost:Connect(function()
            TweenService:Create(bStroke, TWEEN_FAST, { Color = Color3.fromRGB(42, 46, 66) }):Play()
        end))
        return box
    end

    local IntervalInput = makeInput("GachaIntervalInput", "Detik antar spin", GachaConfig.Interval, "JEDA ANTAR SPIN (DETIK):", 4)
    local MaxInput = makeInput("GachaMaxInput", "0 = tanpa batas", GachaConfig.MaxSpins, "BATAS SPIN x10 PER SESI (0 = TANPA BATAS):", 46)

    table.insert(Connections, IntervalInput.FocusLost:Connect(function()
        local n = tonumber(IntervalInput.Text)
        if n then
            GachaConfig.Interval = math.clamp(n, 0.2, 60)
        end
        IntervalInput.Text = tostring(GachaConfig.Interval)
    end))

    table.insert(Connections, MaxInput.FocusLost:Connect(function()
        local n = tonumber(MaxInput.Text)
        if n then
            GachaConfig.MaxSpins = math.max(0, math.floor(n))
        end
        MaxInput.Text = tostring(GachaConfig.MaxSpins)
    end))

    -- Tombol: spin sekali & auto
    local spinBtn, spinGrad = createHeroToggle(page, "GachaSpinNowBtn", "🎰  SPIN X10 SEKARANG", -92)
    spinGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246))
    })

    local toggleBtn, toggleGrad = createHeroToggle(page, "ToggleGachaBtn", "▶  START AUTO GACHA", -44)

    local function paintRunning()
        if GachaState.Running then
            toggleGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 211, 153)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 185, 129))
            })
            toggleBtn.Text = "■  STOP AUTO GACHA (RUNNING)"
            badgeText.Text = "● ACTIVE"
            badgeText.TextColor3 = Color3.fromRGB(52, 211, 153)
            badge.BackgroundColor3 = Color3.fromRGB(20, 45, 35)
        else
            toggleGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
            })
            toggleBtn.Text = "▶  START AUTO GACHA"
            badgeText.Text = "● OFF"
            badgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
            badge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
        end
    end

    G.cb.gacha = function()
        sub.Text = string.format("Spin x10: %d | Gagal: %d | Tarikan: %d",
            GachaState.Spins, GachaState.Fails, GachaState.Spins * 10)
        paintRunning()
    end

    table.insert(Connections, toggleBtn.Activated:Connect(function()
        GachaState.Running = not GachaState.Running
        if GachaState.Running then
            G.startGachaWorker()
        else
            G.stopGachaWorker()
        end
        paintRunning()
    end))

    local SPIN_NOW_TEXT = "🎰  SPIN X10 SEKARANG"
    local spinBusy = false
    table.insert(Connections, spinBtn.Activated:Connect(function()
        if spinBusy then return end
        spinBusy = true
        task.spawn(function()
            spinBtn.Text = "⏳  MEMUTAR..."
            local ok = G.spinOnce()
            if isScriptRunning then
                spinBtn.Text = ok and "✔  BERHASIL" or "✖  GAGAL / DITOLAK"
                task.wait(1.2)
                spinBtn.Text = SPIN_NOW_TEXT
            end
            spinBusy = false
        end)
    end))

    return page
end)()

-- ========================================================
-- FOOTER BAR (CREDIT: SMITH GANTENG)
-- ========================================================
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, 0, 0, 22)
Footer.Position = UDim2.new(0, 0, 1, -22)
Footer.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
Footer.BorderSizePixel = 0
Footer.Parent = MainFrame

local FooterStroke = Instance.new("UIStroke", Footer)
FooterStroke.Color = Color3.fromRGB(32, 35, 50)
FooterStroke.Thickness = 1

local FooterLabel = Instance.new("TextLabel")
FooterLabel.Size = UDim2.new(1, 0, 1, 0)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Font = Enum.Font.GothamBold
FooterLabel.Text = "✨ smith ganteng ✨"
FooterLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
FooterLabel.TextSize = 10
FooterLabel.Parent = Footer

-- ========================================================
-- TAB SWITCHING ANIMATION
-- ========================================================
local TAB_ACTIVE_BG   = Color3.fromRGB(38, 42, 62)
local TAB_INACTIVE_BG = Color3.fromRGB(20, 22, 32)
local TAB_ACTIVE_TXT  = Color3.fromRGB(255, 255, 255)
local TAB_INACTIVE_TXT = Color3.fromRGB(130, 135, 155)

local TAB_MAP = {
    Plant = { page = PlantPage, btn = TabPlantBtn },
    Clean = { page = CleanPage, btn = TabCleanBtn },
    Tenant = { page = TenantPage, btn = TabTenantBtn },
    Afk   = { page = AfkPage,   btn = TabAfkBtn },
    Ternak = { page = TernakPage, btn = TabTernakBtn },
    Gacha = { page = GachaPage, btn = createTabPill("🎰 GACHA") },
}

local function switchTab(tab)
    for name, entry in pairs(TAB_MAP) do
        local active = (name == tab)
        entry.page.Visible = active
        TweenService:Create(entry.btn, TWEEN_SMOOTH, {
            BackgroundColor3 = active and TAB_ACTIVE_BG or TAB_INACTIVE_BG,
            TextColor3 = active and TAB_ACTIVE_TXT or TAB_INACTIVE_TXT
        }):Play()
    end
end

-- Default active tab
switchTab("Plant")

table.insert(Connections, TabPlantBtn.Activated:Connect(function() switchTab("Plant") end))
table.insert(Connections, TabCleanBtn.Activated:Connect(function() switchTab("Clean") end))
table.insert(Connections, TabTenantBtn.Activated:Connect(function() switchTab("Tenant") end))
table.insert(Connections, TabAfkBtn.Activated:Connect(function() switchTab("Afk") end))
table.insert(Connections, TabTernakBtn.Activated:Connect(function() switchTab("Ternak") end))
table.insert(Connections, TAB_MAP.Gacha.btn.Activated:Connect(function() switchTab("Gacha") end))

-- ========================================================
-- LOGIC HANDLERS & ANIMATIONS
-- ========================================================

-- Update Lahan Stepper UI
local function updateLahanDisplay()
    local name = LAHAN_CATEGORIES[currentLahanIndex]
    local plots = LAHAN_PRESETS[name] or {}
    LahanDisplayBtn.Text = "📍 " .. name .. " (" .. #plots .. " Plots)"
    PlantSubStatus.Text = string.format("Plot Terpilih: %d Titik Koordinat", #plots)
end

table.insert(Connections, PrevLahanBtn.Activated:Connect(function()
    currentLahanIndex = currentLahanIndex - 1
    if currentLahanIndex < 1 then currentLahanIndex = #LAHAN_CATEGORIES end
    updateLahanDisplay()
end))

table.insert(Connections, NextLahanBtn.Activated:Connect(function()
    currentLahanIndex = currentLahanIndex + 1
    if currentLahanIndex > #LAHAN_CATEGORIES then currentLahanIndex = 1 end
    updateLahanDisplay()
end))

table.insert(Connections, LahanDisplayBtn.Activated:Connect(function()
    currentLahanIndex = currentLahanIndex + 1
    if currentLahanIndex > #LAHAN_CATEGORIES then currentLahanIndex = 1 end
    updateLahanDisplay()
end))

-- Toggle Auto TP Button (Plant)
table.insert(Connections, TpPlantBtn.Activated:Connect(function()
    PlantConfig.USE_TELEPORT = not PlantConfig.USE_TELEPORT
    local col = PlantConfig.USE_TELEPORT and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
    TweenService:Create(TpPlantBtn, TWEEN_FAST, { BackgroundColor3 = col }):Play()
    TpPlantBtn.Text = PlantConfig.USE_TELEPORT and "ON" or "OFF"
end))

-- Toggle Jarak Jauh Button (Clean)
table.insert(Connections, TpCleanBtn.Activated:Connect(function()
    CleanState.USE_TELEPORT = not CleanState.USE_TELEPORT
    local col = CleanState.USE_TELEPORT and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(45, 48, 65)
    TweenService:Create(TpCleanBtn, TWEEN_FAST, { BackgroundColor3 = col }):Play()
    TpCleanBtn.Text = CleanState.USE_TELEPORT and "ON" or "OFF"
end))

-- Input Listeners for Clean
table.insert(Connections, IdInput.FocusLost:Connect(function()
    CleanState.CurrentKosanID = IdInput.Text
    local o, r = parseKosanID(IdInput.Text)
    CleanState.KosanOwner, CleanState.RoomNumber = o, r
    CleanOwnerLabel.Text = string.format("Owner: %s | Room: %s", o, r)
end))

table.insert(Connections, RadiusInput.FocusLost:Connect(function()
    local val = tonumber(RadiusInput.Text)
    CleanState.Radius = (val and val > 0) and val or CleanConfig.DefaultRadius
    RadiusInput.Text = tostring(CleanState.Radius)
end))

table.insert(Connections, LoopInput.FocusLost:Connect(function()
    local val = tonumber(LoopInput.Text)
    CleanState.LoopInterval = (val and val >= CleanConfig.MinLoopInterval) and val or CleanConfig.DefaultLoop
    LoopInput.Text = tostring(CleanState.LoopInterval)
end))

-- Toggle Plant Button Logic
table.insert(Connections, TogglePlantBtn.Activated:Connect(function()
    isPlantRunning = not isPlantRunning

    if isPlantRunning then
        PlantBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 211, 153)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 185, 129))
        })
        TogglePlantBtn.Text = "■  STOP AUTO PLANT (RUNNING)"
        PlantBadgeText.Text = "● ACTIVE"
        PlantBadgeText.TextColor3 = Color3.fromRGB(52, 211, 153)
        PlantStatusBadge.BackgroundColor3 = Color3.fromRGB(20, 45, 35)
        startPlantingLoop()
    else
        PlantBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
        })
        TogglePlantBtn.Text = "▶  START AUTO PLANT"
        PlantBadgeText.Text = "● IDLE"
        PlantBadgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
        PlantStatusBadge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
        stopPlantingLoop()
    end
end))

-- Toggle Clean Button Logic
table.insert(Connections, ToggleCleanBtn.Activated:Connect(function()
    isCleanRunning = not isCleanRunning

    if isCleanRunning then
        CleanBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 211, 153)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 185, 129))
        })
        ToggleCleanBtn.Text = "■  STOP AUTO CLEAN (RUNNING)"
        CleanBadgeText.Text = "● ACTIVE"
        CleanBadgeText.TextColor3 = Color3.fromRGB(52, 211, 153)
        CleanStatusBadge.BackgroundColor3 = Color3.fromRGB(20, 45, 35)
        startCleaningLoop()
    else
        CleanBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
        })
        ToggleCleanBtn.Text = "▶  START AUTO CLEAN"
        CleanBadgeText.Text = "● IDLE"
        CleanBadgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
        CleanStatusBadge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
        stopCleaningLoop()
    end
end))

-- Toggle Anti-AFK Button Logic
table.insert(Connections, ToggleAfkBtn.Activated:Connect(function()
    isAntiAfkRunning = not isAntiAfkRunning

    if isAntiAfkRunning then
        AfkBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 211, 153)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 185, 129))
        })
        ToggleAfkBtn.Text = "■  STOP ANTI AFK (RUNNING)"
        AfkBadgeText.Text = "● ACTIVE"
        AfkBadgeText.TextColor3 = Color3.fromRGB(52, 211, 153)
        AfkStatusBadge.BackgroundColor3 = Color3.fromRGB(20, 45, 35)
        startAntiAfk()
    else
        AfkBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 63, 94)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72))
        })
        ToggleAfkBtn.Text = "▶  START ANTI AFK"
        AfkBadgeText.Text = "● OFF"
        AfkBadgeText.TextColor3 = Color3.fromRGB(160, 165, 185)
        AfkStatusBadge.BackgroundColor3 = Color3.fromRGB(30, 33, 46)
        stopAntiAfk()
    end
end))

-- Minimize & Restore Window Animation
local isMinimized = false
table.insert(Connections, MiniBtn.Activated:Connect(function()
    isMinimized = not isMinimized
    local targetHeight = isMinimized and MINI_HEIGHT or WIN_HEIGHT

    TabBar.Visible = not isMinimized
    ContentFrame.Visible = not isMinimized
    Footer.Visible = not isMinimized
    MiniBtn.Text = isMinimized and "+" or "—"

    TweenService:Create(MainFrame, TWEEN_SMOOTH, {
        Size = UDim2.new(0, WIN_WIDTH, 0, targetHeight)
    }):Play()
end))

-- Drag window manual (support mouse & touch di semua executor)
end)()
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
