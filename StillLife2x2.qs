namespace StillLife2x2 {
    import Std.Diagnostics.DumpMachine;
    import Std.Arrays.IndexRange;

    @EntryPoint()
    operation Main() : Result[] {
        use grid = Qubit[4]; // 2x2 grid of conway's game of life
        use tempWork = Qubit[2]; // ancillia for work
        use nextGrid = Qubit[4]; // next state
        use phaseInverter = Qubit();

        // set up phase inverter for later
        X(phaseInverter);
        H(phaseInverter);

        // put grid into an equal superposition of all possible states
        ApplyHAll(grid);

        for i in 0..3 {
            mutable k = i + 1;
            if(k > 3) {k = 0;}

            // increment counter based on neighbors
            while(i != k) {
                IncrementNeighborCounter(grid[k], tempWork);

                k += 1;
                if(k > 3) {k = 0;}
            }

            // now use the neighbor count to determine next state (focusing on what makes a cell alive)
            X(tempWork[1]);
            (Controlled X)([grid[i], tempWork[0], tempWork[1]], nextGrid[i]);
            X(tempWork[1]);

            CCNOT(tempWork[0], tempWork[1], nextGrid[i]);

            // we now need to free up tempWork so it can be used by the next cell
            k = i - 1;
            if(k < 0) {k = 3;}

            // decrement in reverse order
            while(i != k) {
                DecrementNeighborCounter(grid[k], tempWork);

                k -= 1;
                if(k < 0) {k = 3;}
            }
        }

        // now we have a properly computed next state :)
        // compare the two states via CNOT and then phase change if the two match (still life!)
        for i in 0..3 {
            CNOT(grid[i], nextGrid[i]);
        }

        // the last thing we have to account for is the empty state. the program counts it as a still life despite it not being alive...
        // so, make sure at least one thing is alive (or gate)
        use alive = Qubit();
        X(alive);
        ApplyXAll(grid);
        (Controlled X)(grid, alive);
        ApplyXAll(grid);

        ApplyXAll(nextGrid);
        (Controlled (Controlled X)([alive], (nextGrid, phaseInverter)));
        ApplyXAll(nextGrid);

        // now, before being able to call grover's algorithm we must undo everything except for the phase change.
        // since this is just running the program in reverse, it is done in the following method:
        UndoEverythingUpToPhaseInversion(grid, tempWork, nextGrid, alive);

        // now apply the diffusion operator
        ApplyHAll(grid);
        ApplyXAll(grid);
        (Controlled X)(grid, phaseInverter);
        ApplyXAll(grid);
        ApplyHAll(grid);

        DumpMachine();

        let observation = [M(grid[0]), M(grid[1]), M(grid[2]), M(grid[3])];

        ResetAll(grid);
        ResetAll(tempWork);
        ResetAll(nextGrid);
        Reset(phaseInverter);
        Reset(alive);

        return observation;
    }

    operation UndoEverythingUpToPhaseInversion(grid : Qubit[], tempWork : Qubit[], nextGrid : Qubit[], alive : Qubit) : Unit {
        ApplyXAll(grid);
        (Controlled X)(grid, alive);
        ApplyXAll(grid);
        X(alive);

        for i in 0..3 {
            CNOT(grid[i], nextGrid[i]);
        }

        for i in 0..3 {
            mutable k = i + 1;
            if(k > 3) {k = 0;}

            // increment counter based on neighbors
            while(i != k) {
                IncrementNeighborCounter(grid[k], tempWork);

                k += 1;
                if(k > 3) {k = 0;}
            }

            // now use the neighbor count to determine next state (focusing on what makes a cell alive)
            X(tempWork[1]);
            (Controlled X)([grid[i], tempWork[0], tempWork[1]], nextGrid[i]);
            X(tempWork[1]);

            CCNOT(tempWork[0], tempWork[1], nextGrid[i]);

            // we now need to free up tempWork so it can be used by the next cell
            k = i - 1;
            if(k < 0) {k = 3;}

            // decrement in reverse order
            while(i != k) {
                DecrementNeighborCounter(grid[k], tempWork);

                k -= 1;
                if(k < 0) {k = 3;}
            }
        }
    }

    // note - counter is an array of two qubits (storing 0-3 neighbors present)
    operation IncrementNeighborCounter(control : Qubit, counter : Qubit[]) : Unit {
        CCNOT(control, counter[1], counter[0]);
        CNOT(control, counter[1]);
    }
    // to undo the work on tempWork (think adjoint version)
    operation DecrementNeighborCounter(control : Qubit, counter : Qubit[]) : Unit {
        CNOT(control, counter[1]);
        CCNOT(control, counter[1], counter[0]);
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
}