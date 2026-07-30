-- Show the current hierarchy in KOReader's top menus.
--
-- Based on koreader-menu-breadcrumbs by Khady:
-- https://github.com/Khady/koreader-menu-breadcrumbs
--
-- Install this file in koreader/patches and restart KOReader.
-- SPDX-License-Identifier: AGPL-3.0-or-later

local BD = require("ui/bidi")
local Button = require("ui/widget/button")
local InfoMessage = require("ui/widget/infomessage")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local TouchMenu = require("ui/widget/touchmenu")
local UIManager = require("ui/uimanager")

if TouchMenu._menu_breadcrumbs_patched then
    return
end
TouchMenu._menu_breadcrumbs_patched = true

local breadcrumb_face_name = "smallinfofont"
local breadcrumb_font_size = 18
local breadcrumb_separator = BD.mirroredUILayout() and "‹" or "›"

local BreadcrumbButton = Button:extend{}

function BreadcrumbButton:onTapSelectButton(_, ges)
    if not ges or not ges.pos then return true end

    -- Segment widths are only needed for hit-testing. Measure them lazily on
    -- the uncommon breadcrumb tap instead of slowing every submenu transition.
    if not self._natural_text_width then
        self._natural_text_width = 0
        for _, segment in ipairs(self._segments) do
            local probe = TextWidget:new{
                text = segment.text,
                face = self.label_widget.face,
            }
            segment.width = probe:getSize().w
            probe:free()
            self._natural_text_width =
                self._natural_text_width + segment.width
        end
    end

    -- The row is the original single full-width Button. Map the tap back to
    -- the corresponding part of its text without changing that layout.
    local content_width = self.width - 2 * self.padding_h
    local x = ges.pos.x - self.dimen.x - self.padding_h
    local text_x = x + math.max(0, self._natural_text_width - content_width)
    local right = 0
    for _, segment in ipairs(self._segments) do
        right = right + segment.width
        if text_x <= right then
            local levels = #self._labels - segment.depth
            if levels > 0 then
                -- Pop all intermediate levels without rebuilding each one.
                -- TouchMenu:backToUpperMenu() calls updateItems() on every
                -- pop, which makes direct breadcrumb jumps unnecessarily slow.
                for _ = 1, levels do
                    self._menu.item_table =
                        table.remove(self._menu.item_table_stack)
                    table.remove(self._menu._breadcrumb_labels)
                end
                if self._menu.item_table.needs_refresh
                        and self._menu.item_table.refresh_func then
                    self._menu.item_table =
                        self._menu.item_table.refresh_func()
                end
                self._menu.parent_id = nil
                self._menu:updateItems(1)
            end
            break
        end
    end
    return true
end

function BreadcrumbButton:onHoldSelectButton()
    UIManager:show(InfoMessage:new{
        text = self.text,
        show_icon = false,
    })
    self._hold_handled = true
    return true
end

local function menuItemText(item)
    local text = item.text_func and item.text_func() or item.text
    if text == nil then
        return
    end
    return tostring(text):gsub("\n", " ")
end

local function joinLabels(labels)
    local parts = {}
    local previous
    for _, label in ipairs(labels) do
        if label ~= "" and label ~= previous then
            if #parts > 0 then
                table.insert(parts, BD.wrap(" " .. breadcrumb_separator .. " "))
            end
            table.insert(parts, BD.auto(label))
            previous = label
        end
    end
    return table.concat(parts)
end

local function makeBreadcrumbRow(menu, labels)
    local full_path = joinLabels(labels)
    local button = BreadcrumbButton:new{
        text = full_path,
        width = menu.item_width,
        align = "left",
        bordersize = 0,
        padding_h = Size.padding.small,
        padding_v = Size.padding.small,
        text_font_face = breadcrumb_face_name,
        text_font_size = breadcrumb_font_size,
        text_font_bold = false,
        avoid_text_truncation = false,
        show_parent = menu.show_parent,
    }
    -- Button defaults to an opaque white fill. Keep the original row geometry
    -- but let the menu background and separator remain visible through it.
    button.frame.background = nil
    button._menu = menu
    button._labels = labels
    button._segments = {}
    local previous
    for depth, label in ipairs(labels) do
        if label ~= "" and label ~= previous then
            local text = BD.auto(label)
            if #button._segments > 0 then
                text = BD.wrap(" " .. breadcrumb_separator .. " ") .. text
            end
            table.insert(button._segments, { depth = depth, text = text })
            previous = label
        end
    end
    button.label_widget.truncate_left = true
    -- Button:init() has already measured the label, so invalidate that cached
    -- layout to have TextWidget recompute it with left truncation.
    button.label_widget:free()
    return button
end

local function nestedMaxPerPage(menu, breadcrumb_height)
    local menu_height = menu.height and math.min(menu.height, menu.screen_size.h)
        or menu.screen_size.h
    local available_height = menu_height
        - menu.bar:getSize().h
        - menu.footer_top_margin:getSize().h
        - menu.footer:getSize().h
        - breadcrumb_height
    return math.max(1, math.floor(available_height / (menu.item_height + menu.split_height)))
end

local original_init = TouchMenu.init
function TouchMenu:init()
    self._breadcrumb_labels = {}
    self._breadcrumb_base_max_per_page = nil

    original_init(self)

    self._breadcrumb_base_max_per_page = self.max_per_page
end

local original_switchMenuTab = TouchMenu.switchMenuTab
function TouchMenu:switchMenuTab(tab_num)
    self._breadcrumb_labels = {}
    return original_switchMenuTab(self, tab_num)
end

local original_onMenuSelect = TouchMenu.onMenuSelect
function TouchMenu:onMenuSelect(item, tap_on_checkmark)
    local previous_item_table = self.item_table
    local selecting_checkmark = tap_on_checkmark and item and item.checkmark_callback
    local added_label = false
    if item and not selecting_checkmark
            and (item.sub_item_table or item.sub_item_table_func) then
        table.insert(self._breadcrumb_labels, menuItemText(item) or "")
        added_label = true
    end

    local result = original_onMenuSelect(self, item, tap_on_checkmark)

    if added_label and self.item_table == previous_item_table then
        table.remove(self._breadcrumb_labels)
    end
    return result
end

local original_backToUpperMenu = TouchMenu.backToUpperMenu
function TouchMenu:backToUpperMenu(no_close)
    if self.item_table_stack and #self.item_table_stack > 0 then
        table.remove(self._breadcrumb_labels)
    end
    return original_backToUpperMenu(self, no_close)
end

local original_updateItems = TouchMenu.updateItems
function TouchMenu:updateItems(target_page, target_item_id)
    if not self._breadcrumb_base_max_per_page then
        return original_updateItems(self, target_page, target_item_id)
    end

    while #self._breadcrumb_labels > #(self.item_table_stack or {}) do
        table.remove(self._breadcrumb_labels)
    end
    local labels = self._breadcrumb_labels
    local breadcrumb_row
    local breadcrumb_height = 0
    if #labels > 0 then
        breadcrumb_row = makeBreadcrumbRow(self, labels)
        breadcrumb_height = breadcrumb_row:getSize().h
        self.max_per_page = nestedMaxPerPage(self, breadcrumb_height)
    else
        self.max_per_page = self._breadcrumb_base_max_per_page
    end

    -- TouchMenu decides whether widgets underneath it need repainting by
    -- comparing the old and new menu heights. Account for the row while that
    -- comparison happens, even though we can only insert it after TouchMenu
    -- has rebuilt item_group.
    local original_padding = self.padding
    self.padding = original_padding + breadcrumb_height
    local result = original_updateItems(self, target_page, target_item_id)
    self.padding = original_padding

    if breadcrumb_row then
        table.insert(self.item_group, 2, breadcrumb_row)
        self.item_group:resetLayout()
        self.dimen.h = self.item_group:getSize().h + self.bordersize * 2 + self.padding
    end

    return result
end
