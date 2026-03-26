import Foundation

@Observable
class StaffManageStore {
    var providerId: String = ""

    // Staff
    var staff: [StaffMember] = []
    var staffSchedules: [String: [StaffSchedule]] = [:] // keyed by staffId
    var staffExceptions: [StaffException] = []
    var timeSlots: [TimeSlot] = []
    var staffInvitations: [StaffInvitation] = []
    var staffPerformance: [StaffPerformance] = []

    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    // MARK: - Staff CRUD

    func loadStaff() async {
        do {
            staff = try await api.get(
                path: APIEndpoints.Staff.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createStaffMember(_ body: [String: Any]) async {
        isLoading = true
        do {
            let member: StaffMember = try await api.post(path: APIEndpoints.Staff.create, body: JSONBody(body))
            staff.append(member)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func updateStaffMember(id: String, body: [String: Any]) async {
        isLoading = true
        do {
            let updated: StaffMember = try await api.patch(path: APIEndpoints.Staff.update(id), body: JSONBody(body))
            if let idx = staff.firstIndex(where: { $0.id == id }) {
                staff[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteStaffMember(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.Staff.delete(id))
            staff.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Staff Schedules

    func loadStaffSchedules(staffIds: [String]) async {
        do {
            let ids = staffIds.joined(separator: ",")
            let schedules: [StaffSchedule] = try await api.get(
                path: APIEndpoints.Staff.schedulesList,
                queryItems: [URLQueryItem(name: "staffIds", value: ids)]
            )
            var grouped: [String: [StaffSchedule]] = [:]
            for schedule in schedules {
                if let staffId = schedule.staffId {
                    grouped[staffId, default: []].append(schedule)
                }
            }
            staffSchedules = grouped
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateStaffSchedule(staffId: String, schedules: [[String: Any]]) async {
        isLoading = true
        do {
            let _: [StaffSchedule] = try await api.put(
                path: APIEndpoints.Staff.schedules(staffId),
                body: JSONBody(["schedules": schedules])
            )
            await loadStaffSchedules(staffIds: [staffId])
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Staff Exceptions

    func loadStaffExceptions(staffIds: [String]) async {
        do {
            let ids = staffIds.joined(separator: ",")
            staffExceptions = try await api.get(
                path: APIEndpoints.Staff.exceptions,
                queryItems: [URLQueryItem(name: "staffIds", value: ids)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createStaffException(_ body: [String: Any]) async {
        isLoading = true
        do {
            let exception: StaffException = try await api.post(
                path: APIEndpoints.Staff.exceptions,
                body: JSONBody(body)
            )
            staffExceptions.append(exception)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteStaffException(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.Staff.deleteException(id))
            staffExceptions.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Time Slots

    func loadTimeSlots(staffId: String, dates: [String]) async {
        do {
            let dateStr = dates.joined(separator: ",")
            timeSlots = try await api.get(
                path: APIEndpoints.Staff.timeSlots(staffId),
                queryItems: [URLQueryItem(name: "dates", value: dateStr)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createTimeSlot(staffId: String, date: String, startTime: String, endTime: String) async {
        isLoading = true
        do {
            let slot: TimeSlot = try await api.post(
                path: APIEndpoints.Staff.timeSlots(staffId),
                body: ["date": date, "startTime": startTime, "endTime": endTime]
            )
            timeSlots.append(slot)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteTimeSlot(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.Staff.deleteTimeSlot(id))
            timeSlots.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Staff Invitations

    func loadStaffInvitations() async {
        do {
            staffInvitations = try await api.get(
                path: APIEndpoints.Staff.invitations,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createStaffInvitation(email: String, role: StaffRole) async {
        isLoading = true
        do {
            let invitation: StaffInvitation = try await api.post(
                path: APIEndpoints.Staff.invitations,
                body: JSONBody([
                    "providerId": providerId,
                    "email": email,
                    "role": role.rawValue
                ] as [String: Any])
            )
            staffInvitations.append(invitation)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Staff Performance

    func loadStaffPerformance() async {
        isLoading = true
        do {
            staffPerformance = try await api.get(
                path: APIEndpoints.Stats.staffPerformance,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
