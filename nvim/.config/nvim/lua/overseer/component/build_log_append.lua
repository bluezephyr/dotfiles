---@type overseer.ComponentFileDefinition
return {
  desc = "Append task output to the persistent build log buffer",
  constructor = function()
    return {
      on_start = function(self, task)
        local header = string.format("── %s ── %s ──", task.name, os.date("%H:%M:%S"))
        require("build_log").append({ "", header })
      end,
      on_output_lines = function(self, task, lines)
        require("build_log").append(lines)
      end,
    }
  end,
}
