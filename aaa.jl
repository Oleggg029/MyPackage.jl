import StructArrays.Tables: columnnames, columntable

mutable struct _EventTableState
    iselected::Int # номер выбранной строки в data
    range::UnitRange{Int} # интервал видимых элементов
    cursor::Float32 # последняя отработанная позиция курсора
    changed_from_outside::Bool
end

function EventTable(
    name::String,
    table_data::StructVector, # таблица в виде структуры векторов, первая колонка = позиции
    cursor_ref::ImCursor
)

    state = get_uistate("state", nothing)
    # необходимо обновить состояние для новых данных
    if state === nothing
        state = _EventTableState(1, 1:min(100, length(table_data)), 0.f0, false)
        set_uistate("state", state)
    end
    # state.iselected = 1
    # state.range = 1:min(100, length(table_data))
    cols_data = columntable(table_data)
    nams = columnnames(table_data) # ???
    N = length(nams)

    # при изменении курсора - ищем ближайшее событие
    if cursor_ref[] !== state.cursor
        index = searchsorted(cols_data[1], cursor_ref[])
        ind = first(index)
        state.iselected = ind
        if state.iselected < first(state.range) || last(state.range) < state.iselected # если выбрана строка вне текущей области - скроллим туда!
            state.changed_from_outside = true
        end
        state.cursor = cursor_ref[]
    end

    flag = CImGui.LibCImGui.ImGuiTableFlags_BordersOuter |
        CImGui.LibCImGui.ImGuiTableFlags_BordersInner |
        CImGui.LibCImGui.ImGuiTableFlags_RowBg |
        CImGui.LibCImGui.ImGuiTableFlags_ScrollY |
        CImGui.LibCImGui.ImGuiTableColumnFlags_WidthStretch

    if CImGui.BeginTable(name, N, flag,CImGui.ImVec2(-1,0),-1.0)
        CImGui.TableSetupScrollFreeze(0, 1)
        for i in 1:N
            CImGui.TableSetupColumn(string(nams[i]), CImGui.LibCImGui.ImGuiTableColumnFlags_WidthStretch, 80.0, UInt32(2+i))
        end
        CImGui.TableHeadersRow()

        clipper = CImGui.Clipper()
        CImGui.ImGuiListClipper_Begin(clipper, length(table_data), -1) # error in old version wrapper.jl: CImGui.Begin(clipper, length(table_data))

        while CImGui.Step(clipper)

            disp_start = unsafe_load(clipper).DisplayStart + 1
            disp_end = unsafe_load(clipper).DisplayEnd
            state.range = disp_start : disp_end # сохраняем в состоянии

            for row in state.range
                CImGui.TableNextRow(CImGui.LibCImGui.ImGuiTableRowFlags_Headers,-1)
                is_selected = state.iselected == row
                for col in 0:N-1
                    CImGui.TableSetColumnIndex(col)
                    val = cols_data[col+1][row]
                    txt = string(val)
                    if (col == 0) # первая колонка = строка с выбором,
                        # добавил ###row т.к. лейблы Selectable должны быть уникальными, иначе выбор не работает (что бы мог подумать?)
                        if CImGui.Selectable(txt * "###$row", is_selected, CImGui.LibCImGui.ImGuiSelectableFlags_SpanAllColumns) # | CImGui.LibCImGui.ImGuiSelectableFlags_AllowItemOverlap)
                            state.iselected = row
                            if CImGui.IsItemHovered() # клик был чуть раньше... && CImGui.IsMouseClicked(0)
                                state.changed_from_outside = false
                                state.cursor = val
                                @info "changed!"
                                cursor_ref[] = val # выдаем событие наружу, только когда действуем в текущем окне
                            end
                        end
                    else
                        CImGui.TextUnformatted(txt)
                    end
                end
                if (is_selected)
                    CImGui.SetItemDefaultFocus()
                end
            end
        end
        if CImGui.IsWindowHovered()
            state.changed_from_outside = false
        end
        if state.changed_from_outside && (state.iselected < first(state.range) || last(state.range) < state.iselected) # если выбрана строка вне текущей области - скроллим туда!
            top_row = max(1, state.iselected - length(state.range) ÷ 2) # учитываем, чтобы выбранная строка была в центре скролла
            scroll = Float64(top_row) / (length(table_data)-length(state.range)) * CImGui.GetScrollMaxY() # позиция
            CImGui.SetScrollY(scroll)
        end

        CImGui.EndTable()
    end


    
end
