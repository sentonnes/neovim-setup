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

-- Pending (unwritten) usage: usage_data[date][repo] = credits
local usage_data = {}
local last_tracked = nil -- credits_used at the last tracking point

local function get_repository_name()
  local root = vim.fs.root(vim.fn.getcwd(), ".git")
  return root and vim.fs.normalize(root) or "unknown"
end

--- Record credits spent since the last call against today's date and repo.
--- Uses the difference in credits_used, so repeated calls never double count.
function M.track_monthly_usage()
  if not state.used then
    return
  end
  if not last_tracked or state.used < last_tracked then
    -- First reading, or the quota period rolled over
    last_tracked = state.used
    return
  end
  local delta = state.used - last_tracked
  if delta <= 0 then
    return
  end
  last_tracked = state.used

  local date = os.date("%Y-%m-%d")
  local repo_name = get_repository_name()
  usage_data[date] = usage_data[date] or {}
  usage_data[date][repo_name] = (usage_data[date][repo_name] or 0) + delta
end

--- Merge pending usage into the monthly file(s), summing with existing totals.
local function write_monthly_usage()
  local by_month = {}
  for date, repos in pairs(usage_data) do
    local month = date:sub(1, 7) -- YYYY-MM
    by_month[month] = by_month[month] or {}
    by_month[month][date] = repos
  end

  for month, dates in pairs(by_month) do
    local filename = string.format("%s/credit_usage_%s.txt", vim.fn.stdpath("data"), month)
    local totals = {}
    if vim.uv.fs_stat(filename) then
      for _, line in ipairs(vim.fn.readfile(filename)) do
        local date, repo, n = line:match("^(%S+) %[(.*)%]: (%d+)$")
        if date then
          totals[date] = totals[date] or {}
          totals[date][repo] = (totals[date][repo] or 0) + tonumber(n)
        end
      end
    end
    for date, repos in pairs(dates) do
      totals[date] = totals[date] or {}
      for repo, n in pairs(repos) do
        totals[date][repo] = (totals[date][repo] or 0) + n
      end
    end

    local lines = {}
    for date, repos in pairs(totals) do
      for repo, n in pairs(repos) do
        table.insert(lines, string.format("%s [%s]: %d", date, repo, n))
      end
    end
    table.sort(lines)
    vim.fn.writefile(lines, filename)
  end
  usage_data = {}
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

  -- Persist tracked usage when Neovim exits
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.track_monthly_usage()
      write_monthly_usage()
    end,
  })

  vim.api.nvim_create_user_command("CopilotUsage", function()
    M.refresh()
    vim.notify(M.details(), vim.log.levels.INFO, { title = "Copilot" })
    M.track_monthly_usage()
    write_monthly_usage()
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
      vim.defer_fn(M.refresh, 5000)
    end,
  })
end

return M
