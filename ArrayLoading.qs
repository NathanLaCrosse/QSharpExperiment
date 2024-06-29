// intakes an array of size four and holds values from 0-7  
// the array is essentially a function that takes 

namespace ArrayLoading {
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;

    @EntryPoint()
    operation Main() : Unit {
        use inputQubits = Qubit[2]; // represents the possibles indices in array
        use outputQubits = Qubit[3]; // represents the possible values in array

        EnterBalancedState(inputQubits); // put inputs into a superposition

        let ar = [2, 1, 4, 7]; // 4 numbers from 0-7
        //let arLen = Length(ar);

        for i in IndexRange(ar) {
            // create a gate than maps the current index of the array onto
            let bitIndex = IntAsBoolArray(i, Length(inputQubits));

            ApplyIndexXGates(inputQubits, bitIndex);
            ApplyOutputGatesThroughArray(inputQubits, outputQubits, ar[i]);
            ApplyIndexXGates(inputQubits, bitIndex);
        }

        DumpMachine();

        ResetAll(inputQubits);
        ResetAll(outputQubits);

    }

    // applies a hadamard gate to each of the qubits to enter a balanced superposition
    operation EnterBalancedState(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            H(qubits[i]);
        }
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

    // takes the array value for a given index and entangles the input qubits (index) with the output qubits (stores array val in superposition)
    // X gates would have been applied beforehand so it is implied that all inputs must be 1 if we are on the correct index
    operation ApplyOutputGatesThroughArray(input : Qubit[], output : Qubit[], arrayVal : Int) : Unit {
        let bitAr = IntAsBoolArray(arrayVal, Length(output));

        for i in IndexRange(bitAr) {
            if(bitAr[Length(bitAr) - 1 - i] == true) {
                // currently using only 2 input qubits so a toffoli will suffice
                CCNOT(input[0], input[1], output[i]);
            }
        }
    }
}