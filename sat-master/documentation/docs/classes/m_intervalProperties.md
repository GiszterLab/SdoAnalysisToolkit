# dataCell.properties.intervalProperties

## Utility: 
- Lighweight support class containing the properties used for deriving intervals for sampling data.

## Structure: 

```mermaid
classDiagram
    class primaryData {
        ___Direct:___
        +n_shift = 0
        +z_delay = 0
        +dura_ms = 10
        +fs = 0
        ___Dependent:___
        +dura_nPoints
    }
```

## Properties: 

### (Defined):
* ```n_shift```

* ```z_delay```

* ```dura_ms```
    - The relative duration intervals to draw around events. 

* ```fs```
    - Sample Frequency. Used to convert time durations to bins. 

### (Derived):
* ```dura_nPoints```
    - Converstion of ```dura_ms``` into bins. 

## Methods: 