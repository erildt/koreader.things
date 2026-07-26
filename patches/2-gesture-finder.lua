-- 2-gesture-finder.lua
--
-- Adds action search to KOReader's Dispatcher menus, including the action
-- chooser opened from Gesture manager.
--
-- INSTALLATION:
--   Copy this file into koreader/patches/2-gesture-finder.lua,
--   then restart KOReader.

local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local Menu = require("ui/widget/menu")
local UIManager = require("ui/uimanager")
local Utf8Proc = require("ffi/utf8proc")
local _ = require("gettext")
local T = require("ffi/util").template

if not Dispatcher._gesture_finder_installed then
    Dispatcher._gesture_finder_installed = true

    local original_addSubMenu = Dispatcher.addSubMenu

    local function item_text(item)
        return item.text_func and item.text_func() or item.text or ""
    end

    local function show_results(touchmenu, sections, query)
        local needle = Utf8Proc.lowercase(query)
        local matches = {}

        for _, section in ipairs(sections) do
            local section_name = item_text(section)
            for _, action in ipairs(section.sub_item_table or {}) do
                local title = item_text(action)
                if Utf8Proc.lowercase(title):find(needle, 1, true) then
                    table.insert(matches, {
                        action = action,
                        section = section_name,
                        title = title,
                    })
                end
            end
        end

        if #matches == 0 then
            UIManager:show(InfoMessage:new{
                text = T(_("No actions containing “%1” found."), query),
            })
            return
        end

        local result_items = {}
        local results_container
        for _, match in ipairs(matches) do
            local found = match
            table.insert(result_items, {
                text = found.title,
                mandatory = found.section,
                callback = function()
                    UIManager:close(results_container)
                    UIManager:nextTick(function()
                        touchmenu:onMenuSelect(found.action)
                    end)
                end,
            })
        end

        local results_menu = Menu:new{
            title = _("Search actions"),
            subtitle = T(_("%1 matches for “%2”"), #matches, query),
            item_table = result_items,
            width = math.floor(Device.screen:getWidth() * 0.9),
            height = math.floor(Device.screen:getHeight() * 0.9),
            single_line = true,
            items_per_page = 10,
            items_font_size = Menu.getItemFontSize(10),
            onMenuSelect = function(_, item)
                if item.callback then
                    item.callback()
                end
            end,
            close_callback = function()
                UIManager:close(results_container)
            end,
        }
        results_container = CenterContainer:new{
            dimen = Device.screen:getSize(),
            results_menu,
        }
        results_menu.show_parent = results_container
        UIManager:show(results_container)
    end

    local function show_search_dialog(touchmenu, sections)
        local search_dialog
        search_dialog = InputDialog:new{
            title = _("Search actions"),
            description = _("Find an action by name (case insensitive)."),
            input = G_reader_settings:readSetting("gesture_finder_search", ""),
            input_hint = _("Action name"),
            buttons = {
                {
                    {
                        text = _("Cancel"),
                        id = "close",
                        callback = function()
                            UIManager:close(search_dialog)
                        end,
                    },
                    {
                        text = _("Search"),
                        is_enter_default = true,
                        callback = function()
                            local query = search_dialog:getInputText()
                            G_reader_settings:saveSetting("gesture_finder_search", query)
                            UIManager:close(search_dialog)
                            show_results(touchmenu, sections, query)
                        end,
                    },
                },
            },
        }
        UIManager:show(search_dialog)
        search_dialog:onShowKeyboard()
    end

    function Dispatcher:addSubMenu(caller, menu, location, settings)
        local previous_count = #menu
        original_addSubMenu(self, caller, menu, location, settings)

        -- Dispatcher appends Nothing, followed by its seven action sections.
        local sections = {}
        for i = previous_count + 2, previous_count + 8 do
            if menu[i] and menu[i].sub_item_table then
                table.insert(sections, menu[i])
            end
        end

        if #sections > 0 then
            table.insert(menu, previous_count + 2, {
                text = _("Search actions"),
                keep_menu_open = true,
                callback = function(touchmenu)
                    show_search_dialog(touchmenu, sections)
                end,
                separator = true,
            })

            -- Keep Dispatcher's page break between action sections and settings.
            if menu.max_per_page then
                menu.max_per_page = menu.max_per_page + 1
            end
        end
    end
end
