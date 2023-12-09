-- Magnet Helis
-- Made By Dynasty

-- [[Auto Updater from https://github.com/hexarobi/stand-lua-auto-updater
local status, auto_updater = pcall(require, "auto-updater")
if not status then
    local auto_update_complete = nil util.toast("Installing auto-updater...", TOAST_ALL)
    async_http.init("raw.githubusercontent.com", "/hexarobi/stand-lua-auto-updater/main/auto-updater.lua",
        function(result, headers, status_code)
            local function parse_auto_update_result(result, headers, status_code)
                local error_prefix = "Error downloading auto-updater: "
                if status_code ~= 200 then util.toast(error_prefix..status_code, TOAST_ALL) return false end
                if not result or result == "" then util.toast(error_prefix.."Found empty file.", TOAST_ALL) return false end
                filesystem.mkdir(filesystem.scripts_dir() .. "lib")
                local file = io.open(filesystem.scripts_dir() .. "lib\\auto-updater.lua", "wb")
                if file == nil then util.toast(error_prefix.."Could not open file for writing.", TOAST_ALL) return false end
                file:write(result) file:close() util.toast("Successfully installed auto-updater lib", TOAST_ALL) return true
            end
            auto_update_complete = parse_auto_update_result(result, headers, status_code)
        end, function() util.toast("Error downloading auto-updater lib. Update failed to download.", TOAST_ALL) end)
    async_http.dispatch() local i = 1 while (auto_update_complete == nil and i < 40) do util.yield(250) i = i + 1 end
    if auto_update_complete == nil then error("Error downloading auto-updater lib. HTTP Request timeout") end
    auto_updater = require("auto-updater")
end
if auto_updater == true then error("Invalid auto-updater lib. Please delete your Stand/Lua Scripts/lib/auto-updater.lua and try again") end

local auto_update_config = {
    source_url="https://raw.githubusercontent.com/DynastySheep/Magnet-Helis/main/MagnetHelis.lua",
    script_relpath=SCRIPT_RELPATH,
}

auto_updater.run_auto_update(auto_update_config)

-- Auto Updater Ends Here!

util.require_natives("2944b.g")

local playerPed = players.user_ped()

local SKYLIFT_MODEL = util.joaat("skylift")
local CARGOBOB_MODEL = util.joaat("cargobob")

local spawnedVehicles = {
    Cargobob = nil,
    Skylift = nil
}

local liftMode = 0

local attachedVehicle = nil
local skyliftMagnetEnabled = false

--! Helpers
function StreamModel(selectedModel)
    util.request_model(selectedModel, 2000)
end

function GetPlayerPosition()
    playerPos = GET_ENTITY_COORDS(playerPed)
    playerHeading = GET_ENTITY_HEADING(playerPed)
    return playerPos, playerHeading
end

function CheckForVehicle(vehicleName)
    local currentCargobob = spawnedVehicles[vehicleName]

    if currentCargobob and DOES_ENTITY_EXIST(currentCargobob) then
        entities.delete_by_handle(currentCargobob)
        spawnedVehicles[vehicleName] = nil
    end
end

function GetPlayerVehicle(modelHash, notifyMessage)
    local currentVehicle = GET_VEHICLE_PED_IS_IN(playerPed, false)
    local vehicleHash = GET_ENTITY_MODEL(currentVehicle)

    if vehicleHash ~= modelHash then
        util.toast(notifyMessage)
        menu.set_value(toggleCargobobPickup, false)
        return false
    end
    return true
end

--! Main
function SpawnVehicle(vehicleName, modelHash)
    CheckForVehicle(vehicleName)
    StreamModel(modelHash)

    local playerPos, playerHeading = GetPlayerPosition()
    local spawnVehicle = entities.create_vehicle(modelHash, playerPos, playerHeading)

    SET_HELI_BLADES_FULL_SPEED(spawnVehicle)
    SET_PED_INTO_VEHICLE(playerPed, spawnVehicle, -1)

    spawnedVehicles[vehicleName] = spawnVehicle
end

function TogglePickupMode(isAttaching)
    local vehicleMatch = GetPlayerVehicle(CARGOBOB_MODEL, "Only works in cargobob")
    if not vehicleMatch then
        return
    end

    if isAttaching then
        CREATE_PICK_UP_ROPE_FOR_CARGOBOB(spawnedVehicles.Cargobob, liftMode)
    else
        REMOVE_PICK_UP_ROPE_FOR_CARGOBOB(spawnedVehicles.Cargobob)
    end
end

local function TryGainControl(target)
    if not NETWORK_HAS_CONTROL_OF_ENTITY(target) and util.is_session_started() then

        local netid = NETWORK_GET_NETWORK_ID_FROM_ENTITY(target)
        SET_NETWORK_ID_CAN_MIGRATE(netid, true)

        local st_time = os.time()
        while not NETWORK_HAS_CONTROL_OF_ENTITY(target) do
            -- intentionally silently fail, otherwise we are gonna spam the everloving shit out of the user
            if os.time() - st_time >= 5 then
                ls_log("Failed to request entity control in 5 seconds (entity " .. target .. ")")
                break
            end
            NETWORK_REQUEST_CONTROL_OF_ENTITY(target)
            util.yield()
        end
    end
end

function SkyliftToggle(attach)
    if not attach then
        if attachedVehicle and IS_ENTITY_ATTACHED(attachedVehicle) then
            DETACH_ENTITY(attachedVehicle, true, true)
            attachedVehicle = nil
        end
        return
    end

    local vehicleMatch = GetPlayerVehicle(SKYLIFT_MODEL, "Only works in skylift")
    if not vehicleMatch then
        return
    end

    local currentSkylift = spawnedVehicles.Skylift
    local skyliftPos = GET_ENTITY_COORDS(currentSkylift)
    local radius = 10.0

    local targetVehicle = GET_CLOSEST_VEHICLE(v3(skyliftPos), radius, 0, 70)
    if targetVehicle ~= 0 then
        TryGainControl(targetVehicle)
        if NETWORK_HAS_CONTROL_OF_ENTITY then
            ATTACH_ENTITY_TO_ENTITY(targetVehicle, currentSkylift, 0, 0.0, -3.5, -2.0, 0.0, 0.0, 0, true, true, true, false, 2, true, 0)

            if IS_ENTITY_ATTACHED(targetVehicle) then
                attachedVehicle = targetVehicle
            end
        end
    else
        util.toast("Pickup failed - you need to be above vehicle")
        menu.set_value(toggleSkyliftPickup, false)
    end
end

--! Removal Functions
function RemoveAllVehicles()
    for _, vehicle in pairs(spawnedVehicles) do
        if DOES_ENTITY_EXIST(vehicle) then
            entities.delete_by_handle(vehicle)
        end
    end
    spawnedVehicles = {}
end

function RemoveSpecificVehicle(vehicleName)
    entities.delete_by_handle(spawnedVehicles[vehicleName])
    spawnedVehicles[vehicleName] = nil
end

--! Menus
local cargobobMenu = menu.list(menu.my_root(), "Cargobob", {})
menu.action(cargobobMenu, "Spawn Cargobob", {}, "", function()
    SpawnVehicle("Cargobob", CARGOBOB_MODEL)
end)

menu.list_select(cargobobMenu, "Choose Pickup Mode", {}, "", {{0, "Hook"}, {1, "Magnet"}}, 0, function(value)
    liftMode = value
    SpawnVehicle("Cargobob", CARGOBOB_MODEL)
    menu.set_value(toggleCargobobPickup, false)
end)

toggleCargobobPickup = menu.toggle(cargobobMenu, "Toggle Pickup Mode", {}, "", function(isOn)
    TogglePickupMode(isOn)
end)

menu.action(cargobobMenu, "Remove Cargobob", {}, "", function()
    RemoveSpecificVehicle("Cargobob")
end)

local skyliftMenu = menu.list(menu.my_root(), "Skylift", {})
menu.action(skyliftMenu, "Spawn Skylift", {}, "", function()
    SpawnVehicle("Skylift", SKYLIFT_MODEL)
end)

toggleSkyliftPickup = menu.toggle(skyliftMenu, "Toggle Pickup Mode", {}, "This only works for NPC/Empty vehicles :(", function(isOn)
    SkyliftToggle(isOn)
end)

menu.action(skyliftMenu, "Remove Skylift", {}, "", function()
    RemoveSpecificVehicle("Skylift")
end)

menu.action(menu.my_root(), "Clear All", {}, "", function()
    RemoveAllVehicles()
end)

-- Manually check for updates with a menu option
menu.action(menu.my_root(), "Check for Update", {}, "The script will automatically check for updates at most daily, but you can manually check using this option anytime.", function()
    auto_update_config.check_interval = 0
    util.toast("Checking for updates")
    auto_updater.run_auto_update(auto_update_config)
end)

util.on_pre_stop(function()
    RemoveAllVehicles()
end)