-- @noindex
-- OnsetRR - Append Media Explorer selection
-- Same as "OnsetRR - Load Media Explorer selection", but adds the files to the
-- sampler's current content instead of replacing it.

ONSETRR_APPEND = true
local dir = debug.getinfo(1, "S").source:match("^@(.*[/\\])") or ""
dofile(dir .. "OnsetRR - Load Media Explorer selection.lua")
