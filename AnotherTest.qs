// testing to see if a certain algorithm could peform a calculation but keep a superposition afterwards

// ok so now with this working i have some important notes to share with any weary traveler
// we only measure the first qubit, and let it interact with the other but most importantly DONT LET A QUBIT INTERACT WITH IT
// that way when we measure the first qubit, the rest of the circuit remains in a superposition

namespace AnotherTest {
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;

    @EntryPoint()
    operation Main() : Unit {
        use qubits = Qubit[3];
        use retain = Qubit[1]; // qubits whose superpositions we want to maintain

        H(qubits[0]);
        X(qubits[1]);
        H(qubits[1]);
        ApplyHAll(retain);

        CCNOT(qubits[0], retain[0], qubits[2]);
        CNOT(qubits[2], qubits[1]);
        CCNOT(qubits[0], retain[0], qubits[2]);

        M(qubits[0]);

        DumpMachine();

        ResetAll(qubits);
        ResetAll(retain);
    }


    operation ApplyHAll(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            H(qubits[i]);
        }
    }
}