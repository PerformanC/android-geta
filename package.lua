  return {
    name = "geta",
    version = "1.0.0",
    description = "A binary for getting logs",
    tags = { "lua", "lit", "luvit" },
    license = "BSD-2-Clause",
    author = { name = "RainyXeon", email = "xeondev@xeondex.onmicrosoft.com" },
    homepage = "https://github.com/geta",
    dependencies = {
      'luvit/luvit@2.18.1'
    },
    files = {
      "**.lua",
      "!test*",
      "!*******-log"
    }
  }
  