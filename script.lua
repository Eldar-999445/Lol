-- Настройки
local AUDIO_ID_1 = "rbxassetid://115287262309884" -- Основной звук (Громкий, кик по его окончании)
local AUDIO_ID_2 = "rbxassetid://116103157999673" -- Фоновый звук (В 2 раза тише, с 5 сек, скорость 0.95)
local IMAGE_NAME = "mge.png"
local GITHUB_URL = "https://github.com/Eldar-999445/Haha-/blob/main/mge.png?raw=true"
local FOLDER_NAME = "mge"

local FADE_TIME = 0.15      -- Время появления (0.15 сек)
local HOLD_TIME = 6.765714  -- Точное время удержания картинки и длительность первого трека
local KICK_REASON = "сосунок" -- Причина кика

-- Проверка функций инжектора
local getcustomasset = getcustomasset or syn_getcustomasset
local writefile = writefile or syn_writefile
local isfile = isfile or syn_isfile
local gameHttpGet = game.HttpGet

if not getcustomasset then
    error("Твой инжектор не поддерживает getcustomasset!")
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local localPlayer = Players.LocalPlayer

-- Создаем интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XenoMgeAudioBoundKickPlayer"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 99999 -- Поверх окон Roblox
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Черный задний фон
local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 1
background.Parent = screenGui

-- Картинка (Растянутая на весь экран)
local imageLabel = Instance.new("ImageLabel")
imageLabel.Size = UDim2.new(1, 0, 1, 0)
imageLabel.BackgroundTransparency = 1
imageLabel.ImageTransparency = 1
imageLabel.ScaleType = Enum.ScaleType.Stretch
imageLabel.Parent = background

-- Усиление звуков через каскад SoundGroup
local group1 = Instance.new("SoundGroup")
group1.Volume = 2
group1.Parent = SoundService

local group2 = Instance.new("SoundGroup")
group2.Volume = 2
group2.Parent = group1

local group3 = Instance.new("SoundGroup")
group3.Volume = 2
group3.Parent = group2

-- Первый звук (Максимальная громкость х16)
local sound1 = Instance.new("Sound")
sound1.SoundId = AUDIO_ID_1
sound1.Volume = 2
sound1.SoundGroup = group3
sound1.Parent = screenGui

-- Второй звук (В 2 раза тише, старт с 5 сек, скорость 0.95)
local sound2 = Instance.new("Sound")
sound2.SoundId = AUDIO_ID_2
sound2.Volume = 1
sound2.PlaybackSpeed = 0.95
sound2.TimePosition = 5
sound2.SoundGroup = group3
sound2.Parent = screenGui

local isPlaying = true
local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

-- --- УМНЫЙ ПОИСК КАРТИНКИ ---
local function getLocalImage()
    local paths = {
        IMAGE_NAME,
        FOLDER_NAME .. "/" .. IMAGE_NAME,
        "workspace/" .. IMAGE_NAME,
        "workspace/" .. FOLDER_NAME .. "/" .. IMAGE_NAME
    }
    for _, path in ipairs(paths) do
        if isfile and isfile(path) then
            local success, assetId = pcall(getcustomasset, path)
            if success then return assetId end
        end
    end
    return nil
end

-- --- ПЛАВНОЕ ПОЯВЛЕНИЕ ---
local function fadeIn()
    local bgTween = TweenService:Create(background, tweenInfo, {BackgroundTransparency = 0})
    local imgTween = TweenService:Create(imageLabel, tweenInfo, {ImageTransparency = 0})
    
    bgTween:Play()
    imgTween:Play()
    imgTween.Completed:Wait()
end

-- --- ЗАКРЫТИЕ И ОЧИСТКА ---
local function destroyGui()
    screenGui:Destroy()
    group3:Destroy()
    group2:Destroy()
    group1:Destroy()
end

-- --- ЗАПУСК ---
task.spawn(function()
    local imgAsset = getLocalImage()
    if not imgAsset and writefile and gameHttpGet then
        local success, content = pcall(gameHttpGet, game, GITHUB_URL)
        if success and content then
            writefile(IMAGE_NAME, content)
            imgAsset = getcustomasset(IMAGE_NAME)
        end
    end
    
    if imgAsset then
        imageLabel.Image = imgAsset
    end
    
    if isPlaying then
        -- 1. Моментальный старт обоих треков
        sound1:Play()
        sound2:Play()
        
        -- 2. Быстрое появление визуала (0.15 сек)
        fadeIn()
        
        -- 3. Ждем точную длительность первого аудио
        task.wait(HOLD_TIME)
        
        -- 4. Страховка: если первый звук из-за пинга ещё доигрывает, ждем его конца
        if sound1.Playing then
            sound1.Ended:Wait()
        end
        
        -- 5. Мгновенный кик сразу после финала первого трека (картинка не исчезает до дисконнекта)
        if isPlaying then
            localPlayer:Kick(KICK_REASON)
        end
    end
end)

-- --- МГНОВЕННАЯ ОТМЕНА НА КЛАВИШУ P (ДЛЯ ТЕСТОВ) ---
local inputConnection
inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
        isPlaying = false
        inputConnection:Disconnect()
        if sound1 then sound1:Stop() end
        if sound2 then sound2:Stop() end
        destroyGui()
    end
end)