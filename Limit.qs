// testing the limits of q#

namespace Limit {
    import Std.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Convert.IntAsBoolArray;
    open Microsoft.Quantum.Arrays;

    @EntryPoint()
    operation Main() : Unit {
        use testQs = Qubit[16];
        ApplyHAll(testQs);

        ApplyCNOTChain(testQs);

        DumpMachine();

        ResetAll(testQs);
    }
    operation ApplyHAll(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            H(qubits[i]);
        }
    }
}