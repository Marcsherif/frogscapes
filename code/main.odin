package game

import "base:runtime"
import slog "../ext/sokol/log"
import sg "../ext/sokol/gfx"
import sapp "../ext/sokol/app"
import sglue "../ext/sokol/glue"
import stime "../ext/sokol/time"

state: struct {
    pip: sg.Pipeline,
    bind: sg.Bindings,
    pass_action: sg.Pass_Action,
}

init :: proc "c" () {
    context = runtime.default_context()

    stime.setup()

    sg.setup({
        environment = sglue.environment(),
        logger = { func = slog.func },
    })

    // a vertex buffer with 4 vertices
    vertices := [?]f32 {
        // positions         // colors
        -1.0, -1.0, +0.5,    1.0, 0.0, 0.0, 1.0,
        +1.0, -1.0, +0.5,    0.0, 1.0, 0.0, 1.0,
        +1.0, +1.0, +0.5,    0.0, 0.0, 1.0, 1.0,
        -1.0, +1.0, +0.5,    0.0, 1.0, 1.0, 1.0,
    }
    state.bind.vertex_buffers[0] = sg.make_buffer({
        data = { ptr = &vertices, size = size_of(vertices) },
    })

    // an index buffer
    indices := [?]u16{ 0, 1, 2, 0, 2, 3}
    state.bind.index_buffer = sg.make_buffer({
        data = { ptr = &indices, size = size_of(indices) },
        type = .INDEXBUFFER,
    })

    // create a shader and pipeline object (default render states are fine for triangle)
    state.pip = sg.make_pipeline({
        shader = sg.make_shader(triangle_shader_desc(sg.query_backend())),
        layout = {
            attrs = {
                ATTR_triangle_position = { format = .FLOAT3 },
                ATTR_triangle_color0 = { format = .FLOAT4 },
            },
        },
        index_type = .UINT16,
    })

    // a pass action to clear framebuffer to black
    state.pass_action = {
        colors = {
            0 = { load_action = .CLEAR, clear_value = { r = 0, g = 0, b = 0, a = 1 }},
        },
    }
}

frame :: proc "c" () {
    context = runtime.default_context()

    timeElapsed := f32(stime.sec(stime.since(0)))

    fs_params := Fs_Params {
        iResolution = [2]f32{ sapp.widthf(), sapp.heightf() },
        iTime = timeElapsed
    }

    sg.begin_pass({ action = state.pass_action, swapchain = sglue.swapchain() })
    sg.apply_pipeline(state.pip)
    sg.apply_bindings(state.bind)
    sg.apply_uniforms(UB_fs_params, { ptr = &fs_params, size = size_of(fs_params) })
    sg.draw(0, 6, 1)
    sg.end_pass()
    sg.commit()
}

cleanup :: proc "c" () {
    context = runtime.default_context()
    sg.shutdown()
}

event :: proc "c" (e : ^sapp.Event) {
    context = runtime.default_context()

    #partial switch e.type {
        case .KEY_DOWN:
            if e.key_code == .ESCAPE {
                sapp.quit()
            }
            if e.key_code == .ENTER {
                sapp.toggle_fullscreen()
            }
    }
}

main :: proc()
{
    sapp.run({
        init_cb = init,
        frame_cb = frame,
        cleanup_cb = cleanup,
        event_cb = event,
        width = 640,
        height = 480,
        window_title = "triangle",
        icon = { sokol_default = true },
        logger = { func = slog.func },
    })
}
