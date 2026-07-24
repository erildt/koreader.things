-- 2-custom-center-gestures.lua
--
-- Adds fourteen assignable gestures to KOReader's Gesture manager:
--   * Tap: top center / bottom center
--   * Long-press: top center / bottom center
--   * Tap / long-press: screen center
--   * One-finger swipe: top center to screen center
--   * Two-finger swipe: top center to screen center
--   * One-finger swipe: bottom center to screen center
--   * Two-finger swipe: bottom center to screen center
--   * One-finger swipe: screen center to top center / bottom center
--   * Two-finger swipe: screen center to top center / bottom center
--
-- INSTALLATION:
--   Copy this file into koreader/patches/2-custom-center-gestures.lua,
--   then restart KOReader.
--
-- The gestures are deliberately unassigned by default. Configure them under:
--   Gesture manager > Center gestures

local Dispatcher = require("dispatcher")
local Event = require("ui/event")
local PluginLoader = require("pluginloader")
local _ = require("gettext")

local GESTURE_GROUPS = {
    {
        title = _("Taps"),
        items = {
            "tap_top_center",
            "tap_center",
            "tap_bottom_center",
        },
    },
    {
        title = _("Long-presses"),
        items = {
            "hold_top_center",
            "hold_center",
            "hold_bottom_center",
        },
    },
    {
        title = _("One-finger swipes"),
        items = {
            "one_finger_swipe_top_to_center",
            "one_finger_swipe_center_to_top",
            "one_finger_swipe_bottom_to_center",
            "one_finger_swipe_center_to_bottom",
        },
    },
    {
        title = _("Two-finger swipes"),
        multitouch = true,
        items = {
            "two_finger_swipe_top_to_center",
            "two_finger_swipe_center_to_top",
            "two_finger_swipe_bottom_to_center",
            "two_finger_swipe_center_to_bottom",
        },
    },
}

local GESTURE_TITLES = {
    tap_top_center = _("Tap top center"),
    tap_bottom_center = _("Tap bottom center"),
    tap_center = _("Tap center"),
    hold_top_center = _("Long-press top center"),
    hold_bottom_center = _("Long-press bottom center"),
    hold_center = _("Long-press center"),
    one_finger_swipe_top_to_center = _("One-finger swipe: top to center"),
    two_finger_swipe_top_to_center = _("Two-finger swipe: top to center"),
    one_finger_swipe_bottom_to_center = _("One-finger swipe: bottom to center"),
    two_finger_swipe_bottom_to_center = _("Two-finger swipe: bottom to center"),
    one_finger_swipe_center_to_top = _("One-finger swipe: center to top"),
    two_finger_swipe_center_to_top = _("Two-finger swipe: center to top"),
    one_finger_swipe_center_to_bottom = _("One-finger swipe: center to bottom"),
    two_finger_swipe_center_to_bottom = _("Two-finger swipe: center to bottom"),
}

-- Ratios are relative to the current screen orientation.
local TOP_CENTER = {
    ratio_x = 0.25, ratio_y = 0.00,
    ratio_w = 0.50, ratio_h = 0.18,
}
local BOTTOM_CENTER = {
    ratio_x = 0.25, ratio_y = 0.82,
    ratio_w = 0.50, ratio_h = 0.18,
}
local SCREEN_CENTER = {
    ratio_x = 0.20, ratio_y = 0.35,
    ratio_w = 0.60, ratio_h = 0.30,
}

local function ends_in_zone(gesture, zone)
    local end_pos = gesture.end_pos
    if not end_pos then return false end

    local Screen = require("device").screen
    local width, height = Screen:getWidth(), Screen:getHeight()
    return end_pos.x >= width * zone.ratio_x
        and end_pos.x <= width * (zone.ratio_x + zone.ratio_w)
        and end_pos.y >= height * zone.ratio_y
        and end_pos.y <= height * (zone.ratio_y + zone.ratio_h)
end

-- Execute a configured action without KOReader's "Ignore hold on corners"
-- preference suppressing these center long-presses.
local function execute_action(self, name, gesture)
    local action_list = self.gestures[name]
    if action_list == nil then return end

    self.ui:handleEvent(Event:new("HandledAsSwipe"))
    local exec_props = { gesture = gesture }
    if action_list.settings and action_list.settings.anchor_quickmenu then
        exec_props.qm_anchor = gesture.end_pos or gesture.pos
    end
    Dispatcher:execute(action_list, exec_props)
    return true
end

local function common_overrides(self, gesture_type, bottom)
    if gesture_type == "tap" then
        if self.is_docless then
            return { "filemanager_ext_tap", "filemanager_tap" }
        end
        if bottom then
            return { "readerfooter_tap", "tap_forward", "tap_backward" }
        end
        return {
            "readerconfigmenu_ext_tap", "readerconfigmenu_tap",
            "readermenu_ext_tap", "readermenu_tap",
            "tap_forward", "tap_backward",
        }
    elseif gesture_type == "hold" then
        if self.is_docless then return nil end
        return bottom
            and { "readerfooter_hold", "readerhighlight_hold" }
            or { "readerhighlight_hold", "readerfooter_hold" }
    elseif gesture_type == "swipe" then
        if self.is_docless then
            return { "filemanager_ext_swipe", "filemanager_swipe" }
        end
        return {
            "readerconfigmenu_ext_swipe", "readerconfigmenu_swipe",
            "readermenu_ext_swipe", "readermenu_swipe",
            "paging_swipe", "rolling_swipe",
        }
    end
end

local function register_zone(self, name, gesture_type, zone, overrides,
        expected_direction, endpoint_zone)
    self.ui:registerTouchZones({
        {
            id = name,
            ges = gesture_type,
            screen_zone = zone,
            overrides = overrides,
            handler = function(gesture)
                if expected_direction then
                    if gesture.direction ~= expected_direction
                            or not ends_in_zone(gesture, endpoint_zone) then
                        return
                    end
                end
                return execute_action(self, name, gesture)
            end,
        },
    })
end

local function install(Gestures)
    if Gestures._custom_center_gestures_installed then return end
    Gestures._custom_center_gestures_installed = true

    -- Add the new touch zones whenever the Gesture plugin initializes.
    local original_initGesture = Gestures.initGesture
    function Gestures:initGesture(...)
        original_initGesture(self, ...)

        register_zone(self, "tap_top_center", "tap", TOP_CENTER,
            common_overrides(self, "tap", false))
        register_zone(self, "tap_bottom_center", "tap", BOTTOM_CENTER,
            common_overrides(self, "tap", true))
        register_zone(self, "tap_center", "tap", SCREEN_CENTER,
            common_overrides(self, "tap", false))
        register_zone(self, "hold_top_center", "hold", TOP_CENTER,
            common_overrides(self, "hold", false))
        register_zone(self, "hold_bottom_center", "hold", BOTTOM_CENTER,
            common_overrides(self, "hold", true))
        register_zone(self, "hold_center", "hold", SCREEN_CENTER,
            common_overrides(self, "hold", false))
        register_zone(self, "one_finger_swipe_top_to_center", "swipe", TOP_CENTER,
            common_overrides(self, "swipe", false), "south", SCREEN_CENTER)
        register_zone(self, "one_finger_swipe_bottom_to_center", "swipe", BOTTOM_CENTER,
            common_overrides(self, "swipe", true), "north", SCREEN_CENTER)
        register_zone(self, "one_finger_swipe_center_to_top", "swipe", SCREEN_CENTER,
            common_overrides(self, "swipe", false), "north", TOP_CENTER)
        register_zone(self, "one_finger_swipe_center_to_bottom", "swipe", SCREEN_CENTER,
            common_overrides(self, "swipe", true), "south", BOTTOM_CENTER)

        if self.has_multitouch then
            register_zone(self, "two_finger_swipe_top_to_center",
                "two_finger_swipe", TOP_CENTER,
                { "two_finger_swipe_south" }, "south", SCREEN_CENTER)
            register_zone(self, "two_finger_swipe_bottom_to_center",
                "two_finger_swipe", BOTTOM_CENTER,
                { "two_finger_swipe_north" }, "north", SCREEN_CENTER)
            register_zone(self, "two_finger_swipe_center_to_top",
                "two_finger_swipe", SCREEN_CENTER,
                { "two_finger_swipe_north" }, "north", TOP_CENTER)
            register_zone(self, "two_finger_swipe_center_to_bottom",
                "two_finger_swipe", SCREEN_CENTER,
                { "two_finger_swipe_south" }, "south", BOTTOM_CENTER)
        end
    end

    -- Give custom keys readable names in action/QuickMenu screens.
    local original_gestureTitleFunc = Gestures.gestureTitleFunc
    function Gestures:gestureTitleFunc(gesture)
        local title = GESTURE_TITLES[gesture]
        if title then
            return title .. " (" .. Dispatcher:menuTextFunc(self.gestures[gesture]) .. ")"
        end
        return original_gestureTitleFunc(self, gesture)
    end

    -- Add a dedicated section to the stock Gesture manager.
    local original_addToMainMenu = Gestures.addToMainMenu
    function Gestures:addToMainMenu(menu_items, ...)
        original_addToMainMenu(self, menu_items, ...)

        local manager = menu_items.gesture_manager
        if not manager or not manager.sub_item_table then return end

        local groups = {}
        for _, group in ipairs(GESTURE_GROUPS) do
            if not group.multitouch or self.has_multitouch then
                local items = {}
                for _, gesture in ipairs(group.items) do
                    table.insert(items, self:genSubItem(gesture))
                end
                table.insert(groups, {
                    text = group.title,
                    sub_item_table = items,
                })
            end
        end

        table.insert(manager.sub_item_table, {
            text = _("Center gestures"),
            sub_item_table = groups,
        })
    end
end

-- Built-in plugins are loaded with dofile(), not require(), so patch the
-- actual Gesture class returned by PluginLoader before instances are created.
local original_loadPlugins = PluginLoader.loadPlugins
function PluginLoader:loadPlugins(...)
    local enabled_plugins, disabled_plugins = original_loadPlugins(self, ...)
    for _, plugin in ipairs(enabled_plugins) do
        if plugin.name == "gestures" then
            install(plugin)
            break
        end
    end
    return enabled_plugins, disabled_plugins
end
