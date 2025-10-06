return {
  "mason-org/mason.nvim",
  opts = {
    ensure_installed = {
      "stylua",
      "shellcheck",
      "shfmt",
      "flake8",
    },
    registries = {
      "github:mason-org/mason-registry",
      "github:Crashdummyy/mason-registry",
    },
  },
}
