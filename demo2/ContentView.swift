import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)

                Text("摩斯输入法")
                    .font(.largeTitle.bold())

                Text("打字即出码：按下按键，输入框里出现的是对应的摩斯密码")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 14) {
                    step(1, "打开「设置」→「通用」→「键盘」")
                    step(2, "点「键盘」→「添加新键盘…」")
                    step(3, "选择「摩斯键盘」")
                    step(4, "在任意输入框长按 🌐 切换到摩斯键盘")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("键盘布局").font(.headline)
                    Text("• 第 1 行：数字 0-9")
                    Text("• 第 2-4 行：26 个字母（无大小写）与标点 ， 。 ？")
                    Text("• 空格键输出 /（摩斯码的词分隔符）")
                    Text("• 每个字符的摩斯码后自动补一个空格分隔")
                }
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                Text("示例：SOS → ... --- ...")
                    .font(.title3.monospaced())
                    .foregroundStyle(.blue)

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemBackground))
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(Circle().fill(.blue))
                .foregroundStyle(.white)
            Text(text)
        }
    }
}
