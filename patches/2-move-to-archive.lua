-- Add Move to archive / Move to library to KOReader's file-dialog buttons.
-- This applies to the built-in History (library), Collections, file search,
-- and File Manager long-press dialogs through the public extension hook.

local DataStorage = require("datastorage")
local DocSettings = require("docsettings")
local FileManager = require("apps/filemanager/filemanager")
local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local LuaSettings = require("luasettings")
local UIManager = require("ui/uimanager")
local lfs = require("libs/libkoreader-lfs")
local util = require("util")
local _ = require("gettext")

local ROW_ID = "library_archive_toggle"
local settings_path = DataStorage:getSettingsDir() .. "/move_to_archive_settings.lua"

local function with_slash(path)
    if path and path ~= "" and path:sub(-1) ~= "/" then
        return path .. "/"
    end
    return path
end

local function parent_dir(file)
    local dir = util.splitFilePathName(file)
    return with_slash(dir)
end

local function close_file_dialogs(fm)
    local function close(dialog)
        if dialog then UIManager:close(dialog) end
    end
    close(fm.file_chooser and fm.file_chooser.file_dialog)
    close(fm.history and fm.history.file_dialog)
    close(fm.collections and fm.collections.file_dialog)
    close(fm.filesearcher and fm.filesearcher.file_dialog)
end

local function refresh_views(fm)
    if fm.file_chooser then fm.file_chooser:refreshPath() end
    if fm.history and fm.history.booklist_menu then
        fm.history:updateItemTable()
    end
end

local function move_book(fm, file, destination_dir, message, archive_settings, original_dirs)
    local _source_dir, filename = util.splitFilePathName(file)
    destination_dir = with_slash(destination_dir)
    local destination = destination_dir .. filename

    FileManager:moveFile(file, destination_dir)
    require("readhistory"):updateItem(file, destination)
    require("readcollection"):updateItem(file, destination)
    DocSettings.updateLocation(file, destination, false)
    archive_settings:saveSetting("library_archive_original_dirs", original_dirs)
    archive_settings:flush()

    close_file_dialogs(fm)
    refresh_views(fm)
    UIManager:show(InfoMessage:new{ text = message, timeout = 3 })
end

local function archive_button(fm, file, is_file)
    if not is_file or lfs.attributes(file, "mode") ~= "file" then return nil end

    local archive_settings = LuaSettings:open(settings_path)
    local archive_dir = with_slash(archive_settings:readSetting("archive_dir"))
    if not archive_dir or lfs.attributes(archive_dir, "mode") ~= "directory" then
        return {{
            text = _("Move to archive"),
            callback = function()
                UIManager:show(ConfirmBox:new{
                    text = _("No archive directory.\nDo you want to set it now?"),
                    ok_text = _("Set archive folder"),
                    ok_callback = function()
                        require("ui/downloadmgr"):new{
                            onConfirm = function(path)
                                archive_settings:saveSetting("archive_dir", with_slash(path))
                                archive_settings:flush()
                            end,
                        }:chooseDir()
                    end,
                })
            end,
        }}
    end

    local original_dirs = archive_settings:readSetting("library_archive_original_dirs") or {}
    local in_archive = parent_dir(file) == archive_dir
    local currently_open = fm.document and fm.document.file == file

    if in_archive then
        return {{
            text = _("Move to library"),
            enabled = not currently_open,
            callback = function()
                local library_dir = original_dirs[file]
                    or G_reader_settings:readSetting("home_dir")
                if not library_dir or lfs.attributes(library_dir, "mode") ~= "directory" then
                    UIManager:show(InfoMessage:new{
                        text = _("Set a HOME folder in File Manager first."), timeout = 3,
                    })
                    return
                end
                original_dirs[file] = nil
                move_book(fm, file, library_dir, _("Book moved to library."),
                    archive_settings, original_dirs)
            end,
        }}
    end

    return {{
        text = _("Move to archive"),
        enabled = not currently_open,
        callback = function()
            local _source_dir, filename = util.splitFilePathName(file)
            original_dirs[archive_dir .. filename] = parent_dir(file)
            move_book(fm, file, archive_dir, _("Book moved to archive."),
                archive_settings, original_dirs)
        end,
    }}
end

local function install(fm)
    fm:addFileDialogButtons(ROW_ID, function(file, is_file)
        return archive_button(fm, file, is_file)
    end)
end

-- Install on future FileManager instances.
local original_init = FileManager.init
function FileManager:init(...)
    original_init(self, ...)
    install(self)
end

-- Also support patch reload while File Manager is already alive.
if FileManager.instance then
    FileManager.instance:removeFileDialogButtons(ROW_ID)
    install(FileManager.instance)
end
