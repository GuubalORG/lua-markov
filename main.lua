-- ALWAYS ADD NEW DATA TO "bigData" FOLDER (cd bigData), "cd .." to exit that folder
-- The model is trained every time you run it.

local Processor = {}
Processor.__index = Processor

function Processor.new(state_size)
    local self = setmetatable({}, Processor)
    self.model = {}
    self.state_size = state_size or 1
    return self
end

function Processor:train(prompt)
    local tokens = self:tokenize(prompt)
    if #tokens < self.state_size then return end

    for i = 1, #tokens - self.state_size do
        local key = table.concat({unpack(tokens, i, i + self.state_size - 1)}, "_")
        local next_token = tokens[i + self.state_size]
        self.model[key] = self.model[key] or {}
        table.insert(self.model[key], next_token)
    end
end

function Processor:tokenize(text)
    local tokens = {}
    for token in text:gmatch("[%w'%-]+|[.,!?;😝🤔😀😭👻]+") do
        table.insert(tokens, token:lower())
    end
    if #tokens == 0 then
        for token in text:gmatch("%S+") do
            table.insert(tokens, token:lower())
        end
    end
    return tokens
end

function Processor:generate(length, temperature, start_phrase)
    local keys = {}
    for k in pairs(self.model) do table.insert(keys, k) end
    
    if #keys == 0 then return "Brain empty! Feed me data." end
    
    local current_key
    if start_phrase then
        local search_key = start_phrase:lower():gsub(" ", "_")
        if self.model[search_key] then
            current_key = search_key
        end
    end
    
    current_key = current_key or keys[math.random(#keys)]
    local output = {}
    
    for word in current_key:gmatch("[^_]+") do
        table.insert(output, word)
    end
    
    for i = 1, length do
        local choices = self.model[current_key]
    
        if not choices or #choices == 0 or (temperature and math.random() < temperature) then
            current_key = keys[math.random(#keys)]
            choices = self.model[current_key]
        end
    
        local next_token = choices[math.random(#choices)]
        table.insert(output, next_token)
    
        if next_token:find("[.!?]") and i > 5 then break end
    
        local parts = {}
        for part in current_key:gmatch("[^_]+") do table.insert(parts, part) end
        table.remove(parts, 1)
        table.insert(parts, next_token)
        current_key = table.concat(parts, "_")
    
        if not self.model[current_key] then
            current_key = keys[math.random(#keys)]
        end
    end
    
    return table.concat(output, " ")
end

--------
math.randomseed(os.time())

local training_data = [[
    
]]

local function load_file(filename)
    local f = io.open(filename, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

local brain = Processor.new(1)

-- Training
brain:train(training_data)

local p = io.popen("ls bigData")
local fileList = p:read("*a")
p:close()

for filename in fileList:gmatch("[^\r\n]+") do
    local path = "bigData/" .. filename
    -- read
    local f = io.open(path, "r")
    if f then
        local data = f:read("*a")
        f:close()

        brain:train(data)
        print("Trained on:", filename)
    else
        print("Could not open:", filename)
    end
end

print(brain:generate(90, 0.2))

local utils = { -- custom  commands
    ["time"] = function()
        return "The current time is " .. os.date("%H:%M:%S")
    end,
    ["date"] = function()
        return "Today is " .. os.date("%A, %B %d, %Y")
    end,
    ["random"] = function()
        return "Your lucky number is " .. math.random(1, 100)
    end,
    ["uptime"] = function()
        return "I've been running since " .. os.date("%H:%M", os.time() - os.clock())
    end,
    ["mood"] = function()
        local emojis = {"😝", "🤔", "😀", "😭", "👻"}
        return "Current status: " .. emojis[math.random(#emojis)] .. " (The loop is eternal)"
    end
}

local function handle_utilities(input)
    local low_input = input:lower()

    for keyword, tool_func in pairs(utils) do
        if low_input:find(keyword) then
        end
    end

    return nil
end

print("--- BOT INITIALIZED ---")
print("Type something to start chatting (type 'exit' to stop)")

while true do
    io.write("You: ")
    local input = io.read()
    
    if not input or input == "exit" then break end
    
    local utility_response = handle_utilities(input)
    
    if utility_response then
        print("\nBot [System]: " .. utility_response .. "\n")
    else
        local user_tokens = brain:tokenize(input)
        local seed = nil
    
        if #user_tokens >= 1 then
            local potential_seeds = {}
            for k in pairs(brain.model) do
                if k:find("^" .. user_tokens[1]) then
                    table.insert(potential_seeds, k)
                end
            end
            if #potential_seeds > 0 then
                seed = potential_seeds[math.random(#potential_seeds)]
            end
        end
    
        local response = brain:generate(20, 0.3, seed)
    
        local final_text = response:sub(1,1):upper() .. response:sub(2)
        if not final_text:find("[.!?]$") then final_text = final_text .. "." end
    
        print("\nBot [Dante Ballast 1.1]: " .. final_text .. "\n")
    end
    
    -- so he matches the user's style somewhat
    brain:train(input)
end
