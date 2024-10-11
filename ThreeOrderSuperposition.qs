namespace ThreeWay {
    import Microsoft.Quantum.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Math.PI;
    open Microsoft.Quantum.Arrays;
    @EntryPoint()
    operation Main() : Unit {
        // attempt to get the qubits into a superposition of three possible orders of an array (vals = indices)

        use order1 = Qubit[2];
        use order2 = Qubit[2];
        use order3 = Qubit[2];
        
        // rotate the first qubit into sqrt(2)/sqrt(3)|0> + 1/sqrt(3)|1>
        Ry(2.0*0.61547970867, order1[0]);

        // apply a hadamard when the top qubit is in |0>, requiring an X gate
        X(order1[0]);
        ControlledH(order1[0],order1[1]) ;
        X(order1[0]);   

        // for the second index:
        H(order2[1]);
        X(order1[0]);
        CCH(order1[0], order1[1], order2[0]);
        CCH(order1[0], order1[1], order2[1]);
        X(order1[0]);

        ApplyXAll(order1);
        CCNOT(order1[0], order1[1], order2[0]);
        CCCNOT(order1[0], order1[1], order2[1], order2[0]);
        ApplyXAll(order1);

        // for the third index:
        CNOT(order1[0], order2[0]);
        X(order2[0]);
        CNOT(order2[0], order3[0]);
        X(order2[0]);
        CNOT(order1[0], order2[0]);

        CNOT(order1[1], order2[1]);
        X(order2[1]);
        CNOT(order2[1], order3[1]);
        X(order2[1]);
        CNOT(order1[1], order2[1]);

        DumpMachine();

        ResetAll(order1);
        ResetAll(order2);
        ResetAll(order3);
    }

    operation ControlledH(control : Qubit, target : Qubit) : Unit {
        (Controlled H)([control], target);
    }

    operation CCH(control1 : Qubit, control2 : Qubit, target : Qubit) : Unit {
        (Controlled (Controlled H))([control1], ([control2], target));
    }

    operation ApplyXAll(qubits : Qubit[]) : Unit {
        for i in IndexRange(qubits) {
            X(qubits[i]);
        }
    }

    operation CCCNOT(control1 : Qubit, control2 : Qubit, control3 : Qubit, target : Qubit) : Unit {
        (Controlled (Controlled (Controlled X)))([control1], ([control2], ([control3], target)));
    }
}