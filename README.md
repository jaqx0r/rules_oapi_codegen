# rules_oapi_codegen

Bazel rules for generating API service handlers from OpenAPI yaml with [`oapi-codegen`](https://github.com/oapi-codegen/oapi-codegen).

## Rules

### `oapi_codegen`

```starlark
load("@rules_oapi_codegen//:defs.bzl", "oapi_codegen")

oapi_codegen(
  name = "generate_api_handler",
  src = "api.yaml",
  generate = "gin", # your server framework of choice
  out = "api.go",
  strict = True,  # default is True
  models = True,  # default is True
)
```

`oapi_codegen` invokes the `oapi-codegen` binary on your source openapi yaml description, generating a service handler for that specification into the output file.

The generated file is not scanned for imports by `bazel run @rules_go//go -- mod tidy` nor `bazel run //:gazelle` so you will have to manually copy the imports from your generated file once:

    1. ```shell
       bazel build //:generate_api_handler
       ```
       
   2. Inspect the output in `bazel-bin/api.go`

   3. Create an import-only file:
      ```go
      package api
      
      import (
        _ "github.com/gin/gin-gonic"
        ... etc
      )
      ```



