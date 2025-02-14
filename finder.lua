-- Configuration
local Config = {
    EnableDiscord = true,
    DiscordWebhook = "", -- Add your webhook here
    StopOnDetection = false,
    ConsolePrint = true,
    AutoNeutralize = true,
    TrustedResources = {}
}

-- Color utility function
local function colorText(text, color)
    local colors = {
        red = "^1",
        green = "^2",
        yellow = "^3",
        blue = "^4",
        lightblue = "^5",
        purple = "^6",
        white = "^7"
    }
    return (colors[color] or "^7") .. text .. "^7"
end

print(colorText([[
████████╗██╗  ██╗███████╗    ███████╗███████╗███╗   ███╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔════╝████╗ ████║
   ██║   ███████║█████╗      ███████╗█████╗  ██╔████╔██║
   ██║   ██╔══██║██╔══╝      ╚════██║██╔══╝  ██║╚██╔╝██║
   ██║   ██║  ██║███████╗    ███████║███████╗██║ ╚═╝ ██║
   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚══════╝╚══════╝╚═╝     ╚═╝
                Backdoor Finder v1.1
]], "red"))

-- Add new patterns and ignore lists
local suspicious_patterns = {
    "http://", "https://",
    "curl", "wget",
    "LoadResourceFile",
    "SaveResourceFile",
    "ExecuteCommand",
    "_G",
    "execute",
    "msec",
    "cipher",
    "payload",
    "backdoor",
    "inject",
    "hook",
    "exploit",
    "PerformHttpRequest",
    "cipher-panel",
    "Enchanced_Tabs",
    "helperServer",
    "ketamin.cc",
    "GetConvar",
    "txAdmin",
    -- Add encoded patterns
    "\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65",
    "\x6b\x65\x74\x61\x6d\x69\x6e\x2e\x63\x63",
    "MpWxwQeLMRJaDFLKmxVIFNeVfzVKaTBiVRvjBoePYciqfpJzxjNPIXedbOtvIbpDxqdoJR"
}

local ignore_patterns = {
    "discord.com/api/webhooks",
    "cdn.discordapp.com/attachments"
}

local ignore_folders = {
    "bob74_ipl"
}

-- Add hex pattern detection
local function isHexPattern(str)
    local hexCount = 0
    for hex in str:gmatch("'%x%x'%s*,?%s*") do
        hexCount = hexCount + 1
        if hexCount >= 10 then
            return true
        end
    end
    return false
end

-- Add long string detection
local function isLongString(str)
    local longString = str:match("[%w%d]{50,}")
    return longString ~= nil
end

-- Add base64 detection
local function isBase64(str)
    return str:match("^[A-Za-z0-9+/]+=*$") and #str > 40
end

local function scanFile(path)
    local file = io.open(path, "r")
    if not file then return false end
    
    local findings = {}
    local lineNum = 0
    
    for line in file:lines() do
        lineNum = lineNum + 1
        
        -- Skip ignored patterns
        local skip = false
        for _, ignore in ipairs(ignore_patterns) do
            if line:find(ignore) then
                skip = true
                break
            end
        end
        
        if not skip then
            -- Check suspicious patterns
            for _, pattern in ipairs(suspicious_patterns) do
                if line:find(pattern) then
                    table.insert(findings, {line = lineNum, content = line:gsub("^%s*(.-)%s*$", "%1"), pattern = pattern})
                end
            end
            
            -- Check hex patterns, long strings, and base64
            if isHexPattern(line) or isLongString(line) or isBase64(line) then
                table.insert(findings, {line = lineNum, content = line:gsub("^%s*(.-)%s*$", "%1"), pattern = "SUSPICIOUS_ENCODING"})
            end
        end
    end
    
    file:close()
    return #findings > 0, findings
end

local function scanDirectory(path)
    local items = {}
    local handle = io.popen('dir "'..path..'" /b /s')
    if not handle then return {} end
    
    for file in handle:lines() do
        if file:match("%.lua$") then
            table.insert(items, file)
        end
    end
    handle:close()
    return items
end

local function writeResults(results)
    local file = io.open("results.txt", "w")
    if not file then
        print("^1Error: Cannot create results file^0")
        return
    end
    
    for _, result in ipairs(results) do
        file:write(string.format("File: %s\n", result.file))
        for _, finding in ipairs(result.findings) do
            file:write(string.format("Line %d: [%s] %s\n", finding.line, finding.pattern, finding.content))
        end
        file:write("\n")
    end
    
    file:close()
    print("^2Results written to results.txt^0")
end

-- Function to send Discord webhook
local function sendToDiscord(findings)
    if not Config.EnableDiscord or Config.DiscordWebhook == "" then return end
    
    local description = "**Backdoor Scan Results**\n\n"
    for _, result in ipairs(findings) do
        description = description .. string.format("**File:** %s\n**Line %d:** %s\n\n", 
            result.file, result.line, result.content)
    end

    local payload = {
        username = "The Sem's Backdoor Finder",
        embeds = {{
            title = "Potential Backdoors Detected",
            description = description,
            color = 16711680,
            footer = {text = "Created by The Sem"}
        }}
    }

    -- Add PerformHttpRequest implementation for FiveM servers
    -- or use io.popen for standalone usage
end

-- Add cipher panel signatures
local cipher_signatures = {
    "cipher%-panel",
    "cipher%-menu",
    "cipher%-loader",
    "cipher%-inject",
    "cipher%-execute",
    "%x%x%x%x%x%x%.lua", -- Detect random hex named files
    "cipher%-admin",
    "cipher%-backend"
}

-- Add injection detection patterns
local injection_patterns = {
    "RegisterServerEvent",
    "TriggerServerEvent",
    "RegisterNetEvent",
    "AddEventHandler",
    "_G%[",
    "assert%(load",
    "load%(",
    "dump%(",
    "dynamic_execute",
    "dynamic_load"
}

-- Add real-time monitoring function
local function startRealtimeMonitoring()
    print(colorText("[MONITOR] Starting real-time defense system...", "blue"))
    
    -- Monitor new resource starts
    AddEventHandler('onResourceStart', function(resourceName)
        local suspicious, findings = scanResource(resourceName)
        if suspicious then
            print(colorText("[ALERT] Suspicious activity detected in resource: " .. resourceName, "red"))
            if Config.StopOnDetection then
                CancelEvent()
                print(colorText("[PROTECTION] Blocked resource from starting: " .. resourceName, "yellow"))
            end
        end
    end)
    
    -- Monitor resource stops (potential reload attacks)
    AddEventHandler('onResourceStop', function(resourceName)
        if not Config.TrustedResources[resourceName] then
            print(colorText("[WARNING] Resource stopped: " .. resourceName, "yellow"))
        end
    end)
end

-- Add enhanced resource scanner
local function scanResource(resourceName)
    local findings = {}
    
    -- Check for cipher panels
    for _, pattern in ipairs(cipher_signatures) do
        local files = scanDirectoryForPattern("./resources/" .. resourceName, pattern)
        if #files > 0 then
            table.insert(findings, {
                type = "CIPHER_PANEL",
                files = files,
                pattern = pattern
            })
        end
    end
    
    -- Check for script injections
    for _, pattern in ipairs(injection_patterns) do
        local files = scanDirectoryForPattern("./resources/" .. resourceName, pattern)
        if #files > 0 then
            table.insert(findings, {
                type = "INJECTION",
                files = files,
                pattern = pattern
            })
        end
    end
    
    return #findings > 0, findings
end

-- Add neutralization function
local function neutralizeThreats(findings)
    for _, finding in ipairs(findings) do
        if finding.type == "CIPHER_PANEL" then
            for _, file in ipairs(finding.files) do
                -- Backup file
                os.rename(file, file .. ".suspicious")
                print(colorText("[PROTECTION] Neutralized cipher panel: " .. file, "green"))
            end
        elseif finding.type == "INJECTION" then
            -- Log injection attempt
            writeResults({{
                file = finding.files[1],
                findings = {{
                    line = 0,
                    content = "Script injection attempted",
                    pattern = finding.pattern
                }}
            }})
        end
    end
end

-- Update main scanning logic
local function main()
    print(colorText("Starting backdoor scan...", "green"))
    local resources = scanDirectory("./resources")
    local suspicious_count = 0
    local all_results = {}
    
    for _, file in ipairs(resources) do
        -- Skip ignored folders
        local skip = false
        for _, ignore in ipairs(ignore_folders) do
            if file:find(ignore) then
                skip = true
                break
            end
        end
        
        if not skip then
            local suspicious, findings = scanFile(file)
            if suspicious then
                suspicious_count = suspicious_count + 1
                table.insert(all_results, {file = file, findings = findings})
                print(colorText("[SUSPICIOUS] " .. file, "red"))
                for _, finding in ipairs(findings) do
                    print(string.format(colorText("Line %d: [%s] %s", "yellow"), finding.line, finding.pattern, finding.content))
                end
                
                -- Neutralize threats if enabled
                if Config.AutoNeutralize then
                    neutralizeThreats(findings)
                end
            end
        end
    end
    
    writeResults(all_results)
    print(string.format(colorText("\nScan complete! Found %d suspicious files", "green"), suspicious_count))
    print(colorText("Created by The Sem", "lightblue"))
    
    -- Add Discord notification
    if #all_results > 0 then
        sendToDiscord(all_results)
        if Config.StopOnDetection then
            print(colorText("Backdoors detected! Stopping server...", "red"))
            os.exit()
        end
    end
    
    -- Start real-time monitoring
    startRealtimeMonitoring()
end

-- Start the enhanced protection system
main()
