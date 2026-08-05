import SwiftUI
import UniformTypeIdentifiers

struct QuickAccessBar: View {
    let availableTools: [ToolDefinition]
    let savedToolIDs: [ToolDefinition.ID]
    let maximumCount: Int
    let selectTool: (ToolDefinition) -> Void
    let save: ([ToolDefinition.ID]) -> Void

    @Namespace private var glassNamespace
    @State private var draftToolIDs: [ToolDefinition.ID] = []
    @State private var isEditing = false
    @State private var isShowingToolPicker = false
    @State private var hoveredToolID: ToolDefinition.ID?
    @State private var draggingToolID: ToolDefinition.ID?
    @State private var settlingToolID: ToolDefinition.ID?
    @State private var settlingDelay: Duration = .milliseconds(80)
    @State private var lastDropDestinationID: ToolDefinition.ID?

    private var displayedToolIDs: [ToolDefinition.ID] {
        isEditing ? draftToolIDs : savedToolIDs
    }

    private var displayedTools: [ToolDefinition] {
        displayedToolIDs.compactMap(tool(id:))
    }

    private var availableToAdd: [ToolDefinition] {
        availableTools.filter { !displayedToolIDs.contains($0.id) }
    }

    private var canAddTool: Bool {
        displayedTools.count < maximumCount && !availableToAdd.isEmpty
    }

    private var hoveredTool: ToolDefinition? {
        hoveredToolID.flatMap(tool(id:))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            GlassEffectContainer(spacing: 8) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(displayedTools) { tool in
                            quickAccessItem(tool)
                        }

                        #if !os(watchOS)
                        HStack(spacing: 0) {
                            if isEditing {
                                addButton
                                    .transition(.scale.combined(with: .opacity))
                            }
                            editButton
                        }
                        #endif
                    }
                    .padding(.top, isEditing ? 9 : 2)
                    .padding(.bottom, 6)
                    .padding(.horizontal, 2)
                }
                .scrollIndicators(.never)
            }

            hoverLabel
        }
        .onAppear {
            draftToolIDs = savedToolIDs
        }
        .onChange(of: savedToolIDs) { _, newValue in
            if !isEditing {
                draftToolIDs = newValue
            }
        }
        .task(id: settlingToolID) {
            guard let settlingToolID else { return }

            try? await Task.sleep(for: settlingDelay)
            if self.settlingToolID == settlingToolID {
                self.settlingToolID = nil
            }
        }
        #if !os(watchOS)
        .popover(isPresented: $isShowingToolPicker) {
            QuickAccessToolPicker(
                tools: availableToAdd,
                add: add
            )
        }
        #endif
    }

    @ViewBuilder
    private func quickAccessItem(_ tool: ToolDefinition) -> some View {
        let item = QuickAccessToolButton(
            tool: tool,
            isEditing: isEditing,
            isDragging: draggingToolID == tool.id || settlingToolID == tool.id,
            glassNamespace: glassNamespace,
            hoverChanged: { isHovering in
                if isHovering {
                    hoveredToolID = tool.id
                } else if hoveredToolID == tool.id {
                    hoveredToolID = nil
                }
            },
            action: { selectTool(tool) }
        )
        .overlay(alignment: .topTrailing) {
            if isEditing
                && draggingToolID != tool.id
                && settlingToolID != tool.id {
                Button {
                    remove(tool.id)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .toolPouchIcon(.small, weight: .semibold)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .offset(x: 7, y: -7)
                .zIndex(2)
                .help("Remove from Quick Access")
                .accessibilityLabel("Remove \(tool.title) from Quick Access")
            }
        }
        .zIndex(isEditing ? 1 : 0)

        #if os(watchOS)
        item
        #else
        if isEditing {
            item
                .onDrag {
                    settlingToolID = nil
                    draggingToolID = tool.id
                    lastDropDestinationID = tool.id
                    return NSItemProvider(object: tool.id.rawValue as NSString)
                } preview: {
                    QuickAccessDragPreview(tool: tool)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: QuickAccessReorderDropDelegate(
                        destinationID: tool.id,
                        draggingToolID: $draggingToolID,
                        settlingToolID: $settlingToolID,
                        lastDropDestinationID: $lastDropDestinationID,
                        toolIDs: $draftToolIDs
                    )
                )
                #if os(macOS)
                .onDragSessionUpdated { session in
                    handleDragSessionUpdate(session, toolID: tool.id)
                }
                #endif
        } else {
            item
        }
        #endif
    }

    private var hoverLabel: some View {
        Group {
            if isEditing {
                Label("Drag shortcuts to reorder", systemImage: "arrow.left.and.right")
            } else if let hoveredTool {
                Label(hoveredTool.title, systemImage: hoveredTool.systemImage)
            } else {
                Text(" ")
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(height: 18)
        .padding(.horizontal, 4)
        .animation(.easeOut(duration: 0.12), value: hoveredToolID)
    }

    #if !os(watchOS)
    private var addButton: some View {
        Button {
            isShowingToolPicker = true
        } label: {
            Image(systemName: "plus")
                .toolPouchIcon(.medium, weight: .medium)
                .frame(width: 24, height: 24)
                .padding(7)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .disabled(!canAddTool)
        .help(
            canAddTool
                ? "Add a Tool to Quick Access"
                : "Quick Access Is Full"
        )
        .accessibilityLabel("Add a Tool to Quick Access")
    }

    private var editButton: some View {
        Button {
            if isEditing {
                save(draftToolIDs)
            } else {
                draftToolIDs = savedToolIDs
            }
            withAnimation(.snappy(duration: 0.22)) {
                isEditing.toggle()
            }
            draggingToolID = nil
            settlingToolID = nil
            lastDropDestinationID = nil
        } label: {
            Image(systemName: isEditing ? "checkmark" : "pencil")
                .toolPouchIcon(.medium, weight: .medium)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 24, height: 24)
                .padding(7)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEditing ? Color.accentColor : Color.secondary)
        .help(isEditing ? "Save Quick Access" : "Edit Quick Access")
        .accessibilityLabel(
            isEditing ? "Save Quick Access" : "Edit Quick Access"
        )
    }
    #endif

    private func tool(id: ToolDefinition.ID) -> ToolDefinition? {
        availableTools.first { $0.id == id }
    }

    private func add(_ tool: ToolDefinition) {
        guard displayedToolIDs.count < maximumCount else { return }

        if isEditing {
            draftToolIDs.append(tool.id)
        } else {
            save(savedToolIDs + [tool.id])
        }
        isShowingToolPicker = false
    }

    private func remove(_ toolID: ToolDefinition.ID) {
        withAnimation(.snappy(duration: 0.2)) {
            draftToolIDs.removeAll { $0 == toolID }
        }
    }

    #if os(macOS)
    private func handleDragSessionUpdate(
        _ session: DragSession,
        toolID: ToolDefinition.ID
    ) {
        switch session.phase {
        case .initial, .active:
            break
        case .ended(_), .dataTransferCompleted:
            finishDrag(toolID: toolID, releaseLocation: session.location)
        @unknown default:
            finishDrag(toolID: toolID, releaseLocation: session.location)
        }
    }

    private func finishDrag(
        toolID: ToolDefinition.ID,
        releaseLocation: CGPoint
    ) {
        guard draggingToolID == toolID else { return }

        let placeholderCenter = CGPoint(x: 19, y: 19)
        let distance = hypot(
            releaseLocation.x - placeholderCenter.x,
            releaseLocation.y - placeholderCenter.y
        )
        let landingDuration = min(max(distance / 1_600, 0.025), 0.28)

        settlingDelay = .milliseconds(Int64(landingDuration * 1_000))
        settlingToolID = toolID
        draggingToolID = nil
        lastDropDestinationID = nil
    }
    #endif

}

private struct QuickAccessToolButton: View {
    let tool: ToolDefinition
    let isEditing: Bool
    let isDragging: Bool
    let glassNamespace: Namespace.ID
    let hoverChanged: (Bool) -> Void
    let action: () -> Void

    @ViewBuilder
    var body: some View {
        if isDragging {
            Color.clear
                .frame(width: 38, height: 38)
                .contentShape(.circle)
                .accessibilityHidden(true)
        } else {
            Button {
                if !isEditing {
                    action()
                }
            } label: {
                Image(systemName: tool.systemImage)
                    .toolPouchIcon(.medium, weight: .medium)
                    .frame(width: 24, height: 24)
                    .padding(7)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .glassEffectID(tool.id.rawValue, in: glassNamespace)
            #if os(macOS) || os(iOS)
            .onHover(perform: hoverChanged)
            #endif
            .help(tool.description)
            .accessibilityLabel(tool.title)
            .accessibilityHint(tool.description)
        }
    }
}

#if !os(watchOS)
private struct QuickAccessReorderDropDelegate: DropDelegate {
    let destinationID: ToolDefinition.ID
    @Binding var draggingToolID: ToolDefinition.ID?
    @Binding var settlingToolID: ToolDefinition.ID?
    @Binding var lastDropDestinationID: ToolDefinition.ID?
    @Binding var toolIDs: [ToolDefinition.ID]

    func dropEntered(info: DropInfo) {
        guard let draggingToolID,
              draggingToolID != destinationID,
              lastDropDestinationID != destinationID,
              let sourceIndex = toolIDs.firstIndex(of: draggingToolID),
              let destinationIndex = toolIDs.firstIndex(of: destinationID)
        else { return }

        lastDropDestinationID = destinationID

        withAnimation(.snappy(duration: 0.18)) {
            toolIDs.move(
                fromOffsets: IndexSet(integer: sourceIndex),
                toOffset: destinationIndex > sourceIndex
                    ? destinationIndex + 1
                    : destinationIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        #if os(macOS)
        lastDropDestinationID = nil
        #else
        settlingToolID = draggingToolID
        draggingToolID = nil
        lastDropDestinationID = nil
        #endif
        return true
    }
}

private struct QuickAccessDragPreview: View {
    let tool: ToolDefinition

    var body: some View {
        Image(systemName: tool.systemImage)
            .toolPouchIcon(.medium, weight: .medium)
            .frame(width: 24, height: 24)
            .padding(9)
            .background(.regularMaterial, in: .circle)
            .overlay {
                Circle()
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            }
    }
}
#endif

#if !os(watchOS)
private struct QuickAccessToolPicker: View {
    let tools: [ToolDefinition]
    let add: (ToolDefinition) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add to Quick Access")
                .font(.headline)

            if tools.isEmpty {
                ContentUnavailableView(
                    "No More Tools",
                    systemImage: "checkmark.circle",
                    description: Text("All available tools are already added.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(tools) { tool in
                            Button {
                                add(tool)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: tool.systemImage)
                                        .toolPouchIcon(.medium)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tool.title)
                                            .font(.headline)
                                        Text(tool.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Image(systemName: "plus.circle")
                                        .toolPouchIcon(.medium)
                                }
                                .padding(8)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 320, height: 340)
    }
}
#endif
