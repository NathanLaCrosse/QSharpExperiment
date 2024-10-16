// an attempt to speed up the grover sort algorithm by loading index values based
// off of a quantum array

// Goal: see if this works with two qubits

namespace ArrayLoadingForSort {
    import Std.Diagnostics.DumpMachine;
    import Std.Convert.IntAsBoolArray;
    open Microsoft.Quantum.Arrays;

    @EntryPoint()
    operation Main() : Unit {
        // array loading
        use qIndex = Qubit();
        use qArray = Qubit[2]; // stores the values in the array

        H(qIndex);

        let ar = [3,1];
        loadShortArray(ar, qIndex, qArray);

        Message("Printing out qArray:");
        DumpMachine();

        // building order superposition - all possible combinations of array elements
        use qOrder = Qubit[2];
        H(qOrder[0]);
        X(qOrder[1]);
        CNOT(qOrder[0], qOrder[1]);

        // This is the meat of the program, as we want to use our loaded array to transfer
        // values in the array to values that we can use groverSort on
        use val1 = Qubit[2];
        use val2 = Qubit[2];

        // value transferral - if qIndex and a given qOrder agree, their value is transferred to val
        X(qIndex);
        X(qOrder[0]);
        (Controlled X)([qIndex, qOrder[0], qArray[0]], val1[0]);
        (Controlled X)([qIndex, qOrder[0], qArray[1]], val1[1]);
        X(qOrder[0]);
        X(qIndex);

        (Controlled X)([qIndex, qOrder[1], qArray[0]], val2[0]);
        (Controlled X)([qIndex, qOrder[1], qArray[1]], val2[1]);

        Message("After qArray transferral:");
        DumpMachine();

        // notes from tired me
        // only bits of the array are loaded in in each state, none contain the full array
        // this could make comparisons impossible

        Reset(qIndex);
        ResetAll(qArray);
        ResetAll(qOrder);
        ResetAll(val1);
        ResetAll(val2);
    }

    // loads a length 2 array containing values from 0-3 into a superposition between qIndex and qArray qubits
    operation loadShortArray(ar : Int[], qIndex : Qubit, qArray : Qubit[]) : Unit {
        X(qIndex);
        loadArrayIndex(ar[0], qIndex, qArray);
        X(qIndex);
        loadArrayIndex(ar[1], qIndex, qArray);
    }

    // arrayVal is value at the specific index of array
    // index qubit is the one performing the CNOT action
    // qArray will have the array loaded into it
    // it is assumed that index is currently in "|1>" state for data transfer (kinda hard to put into words as its not competely the case)
    operation loadArrayIndex(arrayVal : Int, index : Qubit, qArray : Qubit[]) : Unit {
        let valAr = IntAsBoolArray(arrayVal, 2);

        for i in IndexRange(valAr) {
            if(valAr[1-i]) {
                CNOT(index, qArray[i])
            }
        }
    }
}