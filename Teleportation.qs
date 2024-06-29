namespace Teleportation {
    open Microsoft.Quantum.Diagnostics;
    @EntryPoint()
    operation Main() : Unit {
        
        use message = Qubit();
        use alice = Qubit();
        use bob = Qubit();

        Rx(3.0,message);

        DumpMachine();

        H(alice);
        CNOT(alice, bob);
        CNOT(message, alice);
        H(message);

        if (M(message) == One) {
            Z(bob);
        }
        if (M(alice) == One) {
            X(bob);
        }

        DumpMachine();

        Reset(message);
        Reset(alice);
        Reset(bob);
    }
}