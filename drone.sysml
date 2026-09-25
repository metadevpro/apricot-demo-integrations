// Demo model for the engine comparison: one delivery drone, two engines
// (OpenSysML and the SysML v2 Toolkit), reached through Apricot's
// /api/v1/runtimes. Everything in this file loads cleanly in both engines and
// in the editor's validator.
package Drone {
    private import ScalarValues::*;
    // OpenSysML resolves library functions only through an import; the Toolkit
    // finds `sum`/`size` without one.
    private import RealFunctions::*;
    private import SequenceFunctions::*;
    private import TradeStudies::*;

    // ---- Metadata -----------------------------------------------------

    metadata def SafetyCritical;

    // ---- Structure ----------------------------------------------------

    part def Component {
        attribute mass : Real;     // kg
        attribute power : Real;    // W, average draw in hover (motors excluded)
        attribute cost : Real;     // EUR
    }

    port def PowerPort;
    port def DataPort;
    port def ControlPort;

    part def Frame :> Component;

    part def Battery :> Component {
        attribute capacity : Real;             // Wh
        port supply : PowerPort;
    }

    part def Motor :> Component {
        port powerIn : PowerPort;
        port command : ControlPort;
    }

    part def FlightController :> Component {
        port powerIn : PowerPort;
        port motorBus : ControlPort;
        port telemetry : DataPort;
    }

    part def GpsReceiver :> Component {
        port nav : DataPort;
    }

    part def Camera :> Component {
        port video : DataPort;
    }

    part def Gripper :> Component {
        port command : ControlPort;
    }

    part def Quadcopter {
        part airframe : Frame;
        part battery : Battery;
        part motors : Motor[4];
        part controller : FlightController;
        part gps : GpsReceiver;
        part camera : Camera;
        part gripper : Gripper;

        attribute payload : Real;              // kg carried on a delivery
        attribute hoverSpecificPower : Real = 100.0;   // W per kg lifted
        attribute usableFraction : Real = 0.8;         // battery reserve kept

        // Four motors, one declared value each: the engines disagree on this sum.
        attribute motorMass : Real = sum(motors.mass);
        attribute emptyMass : Real = airframe.mass + battery.mass + motorMass
            + controller.mass + gps.mass + camera.mass + gripper.mass;
        attribute takeoffMass : Real = emptyMass + payload;
        attribute avionicsPower : Real = controller.power + gps.power + camera.power + gripper.power;
        attribute hoverPower : Real = hoverSpecificPower * takeoffMass + avionicsPower;
        attribute endurance : Real = battery.capacity * usableFraction / hoverPower * 60.0;   // min

        connect battery.supply to controller.powerIn;
        connect battery.supply to motors.powerIn;
        connect controller.motorBus to motors.command;
        connect controller.motorBus to gripper.command;
        connect gps.nav to controller.telemetry;
        connect camera.video to controller.telemetry;
    }

    // The drone under study: every component gets its numbers here.
    part drone : Quadcopter {
        part :>> airframe   { attribute :>> mass = 3.2;  attribute :>> power = 0.0;  attribute :>> cost = 450.0; }
        part :>> battery    { @SafetyCritical;
                              attribute :>> mass = 4.4;  attribute :>> power = 0.0;  attribute :>> cost = 900.0;
                              attribute :>> capacity = 1100.0; }
        part :>> motors     { @SafetyCritical;
                              attribute :>> mass = 0.55; attribute :>> power = 0.0;  attribute :>> cost = 160.0; }
        part :>> controller { @SafetyCritical;
                              attribute :>> mass = 0.25; attribute :>> power = 12.0; attribute :>> cost = 380.0; }
        part :>> gps        { attribute :>> mass = 0.1;  attribute :>> power = 2.0;  attribute :>> cost = 120.0; }
        part :>> camera     { attribute :>> mass = 0.6;  attribute :>> power = 15.0; attribute :>> cost = 700.0; }
        part :>> gripper    { attribute :>> mass = 0.4;  attribute :>> power = 5.0;  attribute :>> cost = 150.0; }

        attribute :>> payload = 5.0;

        // Declared here rather than at package level: the editor's validator
        // reads a package-level `satisfy x by y` as a second declaration of x.
        satisfy mtow by drone;
        satisfy flightTime by drone;
        satisfy deliveryLoad by drone;
    }

    // Software that runs on the flight controller.
    part def FlightSoftware;
    part autopilot : FlightSoftware;
    allocation autopilotOnController allocate autopilot to drone.controller;

    // ---- Requirements -------------------------------------------------

    requirement def MaxTakeoffMass {
        doc /* The take-off mass stays within the 25 kg class limit. */
        subject vehicle : Quadcopter;
        attribute limit : Real = 25.0;
        require constraint massOk { vehicle.takeoffMass <= limit }
    }

    requirement def MinFlightTime {
        doc /* One charge covers a 30 minute delivery round trip. */
        subject vehicle : Quadcopter;
        attribute minMinutes : Real = 30.0;
        require constraint longEnough { vehicle.endurance >= minMinutes }
    }

    requirement def MinPayload {
        doc /* The drone carries a standard 5 kg parcel. */
        subject vehicle : Quadcopter;
        attribute minKg : Real = 5.0;
        require constraint carriesParcel { vehicle.payload >= minKg }
    }

    // mtow binds its subject too: the verification below checks it directly.
    requirement <'R-01'> mtow : MaxTakeoffMass {
        subject vehicle = drone;
    }
    requirement <'R-02'> flightTime : MinFlightTime;
    requirement <'R-03'> deliveryLoad : MinPayload;

    // A bound check either engine decides outright.
    assert constraint powerBudget { drone.hoverPower <= 2000.0 }
    // R-02 bound to drone: OpenSysML only checks constraints it is given by
    // name, and flightTime leaves its subject open.
    assert constraint flightTimeCheck { drone.endurance >= 30.0 }

    // How the mass requirement is verified: weighing the assembled drone.
    verification def Weighing {
        subject vehicle : Quadcopter;
        VerificationCases::PassIf(vehicle.takeoffMass <= 25.0)
    }
    verification weighDrone : Weighing {
        subject vehicle = drone;
        objective {
            verify mtow;
        }
    }

    // ---- Design space (the solvers' part) -----------------------------
    // Battery capacity and payload are left open: the solvers look for
    // values, prove that none exist, or find the best one.
    //
    // Units are whole Wh and grams, and every condition is written over the
    // two open variables with literal coefficients. Both choices are for
    // OpenSysML's solver: it reads a condition's own text (declared values
    // and derived features are not substituted), and it only reports
    // `unsat` for exact (Integer) arithmetic. The Toolkit decides either way.
    //
    //   take-off mass (g) = 6750 airframe + 4 g per Wh of battery + payload
    //   hover power (W)   = take-off mass / 10 + 34 avionics
    //   endurance (min)   = 48 * capacity / hover power   (80 % usable)
    // so "endurance >= T" is "480 * capacity >= T * (take-off mass + 340)".

    package Sizing {
        attribute capacity : Integer;       // Wh, open
        attribute payload : Integer;        // g, open

        // Can a 10 kg parcel fly for 30 minutes under the 25 kg limit?
        constraint heavyLift {
            payload >= 10000
            & 6750 + 4 * capacity + payload <= 25000
            & 480 * capacity >= 30 * (6750 + 4 * capacity + payload + 340)
        }

        // ---- Battery envelope: asserted facts over open values ----
        // The next battery pack is not chosen yet, but the design commits to
        // it: a catalogue size that keeps the 25 kg limit and flies 30 min
        // with the 5 kg parcel. Interval propagation narrows packWh to the
        // packs that satisfy all three, with no solver. With the parcel fixed,
        // "flies 30 min" is 480 * packWh >= 30 * (12090 + 4 * packWh), i.e.
        // 360 * packWh >= 362700 (packWh appears once, so intervals are exact).
        attribute packWh : Integer;         // Wh, open
        assert constraint packCatalogue { packWh >= 800 & packWh <= 2000 }
        assert constraint packUnder25 { 6750 + 4 * packWh + 5000 <= 25000 }
        assert constraint packFlies30 { 360 * packWh >= 362700 }

        // A compact bay takes packs up to 1000 Wh: too small to fly 30 min
        // with the parcel, so propagation empties the domain.
        attribute bayPackWh : Integer;      // Wh, open
        assert constraint bayFits { bayPackWh <= 1000 }
        assert constraint bayFlies30 { 360 * bayPackWh >= 362700 }

        // A wish list nobody can build: three of these four conditions
        // cannot hold together.
        requirement def AmbitiousSpec {
            require constraint featherweight { 6750 + 4 * capacity + payload <= 12000 }
            require constraint longHaul { 480 * capacity >= 45 * (6750 + 4 * capacity + payload + 340) }
            require constraint parcel { payload >= 5000 }
            require constraint affordablePack { capacity <= 2500 }
        }
        requirement ambitious : AmbitiousSpec;

        // The same kind of question through a derived feature. The Toolkit
        // substitutes takeoffMass by its definition and proves it impossible;
        // OpenSysML's solver treats takeoffMass as one more unknown.
        attribute takeoffMass : Integer = 6750 + 4 * capacity + payload;
        constraint bigBattery { takeoffMass <= 25000 & capacity >= 5000 & payload >= 0 }

        // ---- Nonlinear: the rotor ----
        // Per-rotor thrust (g) ~ 2 * krpm^2 * inches^4 / 1000, four rotors must
        // lift twice the 25 kg limit, and the tip speed caps krpm * inches.
        attribute propInches : Integer;     // propeller diameter, open
        attribute krpm : Integer;           // thousands of rpm, open

        constraint rotorFits {
            8 * krpm * krpm * propInches * propInches * propInches * propInches >= 50000000
            & krpm * propInches <= 90 & krpm >= 1 & propInches >= 1 & propInches <= 30
        }
        // Same, with the propeller squeezed to 20 inches: no rpm is enough.
        constraint rotorCompact {
            8 * krpm * krpm * propInches * propInches * propInches * propInches >= 50000000
            & krpm * propInches <= 90 & krpm >= 1 & propInches >= 1 & propInches <= 20
        }

        // A square panel of exactly 2 m^2: its side is the irrational sqrt(2).
        attribute panelSide : Real;
        constraint squarePanel { panelSide * panelSide == 2.0 & panelSide > 0.0 }

        // The smallest propeller that still lifts: a nonlinear objective.
        analysis def SmallestProp {
            attribute inches : Integer;
            attribute rpmK : Integer;
            objective smallest : MinimizeObjective {
                subject :>> selectedAlternative;
                in calc :>> eval { inches }
                require constraint lifts { 8 * rpmK * rpmK * inches * inches * inches * inches >= 50000000 }
                require constraint tipSpeed { rpmK * inches <= 90 & rpmK >= 1 & inches >= 1 }
            }
        }

        // The heaviest parcel that still flies 30 minutes under 25 kg.
        analysis def MaxPayload {
            attribute cap : Integer;
            attribute load : Integer;
            objective heaviest : MaximizeObjective {
                subject :>> selectedAlternative;
                in calc :>> eval { load }
                require constraint flies30 { 480 * cap >= 30 * (6750 + 4 * cap + load + 340) }
                require constraint under25 { 6750 + 4 * cap + load <= 25000 }
                require constraint nonNegative { cap >= 0 & load >= 0 }
            }
        }
    }

    // ---- Analysis -----------------------------------------------------

    // Endurance left when the drone carries extra weight on top of its payload.
    analysis def ExtraLoad {
        subject vehicle : Quadcopter;
        in attribute extraKg : Real = 0.0;
        return minutes : Real = vehicle.battery.capacity * vehicle.usableFraction * 60.0
            / (vehicle.hoverSpecificPower * (vehicle.takeoffMass + extraKg) + vehicle.avionicsPower);
        objective stillFlies { require constraint { minutes >= 30.0 } }
    }
    analysis droneExtraLoad : ExtraLoad {
        subject vehicle = drone;
    }

    // ---- Behavior -----------------------------------------------------

    attribute def Launch;
    attribute def ParcelDropped;
    attribute def LowBattery;

    state def FlightModes {
        entry; then idle;

        state idle;
        state cruising;
        state delivering;
        state returning;

        transition launch
            first idle
            accept Launch
            then cruising;
        transition arrive
            first cruising
            then delivering;
        transition dropped
            first delivering
            accept ParcelDropped
            then returning;
        transition abort
            first cruising
            accept LowBattery
            then returning;
        transition landed
            first returning
            then idle;
    }

    // Battery charge (%) spent along one delivery. The cruise cost is left
    // open: a solver ranges over every value it could take.
    action def DeliveryMission {
        attribute charge : Real = 100.0;
        attribute cruiseCost : Real;
        assert constraint reserve { charge >= 20.0 }

        first start;
        then action takeOff { assign charge := charge - 8.0; }
        then action cruiseOut { assign charge := charge - cruiseCost; }
        then action release { assign charge := charge - 2.0; }
        then action cruiseBack { assign charge := charge - cruiseCost; }
        then action land { assign charge := charge - 5.0; }
        then done;
    }
}
