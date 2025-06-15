import SwiftUI

// MARK: - Model
struct Habit: Identifiable, Codable {
    let id: UUID
    let name: String
    var isCompleted: Bool

    init(id: UUID = UUID(), name: String, isCompleted: Bool) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
    }
}

// MARK: - ViewModel
class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] {
        didSet {
            saveHabits()
        }
    }

    private let saveKey = "SavedHabits"
    private let lastResetKey = "LastResetDate"

    init() {
        // Initialize habits first
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            self.habits = decoded
        } else {
            self.habits = [
                Habit(name: "Drink Water", isCompleted: false),
                Habit(name: "Exercise", isCompleted: false),
                Habit(name: "Read", isCompleted: false)
            ]
        }

        // Then check for daily reset
        checkAndResetForNewDay()
    }

    func toggleHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isCompleted.toggle()
        }
    }

    func addHabit(name: String) {
        let newHabit = Habit(name: name, isCompleted: false)
        habits.append(newHabit)
    }

    func deleteHabit(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
    }

    func resetHabits() {
        for index in habits.indices {
            habits[index].isCompleted = false
        }
        saveLastResetDate()
    }

    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func saveLastResetDate() {
        let today = Date()
        UserDefaults.standard.set(today, forKey: lastResetKey)
    }

    private func checkAndResetForNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = UserDefaults.standard.object(forKey: lastResetKey) as? Date {
            let last = calendar.startOfDay(for: lastDate)
            if last < today {
                resetHabits()
            }
        } else {
            saveLastResetDate() // First-time use
        }
    }
}

// MARK: - View
struct ContentView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var showingAddHabit = false
    @State private var newHabitName = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.habits) { habit in
                    HStack {
                        Text(habit.name)
                        Spacer()
                        Button(action: {
                            viewModel.toggleHabit(habit)
                        }) {
                            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(habit.isCompleted ? .green : .gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 5)
                }
                .onDelete(perform: viewModel.deleteHabit)
            }
            .navigationTitle("Today's Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.resetHabits()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                VStack(spacing: 20) {
                    Text("Add a New Habit")
                        .font(.headline)

                    TextField("Habit name", text: $newHabitName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("Add") {
                        if !newHabitName.isEmpty {
                            viewModel.addHabit(name: newHabitName)
                            newHabitName = ""
                            showingAddHabit = false
                        }
                    }
                    .padding()
                }
                .padding()
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

