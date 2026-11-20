-- Copilot credit usage for the statusline.
-- Reads `premium_interactions.credits_used` from the (undocumented)
-- /copilot_internal/user endpoint via the GitHub CLI, asynchronously.

local M = {}

local INTERVAL_MS = 1 * 60 * 1000 -- refresh every 1 minute(s)
local DAY_MS = 24 * 60 * 60 * 1000

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

local usage_data = {}

local function get_repository_name()
  return vim.fn.systemlist("git rev-parse --show-toplevel")[1] or "unknown"
end

function M.track_monthly_usage()
  local date = os.date("%Y-%m-%d")
  local repo_name = get_repository_name()
  local delta = state.used or 0

  usage_data[date] = usage_data[date] or {}
  usage_data[date][repo_name] = (usage_data[date][repo_name] or 0) + delta
end

local function write_monthly_usage()
  local current_time = os.date("%Y-%m") -- format YYYY-MM
  local filename = string.format("%s/credit_usage_%s.txt", vim.fn.stdpath("data"), current_time)
  local file = io.open(filename, "a+")
  if file then
    for date, usage in pairs(usage_data) do
      for repo, total_usage in pairs(usage) do
        file:write(string.format("%s [%s]: %d\n", date, repo, total_usage))
      end
    end
    file:close()
  end
  usage_data = {}
end

local function check_and_write()
  local current_time = os.date("%Y-%m-%d")
  local first_day = os.date("%Y-%m") .. "-01"
  local next_day = os.date("%Y-%m-%d", os.time() + 86400)

  if current_time >= first_day and current_time < next_day then
    write_monthly_usage()
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

  -- Daily write of tracked usage
  local daily_timer = vim.uv.new_timer()
  daily_timer:start(DAY_MS, DAY_MS, vim.schedule_wrap(check_and_write))

  vim.api.nvim_create_user_command("CopilotUsage", function()
    M.refresh()
    vim.notify(M.details(), vim.log.levels.INFO, { title = "Copilot" })
    M.track_monthly_usage()
    if os.date("%Y-%m-%d") == state.reset then
      write_monthly_usage()
    end
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
