return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", mode = { "n", "i", "t" } },
    { "<C-j>", "<cmd>TmuxNavigateDown<CR>", mode = { "n", "i", "t" } },
    { "<C-k>", "<cmd>TmuxNavigateUp<CR>", mode = { "n", "i", "t" } },
    { "<C-l>", "<cmd>TmuxNavigateRight<CR>", mode = { "n", "i", "t" } },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>", mode = { "n", "i", "t" } },
  },
}
