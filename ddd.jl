module GuiPrototype



using StructArrays
using CImGui
using ImPlot
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
import CImGui.LibCImGui: ImGuiCond_Always, ImGuiCond_Once

include("Renderer.jl")
using .Renderer
include("readfiles.jl")
using Dates, DataFrames
#t1 = readhdr("./data/breath_base/ox113519.hdr")
#string(t1[5])
include("common_widgets.jl")
include("cursor.jl")
include("my_plot.jl")
include("event_tab.jl")
include("test_buttons.jl")
include("file_table.jl")
include("content_file.jl")
# привязать состояния глобальные
const USERDATA = Dict{String, Any}(
    "xy1" => (zeros(Float32, 1001), zeros(Float32, 1001)),
    "xy2" => (zeros(Float32, 11), zeros(Float32, 11)),
)
files = [file for file in readdir("./breath_base") if occursin(".hdr", file)]
channels = [readhdr("./breath_base/" * file)[6] for file in files]
dates = [string(readhdr("./breath_base/" * file)[5]) for file in files]
USERDATA["CURSOR"] = ImCursor()
USERDATA["files"] = files
#USERDATA["files"] = StructVector(
#    files = files,
#    channels = [readhdr("./data/breath_base/" * file)[6] for file in readdir("./data/breath_base") if occursin(".bin", file)],
#    dates = [string(readhdr("./data/breath_base/" * file)[5]) for file in readdir("./data/breath_base") if occursin(".bin", file)]
#)
USERDATA["events_table"] = StructVector(
    pos = [-100, 0, 100, 200, 300, 400, 500],
    type = [:A, :B, :C, :D, :E, :F, :G]
)

# привязать состояния к текущему виджету
const STORAGE = Dict{UInt32, Any}()
get_uistate(key::String = "", default = nothing) = get(STORAGE, CImGui.GetID(key), default)
set_uistate(key::String, value) = STORAGE[CImGui.GetID(key)] = value


function main_gui()
    CImGui.Begin("Window")

    xs1, ys1 = USERDATA["xy1"]
    xs2, ys2 = USERDATA["xy2"]

    check = get_uistate("time_checkbox", false)
    if @c CImGui.Checkbox("Click me to animate plot", &check)
        set_uistate("time_checkbox", check)
    end
    if check
        DEMO_TIME = CImGui.GetTime()
        for i in eachindex(xs1)
            xs1[i] = (i - 1) * 0.001
            ys1[i] = 0.5 + 0.5 * sin(50 * (xs1[i] + DEMO_TIME / 10))
        end
        for i in eachindex(xs2)
            xs2[i] = (i - 1) * 0.1
            ys2[i] = xs2[i] * xs2[i]
        end
    end

    # CImGui.BulletText("Anti-aliasing can be enabled from the plot's context menu (see Help).")
    # if ImPlot.BeginPlot("Line Plot", "x", "f(x)")
    #     ImPlot.PlotLine("sin(x)", xs1, ys1, length(xs1))
    #     ImPlot.SetNextMarkerStyle(ImPlotMarker_Circle)
    #     ImPlot.PlotLine("x^2", xs2, ys2, length(xs2))
    #     ImPlot.EndPlot()
    # end

    style = CImGui.GetStyle()
    sp = unsafe_load(style).ItemSpacing

    test_buttons()
    cursor_ref = USERDATA["CURSOR"]

    tmp = cursor_ref[]
    @c CImGui.DragFloat("cursor", &tmp)
    if cursor_ref[] !== tmp
        cursor_ref[] = tmp # т.к. нужно записать ID виджета изменившего курсор
    end

    # =========================================

    # вписываем по высоте и ширине окна
    vMin = CImGui.GetWindowContentRegionMin()
    vMax = CImGui.GetWindowContentRegionMax()
    Nplots = 2 # 2 графика на весь диапазон ниже
    width = vMax.x - vMin.x
    height = vMax.y - CImGui.GetCursorPosY() #vMin.y
    x_flags = ImPlotAxisFlags_None
    y_flags = ImPlotAxisFlags_NoTickLabels # ImPlotAxisFlags_None #
    size = CImGui.ImVec2(width, height  / Nplots - sp.y*(Nplots-1))
    # ================================

    MyPlot(
        "my plot", ys1, cursor_ref;
        xlim = (1.f0, 100.f0), ylim = (0.f0, 2.f0),
        size = size,
        x_flags = x_flags,
        y_flags = y_flags,
    )
    MyPlot(
        "my plot 2", ys2, cursor_ref;
        xlim = (1.f0, 100.f0), ylim = (0.f0, 2.f0),
        size = size,
        add_controls = false,
    )

    CImGui.Begin("Events")
        tab = USERDATA["events_table"]
        EventTable("my events", tab, cursor_ref)
    CImGui.End()

    CImGui.Begin("Window 2")
        MyPlot("my plot 2", ys2, cursor_ref, xlim = (1.f0, 100.f0), ylim = (0.f0, 2.f0))
    CImGui.End()

        CImGui.Begin("Name file")
            items = USERDATA["files"]
            plot_file_table(items)
            if CImGui.IsItemHovered()
                state = get_uistate("file_state")
                display_content(state)
            end
        CImGui.End()


    #@info cursor_ref[]

    cursor_ref = get_uistate("cursor", Ref(0.f0))

    #@info cursor_ref[]
    CImGui.End()
end

# # main functinon
function show_gui()
    Renderer.render(
        main_gui, # function object
        width = 1360,
        height = 780,
        title = "",
        hotloading = true
    )
    return nothing
end


export show_gui

end # module GuiPrototype
