import SwiftUI

struct BirthdayPickerView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedDate: Date
    @State private var age: Int = 0
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 1920, month: 1, day: 1)
        let endComponents = DateComponents(year: calendar.component(.year, from: Date()),
                                           month: calendar.component(.month, from: Date()),
                                           day: calendar.component(.day, from: Date()))
        return calendar.date(from:startComponents)!
            ...
            calendar.date(from:endComponents)!
    }()
    
    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        let age = ageFromBirthday( selectedDate.wrappedValue)
        _age = State(initialValue: age)
    }
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                DatePicker(
                    "Birthday picker",
                    selection: $selectedDate,
                    in: dateRange,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: selectedDate) { oldValue, newValue in
                    self.age = ageFromBirthday(newValue)
                }
                
                Section {
                    Stepper("unit_age\(age)", value: $age, in: 0...130, step: 1)

                } header: {
                    Text("Remember age of contact?")
                } footer: {
                    Text("Can't remember their year of birth? Enter the years they are.")
                }

                .onChange(of: age) { oldValue, newValue in
                    self.selectedDate = calculateBirthday(referenceDate: self.selectedDate, age: newValue)
                }
                
                Button("action_today") {
                    self.selectedDate = Date()
                }
            }
            .navigationTitle("Select date of birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                doneToolbar
            }
        }
    }

    
    @ToolbarContentBuilder
    private var doneToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction, content: {
            Button("action_done", action: {
                 dismiss()
            })
        })
    }
    
    private func calculateBirthday(referenceDate: Date, age: Int) -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Obtener los componentes de fecha actuales
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentDay = calendar.component(.day, from: currentDate)
        
        // Obtener los componentes de fecha de referencia
        //let referenceYear = calendar.component(.year, from: referenceDate)
        let referenceMonth = calendar.component(.month, from: referenceDate)
        let referenceDay = calendar.component(.day, from: referenceDate)
        
        // Calcular el año de nacimiento
        var birthYear = currentYear - age
        
        // Ajustar el año si la fecha de nacimiento ya ha pasado este año
        if currentMonth < referenceMonth || (currentMonth == referenceMonth && currentDay < referenceDay) {
            birthYear -= 1
        }
        
        // Crear la fecha de nacimiento
        return calendar.date(from: DateComponents(year: birthYear, month: referenceMonth, day: referenceDay)) ?? Date()
    }
    
    private func ageFromBirthday(_ birthday: Date) -> Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: currentDate)
        return (ageComponents.year ?? 0)
    }
}

struct BirthdayPickerPlayground : View {
    @State private var selectedDate: Date
    @State private var isPresentingPicker = false

    init() {
        _selectedDate = State(initialValue: Calendar.current.date(byAdding: .year, value: -18, to: Date())!)
    }
    
    var body: some View {
        VStack {
            
            LabeledContent("Fecha de nacimiento", value: selectedDate, format: .dateTime.year().month().day())
        }
        Button("Show Birthday Picker") {
            isPresentingPicker.toggle()
        }
        .sheet(isPresented: $isPresentingPicker) {
             BirthdayPickerView(selectedDate: $selectedDate)
        }
        .padding()
    }
}

#Preview {
    BirthdayPickerPlayground()
}
