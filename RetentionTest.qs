// This program is an example of a (slightly contrived) way to retain a qubit's superposition after doing Grover's algorithm
// currently this only works with the Hadamard matrix but as you can see, the most likely state for the input qubits is 
// 01, as when it is 01 there is a 50% chance that phase is inverted

// there are unfortunately a couple problems with this:
// 1) the chance of observing 01 is only around 60% or so
// 2) if 01 is not observed the retainQubit's superposition is destroyed
// 3) the way this works seems very contrived, as the goal of the recovery is to convert the state back to |0> and apply
//    the hadamard again. 
// 4) changing the retainQubit's superposition to anything other that (|0> + |1>)/sqrt(2) 

namespace Retention {
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;

    @EntryPoint()
    operation Main() : (Result, Result) {
        use qubits = Qubit[2];
        use phaseControl = Qubit();

        use intermediateQubit = Qubit[2];
        use retainQubit = Qubit(); // we want to perserve this qubit's superposition yet still allow it to interact

        X(phaseControl);
        H(phaseControl);

        ApplyHAll(qubits);

        H(retainQubit);

        for i in 0..3 {
            // do and undo to temporarily store a true value on the intermediate qubit for the current index
            ApplyIndexXGates(qubits, IntAsBoolArray(i, 2));
            CCNOT(qubits[0], qubits[1], intermediateQubit[0]);

            if(i == 1) {
                CCNOT(intermediateQubit[0], retainQubit, intermediateQubit[1]);
                CNOT(intermediateQubit[1], phaseControl);
                
                CCNOT(intermediateQubit[0], retainQubit, intermediateQubit[1]);
            }

            CCNOT(qubits[0], qubits[1], intermediateQubit[0]);
            ApplyIndexXGates(qubits, IntAsBoolArray(i, 2));
        }

        Message("Before applying Diffusion Operator: ");
        DumpMachine();

        ApplyDiffusionOperatorFor2Qubits(qubits, phaseControl);

        Message("After applying Diffusion Operator (searching for 01): ");
        DumpMachine();

        let results = (M(qubits[0]), M(qubits[1]));

        Message("The machine after measuring the first two qubits: ");
        DumpMachine();

        if(results == (Zero, One)) {
            Message("Recovery attempt underway!");

            // correcting probabilities
            Ry(PI()/3.38791, retainQubit); // i used desmos to help find this strange angle
            H(retainQubit);

            // now we need to correct phase
            X(phaseControl);
            CNOT(phaseControl, retainQubit);
            X(phaseControl);
            Z(retainQubit);

        }

        Message("After recovery attempt and observing phase control: ");
        DumpMachine();

        ResetAll(qubits);
        Reset(phaseControl);
        ResetAll(intermediateQubit);
        Reset(retainQubit);

        return results;
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

    // applies the inversion about the mean step of Grover's algorithm
    operation ApplyDiffusionOperatorFor2Qubits(qubits : Qubit[], phaseControl : Qubit) : Unit {
        ApplyHAll(qubits);
        ApplyXAll(qubits);
        CCNOT(qubits[0], qubits[1], phaseControl);
        ApplyXAll(qubits);
        ApplyHAll(qubits);
    }

    // applies gates to the qubits so that both will be 1 if the qubits match the index
    // the length of qubits and index should be the same
    operation ApplyIndexXGates(qubits : Qubit[], index : Bool[]) : Unit {
        //if(Length(qubits) != Length(index)) {fail "Lengths of qubits and index do not match!";}

        for i in IndexRange(index) {
            if(index[Length(index) - 1 - i] == false) {
                X(qubits[i]);
            }
        }
    }
}