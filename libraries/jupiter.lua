--write a (non-serial) table to a file. The filename should be a property of "data": data._fileName = "*.extn"
local jupiter = {saveDir = "save"}

function jupiter.save(data)
	assert(type(data) == "table", "Tables must be provided to saveFile!")
	if not love.filesystem.getInfo(jupiter.saveDir, 'directory') then
		assert(love.filesystem.createDirectory(jupiter.saveDir), "Unable to create save directory in " .. love.filesystem.getSaveDirectory() .. "!")
	end --make the save folder if required
	file = love.filesystem.newFile(data._fileName)
	file:open("w")

	local function serial(table, scope)
		scope = scope or ""
		for k, v in pairs(table) do
			if k ~= "_fileName" then
				if type(v) == "table" then
					print("GOT A TABLE SOMEHOW")
					if not scope:find('__index')  then
						serial(v, scope .. tostring(k) .. ".")
					end
				else
					print("THANKFULLY NOT A TABLE")
					x = file:write(scope .. k .. "=" .. tostring(v) .. "\n") --write value
					if not x then return nil end
				end
			end
		end
	end

	serial(data)

	return true
end

--load a file. If no specific file is given it returns the latest save file
function jupiter.load(name)
	if not love.filesystem.getInfo(jupiter.saveDir, 'directory') then
		assert(love.filesystem.createDirectory(jupiter.saveDir), "Unable to create save directory in " .. love.filesystem.getSaveDirectory() .. "!")
	end
	--load the latest save file if no file is given (useful for 'continue' option)
	if not name then
		local saveFiles = love.filesystem.getDirectoryItems(jupiter.saveDir)
		local orderedFiles = {}
		for k, file in ipairs(saveFiles) do
			--ignore files such as .DS_Store
			if not (file:sub(1, 1) == ".") and file:match("%.save$") then
				table.insert(orderedFiles, {f = file, t = love.filesystem.getLastModified(jupiter.saveDir .. "/" .. file) or 0})
			end
		end
		if #orderedFiles ~= 0 then
			--sort the files in modified order
			table.sort(orderedFiles, function(a, b) return a.t > b.t end)
			name = orderedFiles[1]
		end
	else
		--don't do anything if there are no saves
		if love.filesystem.getInfo(name, 'file') then
			print("it is a file")
			local saveFile = {} --data from the file
			local pointer
			--find tables
			local function deserial(value)
				pointer = saveFile
				local scope, dotCount = value:gsub("%.", "%1")
				for x = 1, dotCount do
					local element = scope:match("^(..-)%.") --get the leftmost index
					scope = scope:match("^" .. element .. "%.(.+)") --trim the current index for the next iteration
					element = tonumber(element) and tonumber(element) or element
					pointer[element] = not pointer[element] and {} or pointer[element] --create the table if needed
					pointer = pointer[element] --set the pointer to the current level
				end
				return scope
			end

			--load the data
			local i = 0
			for l in love.filesystem.lines(name) do
				if i < 100 then print(l) end
				local k, v = l:match("^(..-)=(.+)$")
				if k and v then
					local index = deserial(k)
					if v ~= "nil" and v ~= "false" then --ignore nil values that may have been set by the player
						index = tonumber(index) and tonumber(index) or index
						pointer[index] = tonumber(v) and tonumber(v) or v
					end
				end
				i = i + 1
			end
			saveFile._fileName = name
			return saveFile
		end
	end
end

return jupiter
