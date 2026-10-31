-- @noindex
--[[
  OnsetRR - Load Media Explorer selection
  Companion action for the "Onset Round-Robin Sampler" JSFX (ReaJSFX).

  Sends the files currently selected in REAPER's Media Explorer to the
  Onset RR Sampler instance on the selected track (or the focused FX window).
  The sampler then splits them into one-shots with onset detection.

  Where the files come from (first match wins):
    1. Selected files in the Media Explorer   (needs the js_ReaScriptAPI extension)
    2. Sources of the selected media items in the arrange view
    3. A file-open dialog

  Which sampler receives them (first match wins):
    1. The focused FX window, if it is an Onset RR Sampler
    2. The first Onset RR Sampler on the selected track(s)
    3. A new Onset RR Sampler inserted on the first selected track

  Tip: add this script to the "Media Explorer" section of the action list and
  give it a shortcut, so you can fire it while browsing sounds.

  Set ONSETRR_APPEND = true before running (see the "Append" variant) to add
  the files to the sampler's current content instead of replacing it.
]]

local GMEM_NAME   = "ReaJSFX_OnsetRR"
local FX_PATTERN  = "Onset Round%-Robin Sampler"
local PARAM_MATCH = "Remote load"
local APPEND      = ONSETRR_APPEND == true
local MAX_FILES   = 64

local sep = package.config:sub(1, 1)

local function msg(s)
  reaper.ShowMessageBox(s, "Onset RR Sampler", 0)
end

local function file_exists(p)
  return p and p ~= "" and reaper.file_exists(p)
end

---------------------------------------------------------------------------
-- 1. Media Explorer selection (js_ReaScriptAPI)
---------------------------------------------------------------------------
local AUDIO_EXT = { "wav", "flac", "ogg", "mp3", "aif", "aiff", "wv", "opus", "w64", "bwf" }

-- Media Explorer may hide file extensions: try to find the real file.
local function resolve(dir, name)
  if dir ~= "" then
    local p = dir .. sep .. name
    if file_exists(p) then return p end
    for _, e in ipairs(AUDIO_EXT) do
      if file_exists(p .. "." .. e) then return p .. "." .. e end
      if file_exists(p .. "." .. e:upper()) then return p .. "." .. e:upper() end
    end
  end
  if file_exists(name) then return name end
  return nil
end

local function media_explorer_files()
  if not reaper.JS_Window_Find then return nil end
  local title = reaper.JS_Localize and reaper.JS_Localize("Media Explorer", "common") or "Media Explorer"
  local hwnd = reaper.JS_Window_Find(title, true)
  if not hwnd then return nil end

  local container = reaper.JS_Window_FindChildByID(hwnd, 0)
  local lv = container and reaper.JS_Window_FindChildByID(container, 1000)
  if not lv then lv = reaper.JS_Window_FindChildByID(hwnd, 1000) end
  if not lv then return nil end

  local count, sel = reaper.JS_ListView_ListAllSelItems(lv)
  if not count or count == 0 then return nil end

  local dir = ""
  local combo = reaper.JS_Window_FindChildByID(hwnd, 1002)
  local edit = combo and reaper.JS_Window_FindChildByID(combo, 1001)
  if edit then dir = reaper.JS_Window_GetTitle(edit, "") or "" end
  dir = dir:gsub("[/\\]+$", "")

  local files = {}
  for idx in sel:gmatch("[^,]+") do
    local row = tonumber(idx)
    local name = reaper.JS_ListView_GetItemText(lv, row, 0)
    local path = resolve(dir, name)
    if not path then
      -- search results / databases: look for a column holding a folder or full path
      for col = 1, 20 do
        local t = reaper.JS_ListView_GetItemText(lv, row, col)
        if t and t ~= "" then
          path = resolve(t:gsub("[/\\]+$", ""), name) or (file_exists(t) and t or nil)
          if path then break end
        end
      end
    end
    if path then files[#files + 1] = path end
    if #files >= MAX_FILES then break end
  end
  return #files > 0 and files or nil
end

---------------------------------------------------------------------------
-- 2. Selected media items
---------------------------------------------------------------------------
local function selected_item_files()
  local files, seen = {}, {}
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    local take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))
    if take and not reaper.TakeIsMIDI(take) then
      local src = reaper.GetMediaItemTake_Source(take)
      local parent = reaper.GetMediaSourceParent(src)
      while parent do src = parent; parent = reaper.GetMediaSourceParent(src) end
      local fn = reaper.GetMediaSourceFileName(src, "")
      if file_exists(fn) and not seen[fn] then
        seen[fn] = true
        files[#files + 1] = fn
      end
    end
    if #files >= MAX_FILES then break end
  end
  return #files > 0 and files or nil
end

---------------------------------------------------------------------------
-- 3. File dialog
---------------------------------------------------------------------------
local function dialog_file()
  local ok, fn = reaper.GetUserFileNameForRead("", "Onset RR Sampler - choose audio file", "")
  if ok and file_exists(fn) then return { fn } end
  return nil
end

---------------------------------------------------------------------------
-- Find / insert the sampler
---------------------------------------------------------------------------
local function is_sampler(track, fx)
  local _, name = reaper.TrackFX_GetFXName(track, fx, "")
  return name and name:find(FX_PATTERN) ~= nil
end

local function find_sampler()
  -- focused FX window
  local rv, tnum, inum, fxnum = reaper.GetFocusedFX()
  if rv == 1 then
    local tr = tnum == 0 and reaper.GetMasterTrack(0) or reaper.GetTrack(0, tnum - 1)
    if tr and is_sampler(tr, fxnum) then return tr, fxnum end
  end
  -- selected tracks
  for t = 0, reaper.CountSelectedTracks(0) - 1 do
    local tr = reaper.GetSelectedTrack(0, t)
    for fx = 0, reaper.TrackFX_GetCount(tr) - 1 do
      if is_sampler(tr, fx) then return tr, fx end
    end
  end
  -- insert a new one on the first selected track
  local tr = reaper.GetSelectedTrack(0, 0)
  if not tr then return nil end
  local candidates = {
    "JS:Onset Round-Robin Sampler",
    "Onset Round-Robin Sampler",
    "JS:OnsetRRSampler/OnsetRRSampler.jsfx",
    "JS:Marcins JSFX/OnsetRRSampler/OnsetRRSampler.jsfx",
    "JS:ReaJSFX/OnsetRRSampler/OnsetRRSampler.jsfx",
  }
  for _, c in ipairs(candidates) do
    local fx = reaper.TrackFX_AddByName(tr, c, false, -1)
    if fx >= 0 then
      reaper.TrackFX_Show(tr, fx, 3) -- floating window so you can see the slices
      return tr, fx
    end
  end
  return nil
end

local function find_param(tr, fx)
  for p = 0, reaper.TrackFX_GetNumParams(tr, fx) - 1 do
    local _, name = reaper.TrackFX_GetParamName(tr, fx, p, "")
    if name and name:find(PARAM_MATCH, 1, true) then return p end
  end
  return nil
end

---------------------------------------------------------------------------
-- Main
---------------------------------------------------------------------------
local function main()
  local files = media_explorer_files() or selected_item_files() or dialog_file()
  if not files then
    if not reaper.JS_Window_Find then
      msg("No files found.\n\nTo read the Media Explorer selection directly, install the "
        .. "js_ReaScriptAPI extension (via ReaPack).\nYou can also drag files from the Media "
        .. "Explorer onto the sampler window, or select items in the arrange view.")
    end
    return
  end

  local tr, fx = find_sampler()
  if not tr then
    msg("Select a track (with or without an Onset Round-Robin Sampler on it) first.")
    return
  end
  local param = find_param(tr, fx)
  if not param then
    msg("This sampler version has no remote-load parameter. Please update the JSFX.")
    return
  end

  -- gmem layout: [0] pending serial (cleared by JSFX) [1] file count [2] append
  --              [4] serial counter [16..] null-separated UTF-8 bytes
  reaper.gmem_attach(GMEM_NAME)
  local serial = math.floor(reaper.gmem_read(4)) + 1
  if serial > 999999 or serial < 1 then serial = 1 end
  reaper.gmem_write(4, serial)

  local p = 16
  for _, f in ipairs(files) do
    for i = 1, #f do
      reaper.gmem_write(p, f:byte(i)); p = p + 1
    end
    reaper.gmem_write(p, 0); p = p + 1
  end
  reaper.gmem_write(1, #files)
  reaper.gmem_write(2, APPEND and 1 or 0)
  reaper.gmem_write(0, serial)            -- publish last

  reaper.TrackFX_SetParam(tr, fx, param, serial)
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Onset RR Sampler: load files", -1)
