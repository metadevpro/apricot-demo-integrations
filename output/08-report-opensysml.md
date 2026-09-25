# Delivery Drone Design Report

Components, requirements and traceability of the delivery drone, generated from the model by OpenSysML.

## Bill of materials

<!-- caption -->
*Components, heaviest first*

| name | mass | power | cost | costPerKg | label |
| --- | --- | --- | --- | --- | --- |
| battery | 4.4 | 0 | 900 | 204.54545454545453 | part: battery |
| airframe | 3.2 | 0 | 450 | 140.625 | part: airframe |
| camera | 0.6 | 15 | 700 | 1166.6666666666667 | part: camera |
| motors | 0.55 | 0 | 160 | 290.9090909090909 | part: motors |
| gripper | 0.4 | 5 | 150 | 375 | part: gripper |
| controller | 0.25 | 12 | 380 | 1520 | part: controller |
| gps | 0.1 | 2 | 120 | 1200 | part: gps |

## Safety-critical components

<!-- caption -->
*Components marked @SafetyCritical*

| name | qualifiedName |
| --- | --- |
| battery | Drone::drone::battery |
| motors | Drone::drone::motors |
| controller | Drone::drone::controller |

## Requirements

<!-- caption -->
*Requirements by identifier*

| shortName | name | type |
| --- | --- | --- |
| R-01 | mtow | Drone::MaxTakeoffMass |
| R-02 | flightTime | Drone::MinFlightTime |
| R-03 | deliveryLoad | Drone::MinPayload |

<!-- caption -->
*Parts satisfying R-01*

| name | qualifiedName |
| --- | --- |
| drone | Drone::drone |

## Structure

<!-- caption -->
*Drone part tree*

```mermaid
%% tree rendering (the diagram states kind "tree")
flowchart LR
  n0["Drone::drone : Quadcopter<br>«part»"]
  n1["airframe<br>«part»"]
  n2["mass<br>«attribute»"]
  n1 --- n2
  n3["power<br>«attribute»"]
  n1 --- n3
  n4["cost<br>«attribute»"]
  n1 --- n4
  n0 --- n1
  n5["battery<br>«part»"]
  n6["mass<br>«attribute»"]
  n5 --- n6
  n7["power<br>«attribute»"]
  n5 --- n7
  n8["cost<br>«attribute»"]
  n5 --- n8
  n9["capacity<br>«attribute»"]
  n5 --- n9
  n0 --- n5
  n10["motors<br>«part»"]
  n11["mass<br>«attribute»"]
  n10 --- n11
  n12["power<br>«attribute»"]
  n10 --- n12
  n13["cost<br>«attribute»"]
  n10 --- n13
  n0 --- n10
  n14["controller<br>«part»"]
  n15["mass<br>«attribute»"]
  n14 --- n15
  n16["power<br>«attribute»"]
  n14 --- n16
  n17["cost<br>«attribute»"]
  n14 --- n17
  n0 --- n14
  n18["gps<br>«part»"]
  n19["mass<br>«attribute»"]
  n18 --- n19
  n20["power<br>«attribute»"]
  n18 --- n20
  n21["cost<br>«attribute»"]
  n18 --- n21
  n0 --- n18
  n22["camera<br>«part»"]
  n23["mass<br>«attribute»"]
  n22 --- n23
  n24["power<br>«attribute»"]
  n22 --- n24
  n25["cost<br>«attribute»"]
  n22 --- n25
  n0 --- n22
  n26["gripper<br>«part»"]
  n27["mass<br>«attribute»"]
  n26 --- n27
  n28["power<br>«attribute»"]
  n26 --- n28
  n29["cost<br>«attribute»"]
  n26 --- n29
  n0 --- n26
  n30["payload<br>«attribute»"]
  n0 --- n30
  n31["satisfy"]
  n0 --- n31
  n32["satisfy"]
  n0 --- n32
  n33["satisfy"]
  n0 --- n33
```
