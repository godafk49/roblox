--!strict
--[[
	SafeSceneSerializer.lua

	Safe Luau serializer/duplicator for Roblox experiences you own.
	Only serializes explicitly tagged Folder/Model/Part trees.

	Usage:
		local SafeSceneSerializer = require(script.SafeSceneSerializer)

		local root = workspace.MyMapChunk
		root:SetAttribute("SafeSceneSerializer.Allowed", true)

		local copy = SafeSceneSerializer.duplicateRoot(root, workspace, {
			batchSize = 200,
		})
]]

local HttpService = game:GetService("HttpService")

local SafeSceneSerializer = {}

local SCHEMA_VERSION = "SafeSceneSerializer/1"
local DEFAULT_BATCH_SIZE = 250
local REQUIRED_ROOT_ATTRIBUTE = "SafeSceneSerializer.Allowed"

local ALLOWED_CLASSES: { [string]: boolean } = {
	Folder = true,
	Model = true,
	Part = true,
}

local BASE_PART_FIELDS: { string } = {
	"Size",
	"Color",
	"Material",
	"Transparency",
	"Reflectance",
	"Anchored",
	"CanCollide",
	"CanTouch",
	"CastShadow",
}

local function encodeValue(value: any): any
	local valueType = typeof(value)

	if valueType == "number" or valueType == "string" or valueType == "boolean" then
		return value
	elseif valueType == "Vector3" then
		return {
			__type = "Vector3",
			x = value.X,
			y = value.Y,
			z = value.Z,
		}
	elseif valueType == "CFrame" then
		return {
			__type = "CFrame",
			components = { value:GetComponents() },
		}
	elseif valueType == "Color3" then
		return {
			__type = "Color3",
			r = value.R,
			g = value.G,
			b = value.B,
		}
	elseif valueType == "EnumItem" then
		return {
			__type = "Enum",
			enum = value.EnumType.Name,
			name = value.Name,
		}
	end

	return nil
end

local function decodeValue(value: any): any
	if typeof(value) ~= "table" then
		return value
	end

	local marker = value.__type

	if marker == "Vector3" then
		return Vector3.new(value.x or 0, value.y or 0, value.z or 0)
	elseif marker == "CFrame" then
		local components = value.components

		if typeof(components) == "table" then
			return CFrame.new(table.unpack(components))
		end

		return CFrame.new()
	elseif marker == "Color3" then
		return Color3.new(value.r or 0, value.g or 0, value.b or 0)
	elseif marker == "Enum" then
		local ok, enumValue = pcall(function()
			return Enum[value.enum][value.name]
		end)

		if ok then
			return enumValue
		end
	end

	return nil
end

local function shouldYield(counter: { count: number }, batchSize: number): boolean
	return counter.count % batchSize == 0
end

local function serializeAttributes(inst: Instance): { [string]: any }
	local result: { [string]: any } = {}

	for attributeName, attributeValue in pairs(inst:GetAttributes()) do
		local encoded = encodeValue(attributeValue)

		if encoded ~= nil then
			result[attributeName] = encoded
		end
	end

	return result
end

local function serializeInstance(
	inst: Instance,
	visited: { [Instance]: boolean },
	counter: { count: number },
	batchSize: number
): { [string]: any }?
	if visited[inst] then
		return nil
	end

	visited[inst] = true
	counter.count += 1

	if shouldYield(counter, batchSize) then
		task.wait()
	end

	if not ALLOWED_CLASSES[inst.ClassName] then
		return nil
	end

	local node: { [string]: any } = {
		ClassName = inst.ClassName,
		Name = inst.Name,
		Attributes = serializeAttributes(inst),
		Children = {},
	}

	if inst:IsA("BasePart") then
		node.CFrame = encodeValue(inst.CFrame)

		for _, field in ipairs(BASE_PART_FIELDS) do
			local ok, value = pcall(function()
				return inst[field]
			end)

			if ok then
				node[field] = encodeValue(value)
			end
		end
	end

	for _, child in ipairs(inst:GetChildren()) do
		local childNode = serializeInstance(child, visited, counter, batchSize)

		if childNode ~= nil then
			table.insert(node.Children, childNode)
		end
	end

	return node
end

function SafeSceneSerializer.serializeRoot(root: Instance, options: { batchSize: number? }?): string
	assert(typeof(root) == "Instance", "root must be an Instance")
	assert(root ~= game, "Do not serialize the full DataModel.")
	assert(root:IsA("Folder") or root:IsA("Model"), "root must be a Folder or Model you control.")

	if root:GetAttribute(REQUIRED_ROOT_ATTRIBUTE) ~= true then
		error(
			("Root must explicitly have %s = true before serialization."):format(REQUIRED_ROOT_ATTRIBUTE),
			2
		)
	end

	options = options or {}
	local batchSize = options.batchSize or DEFAULT_BATCH_SIZE

	local counter = { count = 0 }
	local visited: { [Instance]: boolean } = {}

	local tree = serializeInstance(root, visited, counter, batchSize)

	local payload = {
		schema = SCHEMA_VERSION,
		savedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		root = tree,
	}

	return HttpService:JSONEncode(payload)
end

local function applyAttributes(inst: Instance, attributes: { [string]: any }?): ()
	if typeof(attributes) ~= "table" then
		return
	end

	for attributeName, encodedValue in pairs(attributes) do
		local decodedValue = decodeValue(encodedValue)

		if decodedValue ~= nil then
			inst:SetAttribute(attributeName, decodedValue)
		end
	end
end

local function deserializeInstance(
	node: { [string]: any },
	parent: Instance,
	counter: { count: number },
	batchSize: number
): Instance?
	if typeof(node) ~= "table" then
		return nil
	end

	if not ALLOWED_CLASSES[node.ClassName] then
		return nil
	end

	counter.count += 1

	if shouldYield(counter, batchSize) then
		task.wait()
	end

	local inst = Instance.new(node.ClassName)
	inst.Name = node.Name or node.ClassName

	if inst:IsA("BasePart") then
		local cframe = decodeValue(node.CFrame)

		if typeof(cframe) == "CFrame" then
			inst.CFrame = cframe
		end

		for _, field in ipairs(BASE_PART_FIELDS) do
			local decodedValue = decodeValue(node[field])

			if decodedValue ~= nil then
				pcall(function()
					inst[field] = decodedValue
				end)
			end
		end
	end

	inst.Parent = parent
	applyAttributes(inst, node.Attributes)

	for _, childNode in ipairs(node.Children or {}) do
		deserializeInstance(childNode, inst, counter, batchSize)
	end

	return inst
end

function SafeSceneSerializer.deserializeRoot(
	json: string,
	parent: Instance,
	options: { batchSize: number? }?
): Instance?
	assert(typeof(json) == "string", "json must be a string")
	assert(typeof(parent) == "Instance", "parent must be an Instance")

	options = options or {}
	local batchSize = options.batchSize or DEFAULT_BATCH_SIZE

	local ok, payload = pcall(function()
		return HttpService:JSONDecode(json)
	end)

	if not ok or typeof(payload) ~= "table" then
		error("Invalid scene JSON.", 2)
	end

	if payload.schema ~= SCHEMA_VERSION then
		error("Unsupported scene schema.", 2)
	end

	local counter = { count = 0 }

	return deserializeInstance(payload.root, parent, counter, batchSize)
end

function SafeSceneSerializer.duplicateRoot(
	root: Instance,
	parent: Instance,
	options: { batchSize: number? }?
): Instance?
	local json = SafeSceneSerializer.serializeRoot(root, options)
	return SafeSceneSerializer.deserializeRoot(json, parent, options)
end

return SafeSceneSerializer
