import SwiftUI
import SwiftData
import PhotosUI

/// 用来在页面之间传递图片（sheet(item:) 需要 Identifiable）
struct PickedImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ContentView: View {
    @State private var showCamera = false          // 是否显示相机
    @State private var showNoCameraAlert = false   // 没有相机时的提示
    @State private var capturedImage: UIImage?     // 相机拍到的照片（临时保存）

    @State private var showPhotoPicker = false         // 是否显示相册
    @State private var selectedItem: PhotosPickerItem? // 相册里选中的项目
    @State private var pickedImage: PickedImage?       // 要拿去识别的图片

    @State private var showFavorites = false           // 是否显示收藏列表
    @State private var showAISearch = false            // 是否显示 AI 搜索

    var body: some View {
        ZStack {
            // 背景
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // MARK: 中间的相机大按钮
                Button {
                    openCamera()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                        Text("相机")
                            .font(.title2)
                            .bold()
                    }
                    .foregroundStyle(.white)
                    .frame(width: 280, height: 280)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }

                // MARK: 功能区

                    HStack(spacing: 20) {
                        FeatureButton(title: "相册", icon: "photo.on.rectangle") {
                            showPhotoPicker = true
                        }
                        FeatureButton(title: "AI搜索", icon: "magnifyingglass") {
                            showAISearch = true
                        }
                        FeatureButton(title: "收藏", icon: "heart.fill") {
                            showFavorites = true
                        }
                    }
                

                Spacer()
            }
        }
        // 全屏打开相机
        // onDismiss：相机完全关闭之后才执行，这时再打开结果页，两个页面不会冲突
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if let image = capturedImage {
                pickedImage = PickedImage(image: image)
                capturedImage = nil   // 用完清空，下次重新拍
            }
        }) {
            CameraView(image: $capturedImage)
                .ignoresSafeArea()
        }
        // 全屏打开收藏列表
        .fullScreenCover(isPresented: $showFavorites) {
            FavoritesView()
        }
        // 全屏打开 AI 搜索
        .fullScreenCover(isPresented: $showAISearch) {
            AISearchView()
        }
        // 打开系统相册（只显示图片）
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $selectedItem,
                      matching: .images)
        // 选好图片后，读取图片数据
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedImage = PickedImage(image: image)
                }
                selectedItem = nil   // 清空，方便下次再选同一张
            }
        }
        // 有图片后弹出识别结果页（相机和相册共用）
        .sheet(item: $pickedImage) { picked in
            ResultView(image: picked.image)
        }
        // 模拟器等没有相机的设备会弹出提示
        .alert("无法使用相机", isPresented: $showNoCameraAlert) {
            Button("好", role: .cancel) { }
        } message: {
            Text("这台设备没有相机。模拟器不支持相机，请在真机 iPhone 上运行。")
        }
    }

    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCamera = true
        } else {
            showNoCameraAlert = true
        }
    }
}

// MARK: 橙色功能按钮（可重复使用）
struct FeatureButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 80, height: 80)
                    .background(Color.appAccentLight)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedNote.self, inMemory: true)
}
