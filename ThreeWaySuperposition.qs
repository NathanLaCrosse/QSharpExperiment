namespace ThreeWay {
    import Microsoft.Quantum.Diagnostics.DumpMachine;
    import Microsoft.Quantum.Math.PI;
    @EntryPoint()
    operation Main() : Unit {
        // attempt to get the qubits into a superposition of three states

        use qubits = Qubit[2];
        
        // rotate the first qubit into sqrt(2)/sqrt(3)|0> + 1/sqrt(3)|1>
        Ry(2.0*0.61547970867, qubits[0]);

        // apply a hadamard when the top qubit is in |0>, requiring an X gate
        X(qubits[0]);
        ControlledH(qubits[0],qubits[1]) ;
        X(qubits[0]);   

        DumpMachine();

        ResetAll(qubits);
    }

    operation ControlledH(control : Qubit, target : Qubit) : Unit {
        (Controlled H)([control], target);
    }
}