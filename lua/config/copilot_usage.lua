-- Copilot credit usage for the statusline.
-- Reads `premium_interactions.credits_used` from the (undocumented)
-- /copilot_internal/user endpoint via the GitHub CLI, asynchronously.

local M = {}

local INTERVAL_MS = 1 * 60 * 1000 -- refresh every 1 minute(s)

local state = {
  used = nil, -- latest credits_used
  baseline = nil, -- credits_used when Neovim started (for session delta)
  reset = nil, -- quota reset date
  model = nil, -- model from the latest CodeCompanion request
  error = nil,
  busy = false,
}

local function fmt(n)
  return tostring(math.floor(n / 100)) .. "$"
end

function M.refresh()
  if state.busy or vim.fn.executable("gh") == 0 then
    return
  end
  state.busy = true
  vim.system({ "gh", "api", "/copilot_internal/user" }, { text = true }, function(res)
    vim.schedule(function()
      state.busy = false
      if res.code ~= 0 then
        state.error = vim.trim(res.stderr or "gh api failed")
        return
      end
      local ok, data = pcall(vim.json.decode, res.stdout)
      local premium = ok and data.quota_snapshots and data.quota_snapshots.premium_interactions
      if not (premium and premium.credits_used) then
        state.error = "credits_used not found in response"
        return
      end
      state.error = nil
      state.used = premium.credits_used
      state.reset = data.quota_reset_date
      -- Re-baseline if the period rolled over (count went down)
      if not state.baseline or state.used < state.baseline then
        state.baseline = state.used
      end
      M.track_monthly_usage()
      pcall(function()
        require("lualine").refresh()
      end)
    end)
  end)
end

--- Statusline text, e.g. " 🤖 auto 357$ (+1$)"
function M.status()
  if state.error then
    return " 🤖 ⁉️"
  end
  if not state.used then
    return ""
  end
  local text = " 🤖 " .. (state.model and (state.model .. " ") or "") .. fmt(state.used)
  local delta = state.used - (state.baseline or state.used)
  if delta > 0 then
    text = text .. " (+" .. fmt(delta) .. ")"
  end
  return text
end

function M.details()
  if state.error then
    return "Copilot usage error: " .. state.error
  end
  if not state.used then
    return "Copilot usage: not fetched yet"
  end
  return string.format(
    "Copilot credits used this period: %d\nThis session: +%d\nResets: %s",
    state.used,
    state.used - (state.baseline or state.used),
    state.reset or "?"
  )
end

-- Monthly usage tracking ---------------------------------------------------
--
-- credits_used is account-wide, and several Neovim instances may be open at
-- once. To avoid each instance counting the same credits, the last recorded
-- credits_used is kept in a shared file on disk, and only an instance that
-- has made a CodeCompanion request claims the increase. All reads/writes of
-- the shared files happen under a cross-process lock.

local DATA_DIR = vim.fn.stdpath("data")
local LAST_FILE = DATA_DIR .. "/credit_usage_last.txt"
local LOCK_DIR = DATA_DIR .. "/credit_usage.lock"
local LOCK_STALE_S = 30 -- break locks left behind by a crashed instance

local claim_pending = false -- this instance made a request not yet recorded

local function get_repository_name()
  local root = vim.fs.root(vim.fn.getcwd(), ".git")
  return root and vim.fs.normalize(root) or "unknown"
end

--- Run fn while holding a cross-process lock (mkdir is atomic).
local function with_lock(fn)
  vim.fn.mkdir(DATA_DIR, "p")
  for _ = 1, 100 do
    if vim.uv.fs_mkdir(LOCK_DIR, 493) then
      local ok, err = pcall(fn)
      vim.uv.fs_rmdir(LOCK_DIR)
      if not ok then
        vim.notify("Copilot usage: " .. tostring(err), vim.log.levels.WARN)
      end
      return ok
    end
    local stat = vim.uv.fs_stat(LOCK_DIR)
    if stat and os.time() - stat.mtime.sec > LOCK_STALE_S then
      vim.uv.fs_rmdir(LOCK_DIR)
    else
      vim.uv.sleep(20)
    end
  end
  return false
end

--- Add credits to the monthly file for the given date and repo.
local function add_usage(date, repo, credits)
  local filename = string.format("%s/credit_usage_%s.txt", DATA_DIR, date:sub(1, 7))
  local totals = {}
  if vim.uv.fs_stat(filename) then
    for _, line in ipairs(vim.fn.readfile(filename)) do
      local d, r, n = line:match("^(%S+) %[(.*)%]: (%d+)$")
      if d then
        totals[d .. "\0" .. r] = (totals[d .. "\0" .. r] or 0) + tonumber(n)
      end
    end
  end
  local key = date .. "\0" .. repo
  totals[key] = (totals[key] or 0) + credits

  local lines = {}
  for k, n in pairs(totals) do
    local d, r = k:match("^(.-)%z(.*)$")
    table.insert(lines, string.format("%s [%s]: %d", d, r, n))
  end
  table.sort(lines)
  vim.fn.writefile(lines, filename)
end

--- Record credits spent since the last recorded total (shared across all
--- instances) against today's date and this instance's repo.
function M.track_monthly_usage()
  if not state.used then
    return
  end
  -- Without a pending request, only proceed to create the initial baseline
  if not claim_pending and vim.uv.fs_stat(LAST_FILE) then
    return
  end
  local used = state.used
  local ok = with_lock(function()
    local last = vim.uv.fs_stat(LAST_FILE) and tonumber(vim.fn.readfile(LAST_FILE)[1] or "")
    if last and used > last then
      add_usage(os.date("%Y-%m-%d"), get_repository_name(), used - last)
    end
    -- First run, period rollover (count went down), or after recording
    if not last or used ~= last then
      vim.fn.writefile({ tostring(used) }, LAST_FILE)
    end
  end)
  if ok then
    claim_pending = false
  end
end

-- Setup --------------------------------------------------------------------

function M.setup()
  if M._started then
    return
  end
  M._started = true
  M.refresh()

  -- Periodic usage refresh
  local timer = vim.uv.new_timer()
  timer:start(INTERVAL_MS, INTERVAL_MS, vim.schedule_wrap(M.refresh))

  vim.api.nvim_create_user_command("CopilotUsage", function()
    M.refresh()
    vim.notify(M.details(), vim.log.levels.INFO, { title = "Copilot" })
  end, { desc = "Show Copilot credit usage" })

  -- Track the selected model for the latest Copilot request.
  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionRequestStarted",
    callback = function(event)
      local adapter = event.data and event.data.adapter
      if adapter and adapter.name == "copilot" and type(adapter.model) == "string" and adapter.model ~= "" then
        state.model = adapter.model
        pcall(function()
          require("lualine").refresh()
        end)
      end
    end,
  })

  -- Refresh shortly after a CodeCompanion request finishes
  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionRequestFinished",
    callback = function()
      claim_pending = true
      vim.defer_fn(M.refresh, 5000)
    end,
  })
end

return M
