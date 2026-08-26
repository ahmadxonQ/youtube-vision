import SwiftUI

struct PlayerBarView: View {
    @EnvironmentObject var vm: PlayerViewModel
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if vm.currentTrack != nil {
                playerContent
            } else {
                emptyContent
            }
        }
        .frame(minWidth: 500, maxWidth: .infinity)
        .background(
            VisionTheme.surface.opacity(0.88)
                .clipShape(RoundedRectangle(cornerRadius: VisionTheme.barCornerRadius))
        )
        .background(
            VisualEffectBlur()
                .clipShape(RoundedRectangle(cornerRadius: VisionTheme.barCornerRadius))
        )
        .clipShape(RoundedRectangle(cornerRadius: VisionTheme.barCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: VisionTheme.barCornerRadius)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: - Player (has track)

    private var playerContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Drag handle (⠿ grip dots)
                VStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 2) {
                            Circle().frame(width: 3, height: 3)
                            Circle().frame(width: 3, height: 3)
                        }
                    }
                }
                .foregroundColor(VisionTheme.textMuted.opacity(0.35))
                .frame(width: 10)

                // Wave bars
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { i in
                        WaveBar(isPlaying: vm.isPlaying, index: i, color: theme.current.waveColors[i])
                    }
                }
                .frame(width: 24, height: 24)

                // Title + time
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.currentTrack?.title ?? "Nothing playing")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VisionTheme.textPrimary)
                        .lineLimit(1)

                    Text("\(vm.currentTimeFormatted) / \(vm.durationFormatted) · \(vm.speedLabel)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(VisionTheme.textMuted)
                }

                Spacer(minLength: 4)

                // Controls
                controlButtons

                // Power menu
                Menu {
                    // Theme picker
                    Menu {
                        ForEach(ColorTheme.allCases, id: \.self) { t in
                            Button {
                                theme.current = t
                            } label: {
                                HStack {
                                    Text(t.rawValue)
                                    if theme.current == t {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Theme", systemImage: "paintpalette")
                    }

                    Divider()

                    Button {
                        NSApp.keyWindow?.orderOut(nil)
                    } label: {
                        Label("Hide Player", systemImage: "eye.slash")
                    }

                    Button(role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Label("Quit YouTube Vision", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(VisionTheme.textMuted)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 20)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(VisionTheme.border)
                    Rectangle().fill(VisionTheme.accentGradient)
                        .frame(width: geo.size.width * vm.progress)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    vm.seek(to: location.x / geo.size.width)
                }
            }
            .frame(height: 5)
            .clipShape(RoundedRectangle(cornerRadius: 2.5))
        }
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 8) {
            Button { vm.previousTrack() } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(VisionTheme.textMuted)

            Button { vm.togglePlay() } label: {
                Circle()
                    .fill(VisionTheme.accentGradient)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .offset(x: vm.isPlaying ? 0 : 1)
                    )
            }
            .buttonStyle(.plain)

            Button { vm.nextTrack() } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(VisionTheme.textMuted)

            Button { vm.cycleSpeed() } label: {
                Text(vm.speedLabel)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(VisionTheme.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(VisionTheme.border)
                    )
            }
            .buttonStyle(.plain)

            // Volume
            HStack(spacing: 4) {
                Image(systemName: vm.volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 11))
                    .foregroundColor(VisionTheme.textMuted)
                    .onTapGesture { vm.toggleMute() }

                CustomSlider(value: Binding(
                    get: { vm.volume },
                    set: { vm.setVolume($0) }
                ), range: 0...100)
                    .frame(width: 90, height: 14)
            }
        }
        .fixedSize()
    }

    // MARK: - Empty state

    private var emptyContent: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Menu {
                    Button("Quit YouTube Vision", role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(VisionTheme.textMuted)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 20)
            }
            .padding(.trailing, 12)
            .padding(.top, 8)

            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(VisionTheme.accent)

                Text("YouTube Vision")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(VisionTheme.textPrimary)
            }

            Text("Play a YouTube video in Chrome — it will appear here automatically.")
                .font(.system(size: 11))
                .foregroundColor(VisionTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Wave Bar

private struct WaveBar: View {
    let isPlaying: Bool
    let index: Int
    let color: Color

    private static let heights: [CGFloat] = [14, 20, 10, 17]
    private static let durations: [Double] = [0.3, 0.4, 0.35, 0.32]

    @State private var animating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 3, height: animating ? Self.heights[index] : 4)
            .animation(
                animating
                    ? .easeInOut(duration: Self.durations[index])
                      .repeatForever(autoreverses: true)
                      .delay(Double(index) * 0.08)
                    : .easeOut(duration: 0.2),
                value: animating
            )
            .onChange(of: isPlaying) { _, playing in
                animating = playing
            }
            .onAppear {
                animating = isPlaying
            }
    }
}

// MARK: - Visual Effect Blur (NSVisualEffectView wrapper)

private struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Custom Slider (always shows accent color)

private struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbX = fraction * geo.size.width

            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(VisionTheme.border)
                    .frame(height: 4)

                // Filled track
                Capsule()
                    .fill(VisionTheme.accentGradient)
                    .frame(width: max(0, thumbX), height: 4)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                    .offset(x: max(0, thumbX - 5))
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let fraction = max(0, min(1, drag.location.x / geo.size.width))
                        value = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
                    }
            )
        }
    }
}
