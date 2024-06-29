// trying to test "Diffusion operator"

namespace Test {
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;
    @EntryPoint()
    operation Main() : Unit {
        use qubits = Qubit[3];
        use phaseInverter = Qubit();

        ApplyHAll(qubits);

        // set up phase inversion
        X(phaseInverter);
        H(phaseInverter);

        // search for 001
        X(qubits[0]);
        X(qubits[1]);
        CCCNOT(qubits[0], qubits[1], qubits[2], phaseInverter);
        X(qubits[1]);
        X(qubits[0]);

        // attempt diffusion operator
        ApplyHAll(qubits);
        ApplyXAll(qubits);
        CCCNOT(qubits[0], qubits[1], qubits[2], phaseInverter);
        ApplyXAll(qubits);
        ApplyHAll(qubits);

        DumpMachine();

        ResetAll(qubits);
        Reset(phaseInverter);
    }

    operation ApplyHAll(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            H(qubits[i]);
        }
    }
    operation ApplyXAll(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            X(qubits[i]);
        }
    }

    // applies an extension of the CNOT family to include a third control
    operation CCCNOT(control1 : Qubit, control2 : Qubit, control3 : Qubit, target : Qubit) : Unit {
        use ancillia = Qubit();

        CCNOT(control1, control2, ancillia);
        CCNOT(control3, ancillia, target);
        CCNOT(control1, control2, ancillia); // return ancillia back to |0> so it can be deallocated

        Reset(ancillia);
    }
}