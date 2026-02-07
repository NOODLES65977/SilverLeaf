local WindUI = loadstring(game:HttpGet("https://pastefy.app/y2EGDNko/raw"))()

task.wait(2)

WindUI:Notify({
    Title = "Lostsoul",
    Content = "UI翻译已完成加载过程",
    Duration = 4
})

task.wait(0.5)

local player = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local playerGui = player.PlayerGui

local Window = WindUI:CreateWindow({
    Title = "Lostsoul<font color='#00FF00'>Translation</font>",
    Icon = "rbxassetid://4483362748",
    IconTransparency = 1,
    Author = " UI翻译",
    Folder = "Translator",
    Size = UDim2.fromOffset(460, 395),
    Transparent = true,
    Theme = "Dark",
    UserEnabled = true,
    SideBarWidth = 200,
    HasOutline = true,
    User = {
        Enabled = true,
        Anonymous = false,
        Username = player.Name,
        DisplayName = player.DisplayName,
        UserId = player.UserId,
        Thumbnail = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png",
        Callback = function()
            WindUI:Notify({
                Title = "用户信息",
                Content = "玩家: " .. player.Name,
                Duration = 3
            })
        end
    }
})

task.wait(0.3)

Window:EditOpenButton({
    Title = "Translation",
    Icon = "crown",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0000"), 
        Color3.fromHex("0000FF")
    ),
    Draggable = true,
})

task.wait(0.2)

local Tabs = {
    Main = Window:Section({ Title = "翻译", Opened = true }),
    Advanced = Window:Section({ Title = "检测", Opened = false })
}

local TabHandles = {
    Translator = Tabs.Main:Tab({ Title = "翻译", Icon = "languages" }),
    Detection = Tabs.Advanced:Tab({ Title = "UI检测", Icon = "search" })
}

TabHandles.Translator:Paragraph({
    Title = "Lostsoul翻译",
    Desc = "",
    Image = "code",
    ImageSize = 20,
    Color = "White",
})

TabHandles.Translator:Divider()

local languageCodes = {
    ["自动检测"] = "auto",
    ["中文(简体)"] = "zh-CN",
    ["中文(繁体)"] = "zh-TW",
    ["英语"] = "en",
    ["日语"] = "ja",
    ["韩语"] = "ko",
    ["法语"] = "fr",
    ["德语"] = "de",
    ["西班牙语"] = "es",
    ["俄语"] = "ru",
    ["阿拉伯语"] = "ar",
    ["葡萄牙语"] = "pt",
    ["意大利语"] = "it",
    ["荷兰语"] = "nl",
    ["希腊语"] = "el",
    ["印地语"] = "hi",
    ["土耳其语"] = "tr",
    ["越南语"] = "vi",
    ["泰语"] = "th"
}

local languageList = {
    "自动检测",
    "中文(简体)",
    "中文(繁体)",
    "英语",
    "日语",
    "韩语",
    "法语",
    "德语",
    "西班牙语",
    "俄语",
    "阿拉伯语",
    "葡萄牙语",
    "意大利语",
    "荷兰语",
    "希腊语",
    "印地语",
    "土耳其语",
    "越南语",
    "泰语"
}

local translationCache = {}
local isTranslating = false
local lastTranslatedText = ""
local lastUsedAPI = "Google"

local YOUDAO_APP_ID = "015e4bc650d16a48"
local YOUDAO_APP_KEY = "wXwwoaeESXz9CzB3yeTDe54JuOzkVbH7"

local SUPPORTED_UI_TYPES = {
    "TextLabel", "TextButton", "TextBox", "TextLabel", 
    "Frame", "ScrollingFrame", "ImageButton", "ImageLabel"
}

local DANGEROUS_COMMANDS = {
    "neon", "shine", "ghost", "gold", "spin", 
    "bighead", "smallhead", "giantdwarf", "squash"
}

local LANGUAGE_PATTERNS = {
    ["zh-CN"] = {
        pattern = "[\199-\244][\128-\191]*[\128-\191]",
        exclude = "[\227][\128-\191][\128-\191]"
    },
    ["zh-TW"] = {
        pattern = "[\227][\128-\191][\128-\191]"
    },
    ["ja"] = {
        pattern = "[\123-\125]|[\199-\244][\128-\191]*[\128-\191]",
        exclude = "[\199-\244][\128-\191]*[\128-\191]"
    },
    ["ko"] = {
        pattern = "[\234-\235][\128-\191][\128-\191]|[\236-\237][\128-\191][\128-\191]"
    },
    ["ar"] = {
        pattern = "[\216-\219][\128-\191]"
    },
    ["ru"] = {
        pattern = "[\208-\209][\128-\191]"
    },
    ["th"] = {
        pattern = "[\224-\231][\128-\191]"
    },
    ["en"] = {
        pattern = "[A-Za-z]",
        exclude = "[\199-\244][\128-\191]*[\128-\191]"
    }
}

local TARGET_LANGUAGE = "zh-CN"
local SCAN_INTERVAL = 2
local MAX_TEXT_LENGTH = 5000

local translatedCache = {}
local translatedObjects = {}
local isTranslationEnabled = false
local connection = nil

local BATCH_SIZE = 20
local MAX_CACHE_SIZE = 3000
local lastScanTime = 0
local SCAN_COOLDOWN = 0.02
local TRANSLATION_DELAY = 0.01
local MAX_CONCURRENT_REQUESTS = 10

local function isDangerousText(text)
    if not text or type(text) ~= "string" then return false end
    local lowerText = text:lower()
    for _, cmd in ipairs(DANGEROUS_COMMANDS) do
        if lowerText:find(cmd) then
            return true
        end
    end
    return false
end

local function shouldSkipTranslation(text)
    if not text or text == "" or translatedCache[text] then
        return true
    end
    
    if text:match("^%s*$") or 
       text:match("^[0-9%.%s,:/]+$") or 
       #text > MAX_TEXT_LENGTH or
       isDangerousText(text) then
        translatedCache[text] = text
        return true
    end
    
    return false
end

local function detectLanguage(text)
    if not text or type(text) ~= "string" or text == "" then
        return "en"
    end
    
    if text:match(LANGUAGE_PATTERNS["zh-CN"].pattern) and 
       (not LANGUAGE_PATTERNS["zh-CN"].exclude or not text:match(LANGUAGE_PATTERNS["zh-CN"].exclude)) then
        return "zh-CN"
    end
    
    if text:match(LANGUAGE_PATTERNS["zh-TW"].pattern) then
        return "zh-TW"
    end
    
    if text:match(LANGUAGE_PATTERNS["ja"].pattern) and 
       (not LANGUAGE_PATTERNS["ja"].exclude or not text:match(LANGUAGE_PATTERNS["ja"].exclude)) then
        return "ja"
    end
    
    if text:match(LANGUAGE_PATTERNS["ko"].pattern) then
        return "ko"
    end
    
    if text:match(LANGUAGE_PATTERNS["ar"].pattern) then
        return "ar"
    end
    
    if text:match(LANGUAGE_PATTERNS["ru"].pattern) then
        return "ru"
    end
    
    if text:match(LANGUAGE_PATTERNS["th"].pattern) then
        return "th"
    end
    
    return "en"
end

local function googleTranslate(text, targetLang, sourceLang)
    if not text or text == "" then return text end
    
    sourceLang = sourceLang or "auto"
    
    local cacheKey = "google_"..text.."|"..sourceLang.."|"..targetLang
    if translationCache[cacheKey] then
        return translationCache[cacheKey]
    end
    
    local url = string.format(
        "https://translate.googleapis.com/translate_a/single?client=gtx&sl=%s&tl=%s&dt=t&q=%s",
        sourceLang, targetLang, HttpService:UrlEncode(text)
    )
    
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success and response then
        local success2, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if success2 and data and data[1] then
            local result = ""
            for i, segment in ipairs(data[1]) do
                if segment[1] then
                    result = result .. segment[1]
                end
            end
            
            if result ~= "" and result ~= text then
                translationCache[cacheKey] = result
                lastUsedAPI = "Google"
                return result
            end
        end
    end
    
    return nil
end

local function youdaoTranslate(text, targetLang, sourceLang)
    if not text or text == "" then return text end
    
    sourceLang = sourceLang or "auto"
    
    local cacheKey = "youdao_"..text.."|"..sourceLang.."|"..targetLang
    if translationCache[cacheKey] then
        return translationCache[cacheKey]
    end
    
    local salt = tostring(tick())
    local input = text
    if #input > 20 then
        input = input:sub(1, 10) .. #input .. input:sub(-10)
    end
    
    local signStr = YOUDAO_APP_ID .. input .. salt .. YOUDAO_APP_KEY
    local sign = game:GetService("HashService"):ComputeMD5Async(signStr)
    
    local url = string.format(
        "https://openapi.youdao.com/api?q=%s&from=%s&to=%s&appKey=%s&salt=%s&sign=%s",
        HttpService:UrlEncode(text),
        sourceLang == "auto" and "auto" or sourceLang,
        targetLang,
        YOUDAO_APP_ID,
        salt,
        sign
    )
    
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success and response then
        local success2, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if success2 and data and data.translation and data.translation[1] then
            local result = data.translation[1]
            
            if result ~= "" and result ~= text then
                translationCache[cacheKey] = result
                lastUsedAPI = "Youdao"
                return result
            end
        end
    end
    
    return nil
end

local function translateText(text, targetLang, sourceLang)
    if not text or text == "" or text:match("^%s*$") then
        return text
    end
    
    if text:match("^[%d%p%s]+$") then
        return text
    end
    
    local detectedLang = detectLanguage(text)
    
    if detectedLang == "zh-CN" or detectedLang == "zh-TW" then
        return text
    end
    
    local result = googleTranslate(text, targetLang, sourceLang)
    if not result or result == text then
        result = youdaoTranslate(text, targetLang, sourceLang)
    end
    return result or text
end

local targetLang = "zh-CN"
local sourceLang = "auto"

local sourceLangDropdown = TabHandles.Translator:Dropdown({
    Title = "被翻译语言",
    Values = languageList,
    Value = "自动检测",
    Callback = function(option)
        sourceLang = languageCodes[option] or "auto"
        WindUI:Notify({
            Title = "被翻译语言设置",
            Content = "已选择: " .. option,
            Duration = 2
        })
    end
})

local targetLangDropdown = TabHandles.Translator:Dropdown({
    Title = "翻译语言",
    Values = languageList,
    Value = "中文(简体)",
    Callback = function(option)
        if option ~= "自动检测" then
            targetLang = languageCodes[option] or "zh-CN"
            WindUI:Notify({
                Title = "翻译语言设置",
                Content = "已选择: " .. option,
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "错误",
                Content = "翻译语言不能选择自动检测",
                Duration = 2
            })
        end
    end
})

local currentMode = 2
local modes = {
    {"快速模式", "置于极速之前"},
    {"标准模式", "上下文翻译"},
    {"基本全翻译模式", "完整翻译"},
    {"极速模式", "速度翻译"}
}

local modeDropdown = TabHandles.Translator:Dropdown({
    Title = "翻译模式",
    Values = {"快速模式", "标准模式", "基本全翻译模式", "极速模式"},
    Value = "自匹配模式",
    Callback = function(option)
        currentMode = table.find({"快速模式", "标准模式", "基本全翻译模式", "极速模式"}, option) or 2
        
        if option == "极速模式" then
            BATCH_SIZE = 50
            SCAN_COOLDOWN = 0.005
            TRANSLATION_DELAY = 0.002
            MAX_CONCURRENT_REQUESTS = 25
        elseif option == "快速模式" then
            BATCH_SIZE = 30
            SCAN_COOLDOWN = 0.01
            TRANSLATION_DELAY = 0.005
            MAX_CONCURRENT_REQUESTS = 15
        elseif option == "标配模式" then
            BATCH_SIZE = 20
            SCAN_COOLDOWN = 0.02
            TRANSLATION_DELAY = 0.01
            MAX_CONCURRENT_REQUESTS = 10
        elseif option == "全翻译模式" then
            BATCH_SIZE = 10
            SCAN_COOLDOWN = 0.05
            TRANSLATION_DELAY = 0.02
            MAX_CONCURRENT_REQUESTS = 5
        end
        
        WindUI:Notify({
            Title = "模式切换",
            Content = modes[currentMode][2],
            Duration = 2
        })
    end
})

local cacheEnabled = true
TabHandles.Translator:Toggle({
    Title = "启用缓存",
    Desc = "提高翻译效率",
    Value = true,
    Callback = function(state)
        cacheEnabled = state
        if not cacheEnabled then
            translationCache = {}
        end
    end
})

TabHandles.Translator:Divider()

local function hasTextContent(gui)
    if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
        return gui.Text and gui.Text ~= ""
    elseif gui:IsA("ImageButton") or gui:IsA("ImageLabel") then
        return gui:GetAttribute("Text") or gui.Name ~= ""
    end
    return false
end

local function getTextContent(gui)
    if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
        return gui.Text
    elseif gui:IsA("ImageButton") or gui:IsA("ImageLabel") then
        return gui:GetAttribute("Text") or gui.Name
    end
    return nil
end

local function setTextContent(gui, text)
    if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
        gui.Text = text
    elseif gui:IsA("ImageButton") or gui:IsA("ImageLabel") then
        gui:SetAttribute("OriginalText", getTextContent(gui))
        gui:SetAttribute("Text", text)
    end
end

local function parallelTranslateBatch(batch)
    local results = {}
    local completed = 0
    local total = #batch
    local activeRequests = 0
    
    local function processItem(item, index)
        if not translatedCache[item.text] then
            activeRequests = activeRequests + 1
            
            local success, translated = pcall(function()
                return translateText(item.text, targetLang, sourceLang)
            end)
            
            if success and translated and translated ~= item.text then
                results[item.gui] = translated
                translatedCache[item.text] = translated
                lastTranslatedText = item.text .. " → " .. translated
                lastUsedAPI = "Google"
            else
                translatedCache[item.text] = item.text
            end
            
            activeRequests = activeRequests - 1
        end
        completed = completed + 1
    end
    
    for i, item in ipairs(batch) do
        while activeRequests >= MAX_CONCURRENT_REQUESTS do
            task.wait()
        end
        
        task.spawn(processItem, item, i)
        
        if i % 5 == 0 then
            task.wait(0.001)
        end
    end
    
    while completed < total do
        task.wait()
    end
    
    return results, total
end

local function fastCollectElements()
    local elementsToTranslate = {}
    local guisToScan = {playerGui, CoreGui}
    
    for _, gui in ipairs(guisToScan) do
        if gui and gui:IsDescendantOf(game) then
            local descendants = gui:GetDescendants()
            for i = 1, #descendants do
                local guiObj = descendants[i]
                if not translatedObjects[guiObj] and table.find(SUPPORTED_UI_TYPES, guiObj.ClassName) then
                    local text = getTextContent(guiObj)
                    if text and text ~= "" and not shouldSkipTranslation(text) then
                        table.insert(elementsToTranslate, {
                            gui = guiObj,
                            text = text
                        })
                        translatedObjects[guiObj] = true
                    end
                end
            end
        end
    end
    
    return elementsToTranslate
end

local function ultraFastTranslateGuiElements()
    local count = 0
    local currentTime = tick()
    
    if currentTime - lastScanTime < SCAN_COOLDOWN then
        return count
    end
    lastScanTime = currentTime
    
    local elementsToTranslate = fastCollectElements()
    
    if #elementsToTranslate > 0 then
        for i = 1, #elementsToTranslate, BATCH_SIZE do
            local batch = {}
            local batchEnd = math.min(i + BATCH_SIZE - 1, #elementsToTranslate)
            
            for j = i, batchEnd do
                table.insert(batch, elementsToTranslate[j])
            end
            
            local batchResults, batchCount = parallelTranslateBatch(batch)
            count = count + batchCount
            
            for gui, translated in pairs(batchResults) do
                if gui and gui.Parent then
                    setTextContent(gui, translated)
                end
            end
            
            if batchCount > 0 then
                task.wait(TRANSLATION_DELAY)
            end
        end
        
        if count > 0 and TabHandles.Translator then
            for _, paragraph in pairs(TabHandles.Translator.Paragraphs or {}) do
                if paragraph.Title == "最近翻译" then
                    paragraph:SetDesc(lastTranslatedText .. " (via " .. lastUsedAPI .. ")")
                    break
                end
            end
        end
    end
    
    if table.count(translatedCache) > MAX_CACHE_SIZE then
        local newCache = {}
        local i = 0
        for k, v in pairs(translatedCache) do
            if i < MAX_CACHE_SIZE / 2 then
                newCache[k] = v
                i = i + 1
            else
                break
            end
        end
        translatedCache = newCache
    end
    
    return count
end

local function deepScanUI()
    local guisToScan = {
        player.PlayerGui,
        CoreGui
    }
    
    for _, service in ipairs({
        game:GetService("StarterGui"),
        game:GetService("CoreGui"),
        game:GetService("Players").LocalPlayer.PlayerGui
    }) do
        table.insert(guisToScan, service)
    end
    
    return guisToScan
end

local translateButtonRef
translateButtonRef = TabHandles.Translator:Button({
    Title = "执行翻译",
    Icon = "play",
    Variant = "Primary",
    Callback = function()
        if isTranslating then
            isTranslating = false
            if translateButtonRef then
                translateButtonRef:SetTitle("执行翻译")
            end
            WindUI:Notify({
                Title = "翻译",
                Content = "翻译已停止",
                Icon = "stop-circle",
                Duration = 2
            })
            return
        end
        
        isTranslating = true
        if translateButtonRef then
            translateButtonRef:SetTitle("停止翻译")
        end
        WindUI:Notify({
            Title = "翻译",
            Content = "极速翻译已启动",
            Icon = "zap",
            Duration = 2
        })
        
        task.spawn(function()
            local startTime = tick()
            local totalTranslated = 0
            
            while isTranslating and tick() - startTime < 5 do
                local count = ultraFastTranslateGuiElements()
                totalTranslated = totalTranslated + count
                
                local elapsed = tick() - startTime
                if elapsed > 3 and count == 0 then
                    break
                end
                
                task.wait(0.03)
            end
            
            if isTranslating then
                isTranslating = false
                if translateButtonRef then
                    translateButtonRef:SetTitle("执行翻译")
                end
                
                WindUI:Notify({
                    Title = "翻译完成",
                    Content = string.format("5秒内翻译了 %d 个元素", totalTranslated),
                    Icon = "check-circle",
                    Duration = 3
                })
            end
        end)
    end
})

local speedSlider = TabHandles.Translator:Slider({
    Title = "翻译速度",
    Desc = "调整翻译速度",
    Value = { Min = 1, Max = 10, Default = 5 },
    Callback = function(value)
        if currentMode ~= 4 then
            BATCH_SIZE = 20 + value * 5
            SCAN_COOLDOWN = 0.01 - (value * 0.001)
            MAX_CONCURRENT_REQUESTS = 10 + value * 2
            
            WindUI:Notify({
                Title = "速度",
                Content = string.format("速度: %d, 批量: %d, 并发: %d", value, BATCH_SIZE, MAX_CONCURRENT_REQUESTS),
                Duration = 1
            })
        else
            WindUI:Notify({
                Title = "提示",
                Content = "极速模式下调整速度参数无用",
                Duration = 2
            })
        end
    end
})

TabHandles.Translator:Divider()

local lastTranslation = TabHandles.Translator:Paragraph({
    Title = "最近翻译",
    Desc = "无",
    Image = "clock",
    ImageSize = 20,
    Color = "Grey"
})

TabHandles.Translator:Button({
    Title = "清理缓存",
    Icon = "trash",
    Callback = function()
        translationCache = {}
        translatedCache = {}
        translatedObjects = {}
        WindUI:Notify({
            Title = "缓存已清理完毕",
            Content = "翻译缓存已清空",
            Duration = 2
        })
    end
})

TabHandles.Translator:Button({
    Title = "刷新",
    Icon = "refresh-cw",
    Callback = function()
        for k in pairs(translatedCache) do
            translatedCache[k] = nil
        end
        
        WindUI:Notify({
            Title = "强制刷新",
            Content = "已清除翻译缓存，下次扫描将重新翻译",
            Duration = 2
        })
    end
})

TabHandles.Detection:Paragraph({
    Title = "UI检测",
    Desc = "检测所有UI",
    Image = "search",
    ImageSize = 20,
    Color = "White"
})

local gameInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
TabHandles.Detection:Paragraph({
    Title = "游戏信息",
    Desc = gameInfo.Name,
    Image = "info",
    ImageSize = 20,
    Color = "Grey"
})

TabHandles.Detection:Button({
    Title = "检测UI",
    Icon = "search",
    Callback = function()
        local uiCount = 0
        local textCount = 0
        
        local guisToScan = deepScanUI()
        for _, gui in ipairs(guisToScan) do
            pcall(function()
                for _, child in ipairs(gui:GetDescendants()) do
                    if table.find(SUPPORTED_UI_TYPES, child.ClassName) then
                        uiCount = uiCount + 1
                        if hasTextContent(child) then
                            textCount = textCount + 1
                        end
                    end
                end
            end)
        end
        
        WindUI:Notify({
            Title = "UI检测结果",
            Content = string.format("发现 %d 个UI元素，%d 个有文本内容", uiCount, textCount),
            Duration = 5
        })
    end
})

Window:OnClose(function()
    isTranslating = false
end)

Window:OnDestroy(function()
    isTranslating = false
end)

task.spawn(function()
    local commonTexts = {
        "Play", "Start", "Settings", "Options", "Exit", "Continue",
        "Back", "Next", "Yes", "No", "OK", "Cancel", "Loading"
    }
    
    for _, text in ipairs(commonTexts) do
        pcall(function()
            translateText(text, targetLang, "en")
        end)
    end
end)

local function cleanupMemory()
    collectgarbage("collect")
    
    if table and table.count and table.count(translatedCache) > MAX_CACHE_SIZE then
        local newCache = {}
        local i = 0
        for k, v in pairs(translatedCache) do
            if i < MAX_CACHE_SIZE / 2 then
                newCache[k] = v
                i = i + 1
            else
                break
            end
        end
        translatedCache = newCache
    end
    
    task.wait(5)
end

task.spawn(function()
    while true do
        cleanupMemory()
        task.wait(30)
    end
end)

task.wait(1)
WindUI:Notify({
    Title = " 已加载完毕",
    Content = "I汉化",
    Icon = "check-circle",
    Duration = 3
})
