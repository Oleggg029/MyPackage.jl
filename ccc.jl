function display_content(state)
    CImGui.Begin("File information")
        for n in 1:length(state.channels)
            channel = state.channels[n]
            CImGui.Text("Channel $n: " * channel);
        end
    CImGui.Text("Date: " * string(state.date));
    CImGui.End()
#hdrjryuukfk


end