-- Magnet Helis
-- Made By Dynasty

-- Auto Updater from https://github.com/hexarobi/stand-lua-auto-updater
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
    switch_to_branch=selected_branch,
    verify_file_begins_with="--",
}

auto_updater.run_auto_update(auto_update_config)

-- Auto Updater Ends Here!

util.require_natives(1627063482)

local SKYLIFT_MODEL = util.joaat("skylift")
local CARGOBOB_MODEL = util.joaat("cargobob")

local currentCargobob = nil
local currentSkylift = nil

local attachedVehicle = nil
local skyliftMagnetEnabled = false

local spawnedVehicles = {}

local function PlayerPedId()
    return PLAYER.PLAYER_PED_ID()
end

-- Cargobob

function spawn_cargobob_with_magnet()
    STREAMING.REQUEST_MODEL(CARGOBOB_MODEL)
    local playerPos = ENTITY.GET_ENTITY_COORDS(PlayerPedId(), true)
    local heading = ENTITY.GET_ENTITY_HEADING(PlayerPedId())
    local spawnPos = { x = playerPos.x, y = playerPos.y, z = playerPos.z + 5.0 }
    if currentCargobob and ENTITY.DOES_ENTITY_EXIST(currentCargobob) then
        entities.delete_by_handle(currentCargobob)
    end
    local cargobob = entities.create_vehicle(CARGOBOB_MODEL, spawnPos, heading)
    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(cargobob, 1.0)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(cargobob)
    VEHICLE.CREATE_PICK_UP_ROPE_FOR_CARGOBOB(cargobob, 1)
    currentCargobob = cargobob
    local playerPed = PlayerPedId()
    PED.SET_PED_INTO_VEHICLE(playerPed, cargobob, -1)
    table.insert(spawnedVehicles, cargobob)
    return cargobob
end

function remove_cargobob()
    if currentCargobob and ENTITY.DOES_ENTITY_EXIST(currentCargobob) then
        entities.delete_by_handle(currentCargobob)
    end
end

-- Skylift

function spawn_skylift()
    STREAMING.REQUEST_MODEL(SKYLIFT_MODEL)
    local playerPed = PlayerPedId()
    local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    local heading = ENTITY.GET_ENTITY_HEADING(playerPed)
    local spawnPos = { x = playerPos.x, y = playerPos.y, z = playerPos.z + 5.0 }
    if currentSkylift and ENTITY.DOES_ENTITY_EXIST(currentSkylift) then
        entities.delete_by_handle(currentSkylift)
    end
    local skylift = entities.create_vehicle(SKYLIFT_MODEL, spawnPos, heading)
    VEHICLE.SET_HELI_BLADES_FULL_SPEED(skylift)
    currentSkylift = skylift
    PED.SET_PED_INTO_VEHICLE(playerPed, skylift, -1)
    table.insert(spawnedVehicles, skylift)
    return skylift
end

function remove_skylift()
    if currentSkylift and ENTITY.DOES_ENTITY_EXIST(currentSkylift) then
        entities.delete_by_handle(currentSkylift)
    end
end

function attach_vehicle_to_skylift()
    if currentSkylift and ENTITY.DOES_ENTITY_EXIST(currentSkylift) then
        local skyliftPos = ENTITY.GET_ENTITY_COORDS(currentSkylift, true)
        local radius = 50.0
        local vehicle = VEHICLE.GET_CLOSEST_VEHICLE(skyliftPos.x, skyliftPos.y, skyliftPos.z, radius, 0, 70)
        if vehicle ~= 0 then
            ENTITY.ATTACH_ENTITY_TO_ENTITY(vehicle, currentSkylift, 0, 0.0, -3.5, -2.0, 0.0, 0.0, 0.0, true, true, true, false, 0, true)
            if ENTITY.IS_ENTITY_ATTACHED(vehicle) then
                attachedVehicle = vehicle
            end
        end
    end
end

function detach_vehicle_from_skylift(vehicle)
    if ENTITY.IS_ENTITY_ATTACHED(vehicle) then
        ENTITY.DETACH_ENTITY(vehicle, true, true)
    end
end

-- Remove all

function remove_all_vehicles()
    for i, vehicle in ipairs(spawnedVehicles) do
        if ENTITY.DOES_ENTITY_EXIST(vehicle) then
            entities.delete_by_handle(vehicle)
        end
        spawnedVehicles[i] = nil
    end
end

-- Menus

local cargobobMenu = menu.list(menu.my_root(), "Cargobob", {})
menu.action(cargobobMenu, "Spawn Cargobob", {}, "Spawn a cargobob with magnet and set player as pilot", function()
    currentCargobob = spawn_cargobob_with_magnet()
end)

menu.action(cargobobMenu, "Remove Cargobob", {}, "Remove the current Cargobob", function()
    remove_cargobob()
end)

local skyliftMenu = menu.list(menu.my_root(), "Skylift", {})
menu.action(skyliftMenu, "Spawn Skylift", {}, "Spawn a skylift and set player as pilot", function()
    spawn_skylift()
end)

menu.action(skyliftMenu, "Remove Skylift", {}, "Remove the current Skylift", function()
    remove_skylift()
end)

menu.action(skyliftMenu, "Attach/Detach", {}, "Attach the closest vehicle to the Skylift, or detach the currently attached vehicle from the Skylift", function()
    if attachedVehicle then
        detach_vehicle_from_skylift(attachedVehicle)
        attachedVehicle = nil
    else
        attach_vehicle_to_skylift()
    end
end)

menu.action(menu.my_root(), "Clear spawned helis", {}, "Removes both, cargobob and skylift", function()
    remove_all_vehicles()
end)

-- Manually check for updates with a menu option
menu.action(menu.my_root(), "Check for Update", {}, "The script will automatically check for updates at most daily, but you can manually check using this option anytime.", function()
    auto_update_config.check_interval = 0
    util.toast("Checking for updates")
    auto_updater.run_auto_update(auto_update_config)
end)