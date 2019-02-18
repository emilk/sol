-- Globals settings - set by solc

global g_local_parse        = false -- If true, ignore 'require'
global g_spam               = false
global g_ignore_errors      = false
global g_break_on_error     = false
global g_warnings_as_errors = false
global g_write_timings      = false
global g_print_stats        = false  -- Prints out stats on the popularity of tokens and ast_type:s
global g_one_line_errors    = false  -- Print errors and warnigns on single lines

-- Output options:
global g_align_lines        = false  -- Align line numbers in output?
global g_warn_output        = false  -- Print --[[SOL OUTPUT--]]  on each line in output file?
