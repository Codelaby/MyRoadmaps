//
//  DateField.swift
//  FieldsPlayground
//
//  Created by Codelaby on 25/10/24.
//

import SwiftUI

struct DateActionButton: ViewModifier {
    @Binding var selectedDate: Date // Enlace a la fecha seleccionada
    @State private var showDatePicker = false // Control para mostrar/ocultar el DatePicker


    public func body(content: Content) -> some View {
        HStack(alignment: .center) {
            content

            // Botón para mostrar el DatePicker
            Button(action: {
                showDatePicker.toggle()
            }) {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
            }
        }
        // Modal con el DatePicker
        .sheet(isPresented: $showDatePicker) {
            VStack {
                Text("Select Date")
                    .font(.headline)
                    .padding()
                
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                
                Button("Done") {
                    showDatePicker = false
                }
                .padding()
            }
        }
    }
}

extension View {
    func dateActionButton(selectedDate: Binding<Date>) -> some View {
        self.modifier(DateActionButton(selectedDate: selectedDate))
    }
}


struct DateField: View {
    @Binding var selectedDate: Date // Enlace a la fecha seleccionada desde el exterior
    @State private var dateText = "" // Variable de estado para el texto del TextField
    @State private var errorMessage: String? = nil // Mensaje de error para la fecha

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short //especifica el formato de fecha corta
        return formatter
    }

    var body: some View {
        VStack() {

            TextField("Enter a date...", text: $dateText, onCommit: validateDate)
                .dateActionButton(selectedDate: $selectedDate)
                .frame(maxWidth: .infinity, maxHeight: 48)
                .padding(.horizontal)
                .background(Color(uiColor: UIColor.systemBackground), in: .rect(cornerRadius: 16))
                .shadow(color: .gray.opacity(0.3), radius: 6, x: 0, y: 0)
                .padding(.horizontal)
            
            // Mostrar mensaje de error si la fecha no es válida
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

        }
        .onAppear {
            // Inicializar el campo de texto con la fecha seleccionada al cargar la vista
            dateText = dateFormatter.string(from: selectedDate)
        }
        .onChange(of: selectedDate) { oldDate, newDate in
            // Actualizar el texto del TextField cuando cambia la fecha seleccionada
            dateText = dateFormatter.string(from: newDate)
            
            // Limpiar el mensaje de error ya que la fecha proven del datepicker
            errorMessage = errorMessage != nil ? nil : errorMessage
        }
    }
    
    // Función para validar la fecha ingresada manualmente, manteniendo la hora
    private func validateDate() {
        if let newDateOnly = dateFormatter.date(from: dateText) {
            // Obtener los componentes actuales de hora de `selectedDate`
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: selectedDate)
            
            // Combinar la fecha ingresada con los componentes de hora actuales
            if let finalDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                             minute: timeComponents.minute ?? 0,
                                             second: timeComponents.second ?? 0,
                                             of: newDateOnly) {
                selectedDate = finalDate
                errorMessage = nil // Limpiar el mensaje de error si la fecha es válida
            }
        } else {
            errorMessage = "La fecha ingresada no es válida. Por favor, usa el formato correcto."
        }
    }
}

#Preview {
    
    struct PreviewWrapper: View {
        
        @State private var selectedDate = Date() // Estado externo para la fecha seleccionada

        var body: some View {
            
            VStack {
                Spacer()
                DateField(selectedDate: $selectedDate)
                
                Spacer()
                Text("Fecha seleccionada: \(selectedDate, format: .dateTime)")
                Spacer()

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.2))
        }
    }
    
    return PreviewWrapper()
}
