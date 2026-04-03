import SwiftUI

struct StaffPicker: View {
    @Binding var selection: StaffMember?
    let staff: [StaffMember]
    var label: String = "員工"

    var body: some View {
        Picker(label, selection: $selection) {
            Text("請選擇").tag(nil as StaffMember?)
            ForEach(staff) { member in
                Text(member.name).tag(member as StaffMember?)
            }
        }
    }
}
