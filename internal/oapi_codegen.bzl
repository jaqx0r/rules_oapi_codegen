"""
Generate code for an OpenAPI Specification.
"""

load("@rules_go//go:def.bzl", "go_context")

_OAPI_CODEGEN_TOOL = "@com_github_oapi_codegen_oapi_codegen_v2//cmd/oapi-codegen"

_OAPI_CONFIG_TEMPLATE = """package: {package}
generate:
  {generate}-server: true
  strict-server: {strict}
  models: {models}
output: {output}
{output_options}
"""

def _oapi_codegen_impl(ctx):
    """Implementation of a build rule to run `oapi-codegen`.

    This rule generates a Go service implementation based on an OpenAPI spec, witten in YAML.
    """

    # The shenanigans with `go_context` and the wrapper script are required to
    # get the absolute path to the Go binary, inside the bazel sandbox.  This
    # is because of https://github.com/golang/go/issues/73734 ; the tool does
    # not accept a relative path.
    go_ctx = go_context(ctx)

    output_options = ""
    if ctx.attr.output_options:
        output_options += "output-options:\n"
        for k, v in ctx.attr.output_options.items():
            output_options += "  {}: {}\n".format(k, v)

    config_file = ctx.actions.declare_file(ctx.label.name + "_config.yaml")
    ctx.actions.write(
        output = config_file,
        content = _OAPI_CONFIG_TEMPLATE.format(
            package = ctx.attr.package,
            strict = ctx.attr.strict,
            output = ctx.outputs.out.path,
            models = ctx.attr.models,
            generate = ctx.attr.generate,
            output_options = output_options,
        ),
    )

    inputs = depset(direct = [ctx.file.src, go_ctx.sdk.go, config_file])

    args = ctx.actions.args()
    args.add(ctx.executable._oapi_codegen_tool)
    args.add(go_ctx.sdk.root_file.dirname)
    args.add(config_file)
    args.add(ctx.file.src)

    go_ctx.actions.run(
        mnemonic = "OpenAPIGen",
        executable = ctx.executable._oapi_codegen_wrapper,
        arguments = [args],
        tools = [ctx.executable._oapi_codegen_tool],
        inputs = inputs,
        outputs = [ctx.outputs.out],
    )

    return DefaultInfo(
        files = depset([ctx.outputs.out]),
    )

oapi_codegen = rule(
    implementation = _oapi_codegen_impl,
    doc = """Generate a Go service handler from an OpenAPI YAML specification.""",
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            doc = "The source YAML containing the OpenAPI specification.",
        ),
        "out": attr.output(
            doc = "The filename to write the output service handler to.",
        ),
        "package": attr.string(doc = "The name of the package that the service handler code is a part of."),
        "strict": attr.bool(
            default = True,
            doc = "Generate the service handler in strict-mode: https://github.com/oapi-codegen/oapi-codegen?tab=readme-ov-file#strict-server",
        ),
        "models": attr.bool(
            default = True,
            doc = "Generate models for schema components.",
        ),
        "output_options": attr.string_dict(
            doc = "Provide oapi-codegen output-options.",
            default = {},
        ),
        "generate": attr.string(
            doc = "Specify the server framework to generate the service handler for.",
        ),
        "_oapi_codegen_tool": attr.label(
            default = _OAPI_CODEGEN_TOOL,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_oapi_codegen_wrapper": attr.label(
            default = "//tools:oapi_codegen_wrapper.sh",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@rules_go//go:toolchain"],
)
