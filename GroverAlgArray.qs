namespace GroverAlgorithm {
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;

    @EntryPoint()
    operation Main() : Unit {
        use inputQubits = Qubit[3]; // represents the possibles indices in array
        use outputQubits = Qubit[4]; // represents the possible values in array

        use ancillia = Qubit[2]; // used in CCC- and CCCC- Not gates
        use phaseControl = Qubit(); // this qubit, when flipped, will induce a negative phase

        ApplyHAll(inputQubits); // put inputs into a superposition

        // prepare the control qubit into the state 1/sqrt(2)|0> - 1/sqrt(2)|1>
        X(phaseControl);
        H(phaseControl);

        let ar = [2, 1, 4, 7, 8, 10, 3, 15]; // 8 numbers from 0-15
        let key = 7;

        // load the array into a highly entangled superposition holding the array's values
        for i in IndexRange(ar) {
            let bitIndex = IntAsBoolArray(i, Length(inputQubits));

            ApplyIndexXGates(inputQubits, bitIndex);
            ApplyOutputGatesThroughArray(inputQubits, outputQubits, ar[i], ancillia[0]);
            ApplyIndexXGates(inputQubits, bitIndex);
        }

        // search for a key and put a |1> on result if we find it
        ApplyKeyCircuit(outputQubits, phaseControl, IntAsBoolArray(key, Length(outputQubits)), ancillia);

        // we need to undo the array loading process as the oracle must be undone before continuing
        for i in IndexRange(ar) {
            let bitIndex = IntAsBoolArray(Length(ar) - 1 - i, Length(inputQubits));

            ApplyIndexXGates(inputQubits, bitIndex);
            ApplyOutputGatesThroughArray(inputQubits, outputQubits, ar[Length(ar) - 1 - i], ancillia[0]);
            ApplyIndexXGates(inputQubits, bitIndex);
        }


        // amplify key
        ApplyDiffusionOperation(inputQubits, phaseControl, ancillia);

        DumpMachine(); 

        // ancillia does not need to be reset as it will always be returned to |0>
        ResetAll(inputQubits);
        ResetAll(outputQubits);
        Reset(phaseControl);
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
    operation ApplyOutputGatesThroughArray(input : Qubit[], output : Qubit[], arrayVal : Int, ancillia : Qubit) : Unit {
        let bitAr = IntAsBoolArray(arrayVal, Length(output));

        for i in IndexRange(bitAr) {
            if(bitAr[Length(bitAr) - 1 - i] == true) {
                // currently using only 2 input qubits so a toffoli will suffice
                CCCNOT(input[0], input[1], input[2], output[i], ancillia);
            }
        }
    }

    // applies a circuit that outputs a 1 in the output qubit if the array values match key
    // it is implied that Length(arrayValues) = Length(key)
    operation ApplyKeyCircuit(arrayValues : Qubit[], output: Qubit, key : Bool[], ancillia : Qubit[]) : Unit {
        ApplyIndexXGates(arrayValues, key); // set it up so the desired key outputs |11..1>

        CCCCNOT(arrayValues[0], arrayValues[1], arrayValues[2], arrayValues[3], output, ancillia);

        ApplyIndexXGates(arrayValues, key);
    }

    // implementation of CCCNOT with the ancillia qubit already provided so the ancillia can be used multiple time
    operation CCCNOT(control1 : Qubit, control2 : Qubit, control3 : Qubit, target : Qubit, ancillia : Qubit) : Unit{
        CCNOT(control1, control2, ancillia);
        CCNOT(control3, ancillia, target);
        CCNOT(control1, control2, ancillia); // return ancillia back to |0> 
    }
    // CCCCNOT gate good lord
    operation CCCCNOT(control1 : Qubit, control2 : Qubit, control3 : Qubit, control4 : Qubit, target : Qubit, ancillia : Qubit[]) : Unit {
        CCCNOT(control1, control2, control3, ancillia[0], ancillia[1]);
        CCNOT(control4, ancillia[0], target);
        CCCNOT(control1, control2, control3, ancillia[0], ancillia[1]);
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

    // performs the diffusion operation on some qubits
    // IT IS CURRENTLY IMPLIED THAT ARRAYVALS HAS 4 QUBITS
    operation ApplyDiffusionOperation(arrayVals : Qubit[], phaseInverter : Qubit, ancillia : Qubit[]) : Unit {
        ApplyHAll(arrayVals);
        ApplyXAll(arrayVals);
        CCCNOT(arrayVals[0], arrayVals[1], arrayVals[2], phaseInverter, ancillia[0]);
        ApplyXAll(arrayVals);
        ApplyHAll(arrayVals);
    }
}