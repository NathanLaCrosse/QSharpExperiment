// a program to test out a CCCNOT gate

namespace CCCNOTGate {
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Diagnostics;
    @EntryPoint()
    operation Main() : Unit {
        use qubits = Qubit[3];
        use output = Qubit();

        for i in IndexRange(qubits) {
            H(qubits[i]);
        }

        //CCCNOT(qubits[0],qubits[1],qubits[2],output);
        CCCNOT(qubits, output);

        DumpMachine();

        ResetAll(qubits);
        Reset(output);
    }

    // operation CCCNOT(control1 : Qubit, control2 : Qubit, control3 : Qubit, target : Qubit) : Unit {
    //     use ancillia = Qubit();

    //     CCNOT(control1, control2, ancillia);
    //     CCNOT(control3, ancillia, target);
    //     CCNOT(control1, control2, ancillia); // return ancillia back to |0>

    //     Reset(ancillia);
    // }

    operation CCCNOT(control : Qubit[], target : Qubit) : Unit {
        (Controlled X)(control, target);
    }
}