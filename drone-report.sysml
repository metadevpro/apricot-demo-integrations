// Report over the Drone model, rendered by OpenSysML:
//   sysml -render-document DroneReport::DesignReport -doc-form markdown drone.sysml drone-report.sysml
// Documents and DocumentQueries are an OpenSysML library, not part of the OMG
// standard library. Every query below also runs on its own with `-run-query` (through Apricot's `exec`).
package DroneReport {
    private import Drone::*;
    private import DocumentQueries::*;
    private import KerML::Root::Element;
    private import ScalarValues::String;

    // ---- Collection ---------------------------------------------------

    // The drone's components: the part usages it owns.
    calc def Components :> Query {
        in root : Element;
        WhereType(source = OwnedElements(source = root), type = "PartUsage")
    }

    // ---- Filter, sort, project ----------------------------------------

    // Components at or above a mass threshold (kg). The value is read through
    // each component's redefinition chain, not taken as a literal.
    calc def HeavyComponents :> Query {
        in root : Element;
        in threshold : String default "1";
        WhereFeature(source = Components(root = root), 'feature' = "mass", operator = ">=", value = threshold)
    }

    // Bill of materials: heaviest first, with computed columns.
    calc def BillOfMaterials :> Query {
        in root : Element;
        Project(
            source = OrderBy(source = Components(root = root), property = "mass",
                             direction = "descending", missing = "last", multiple = "error"),
            properties = ("name", "mass", "power", "cost"),
            columns = (
                Column(name = "costPerKg", expression = Component::cost / Component::mass),
                Column(name = "label", expression = "part: " + Element::name)
            )
        )
    }

    // Components annotated @SafetyCritical.
    calc def CriticalComponents :> Query {
        in root : Element;
        Project(
            source = WhereMetadata(source = Components(root = root), 'metadata' = "Drone::SafetyCritical"),
            properties = ("name", "qualifiedName")
        )
    }

    // ---- Traceability -------------------------------------------------

    calc def Requirements :> Query {
        Project(
            source = OrderBy(source = WhereType(source = OwnedElements(source = Drone), type = "RequirementUsage"),
                             property = "shortName", direction = "ascending", missing = "last", multiple = "error"),
            properties = ("shortName", "name", "type")
        )
    }

    // Who satisfies a requirement: an incoming satisfaction.
    calc def SatisfiedBy :> Query {
        in req : Element;
        Project(
            source = RelatedElements(source = req, relationshipKind = "satisfaction", direction = "incoming", maxDepth = 1),
            properties = ("name", "qualifiedName")
        )
    }

    // Which verification covers a requirement: an incoming verification.
    calc def VerifiedBy :> Query {
        in req : Element;
        RelatedElements(source = req, relationshipKind = "verification", direction = "incoming", maxDepth = 1)
    }

    // Where the software runs: an outgoing allocation.
    calc def AllocatedTo :> Query {
        in origin : Element;
        RelatedElements(source = origin, relationshipKind = "allocation", direction = "outgoing", maxDepth = 1)
    }

    // What the battery feeds: connections run port to port.
    calc def PoweredBy :> Query {
        in origin : Element;
        RelatedElements(source = origin, relationshipKind = "connection", direction = "outgoing", maxDepth = 1)
    }

    // Every component kind: an incoming specialization from Component.
    calc def ComponentKinds :> Query {
        in general : Element;
        RelatedElements(source = general, relationshipKind = "specialization", direction = "incoming", maxDepth = 1)
    }

    // ---- The document -------------------------------------------------

    part def DesignReport :> Document {
        attribute redefines title = "Delivery Drone Design Report";

        part intro : Paragraph {
            attribute redefines text = "Components, requirements and traceability of the delivery drone, generated from the model by OpenSysML.";
        }

        part bom : Section {
            attribute redefines title = "Bill of materials";
            part table : Table {
                attribute redefines caption = "Components, heaviest first";
                calc rows : BillOfMaterials { in root = drone; }
            }
        }

        part safety : Section {
            attribute redefines title = "Safety-critical components";
            part table : Table {
                attribute redefines caption = "Components marked @SafetyCritical";
                calc rows : CriticalComponents { in root = drone; }
            }
        }

        part trace : Section {
            attribute redefines title = "Requirements";
            part reqs : Table {
                attribute redefines caption = "Requirements by identifier";
                calc rows : Requirements;
            }
            part satisfiers : Table {
                attribute redefines caption = "Parts satisfying R-01";
                calc rows : SatisfiedBy { in req = mtow; }
            }
        }

        part structure : Section {
            attribute redefines title = "Structure";
            part tree : Diagram {
                attribute redefines caption = "Drone part tree";
                attribute redefines kind = "tree";
                attribute redefines direction = "LR";
                ref redefines source = drone;
            }
        }
    }
}
