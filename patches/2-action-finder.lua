-- 2-action-finder.lua
--
-- Adds action search to KOReader's Dispatcher menus, including the action
-- chooser opened from Gesture manager.
--
-- INSTALLATION:
--   Copy this file into koreader/patches/2-action-finder.lua,
--   then restart KOReader.

local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local Utf8Proc = require("ffi/utf8proc")
local _ = require("gettext")
local T = require("ffi/util").template

if not Dispatcher._action_finder_installed then
    Dispatcher._action_finder_installed = true

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
        for _, match in ipairs(matches) do
            local result = {}
            for key, value in pairs(match.action) do
                result[key] = value
            end
            result.text = match.title .. "  ·  " .. match.section
            result.text_func = nil
            table.insert(result_items, result)
        end

        table.insert(touchmenu.item_table_stack, touchmenu.item_table)
        touchmenu.parent_id = "action_finder_search"
        touchmenu.item_table = result_items
        touchmenu:updateItems(1)
    end

    local function show_search_dialog(touchmenu, sections)
        local search_dialog
        search_dialog = InputDialog:new{
            title = _("Search actions"),
            description = _("Find an action by name (case insensitive)."),
            input = G_reader_settings:readSetting("action_finder_search", ""),
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
                            G_reader_settings:saveSetting("action_finder_search", query)
                            UIManager:close(search_dialog)
                            UIManager:nextTick(function()
                                show_results(touchmenu, sections, query)
                            end)
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
                menu_item_id = "action_finder_search",
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
