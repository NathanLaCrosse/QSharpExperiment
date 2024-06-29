namespace Arrays {
    open Microsoft.Quantum.Diagnostics;
    @EntryPoint()
    operation BasicEntangledState() : Result[] {
        use qubits = Qubit[2];

        H(qubits[0]);
        CNOT(qubits[0], qubits[1]);

        DumpMachine(); // DumpMachine is essentially a print method for the overall state of the simulated quantum computer,
                       // which displays the amplitude, probability and phase of its qubits 

        let measurement = MeasureEachZ(qubits);

        ResetAll(qubits);

        return measurement;
    }
}