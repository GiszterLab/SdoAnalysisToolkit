# dataCell.shuffler

## Utility: 

Support Class for generating and sampling random shufflers. 

## Compositions:

- ppDataCell2
- sdoMat2


## Structure: 

```mermaid
classDiagram
    class shuffler {
        ___Defined___
        +data
        +shuffleData
        +nShuffles
        +shuffMethod
        +shuffTau
        +shuffCIF
        ___Dependent___
        +importedData
        +shuffledData
        +nTrialEvents
        +nChannels
        +nTrials
        +sensor
        +fs

        +import()
        +random()
        +shuffle()
        +getPpData()
    }
```

## Properties

## Methods

* ### ```import```(data):
    - ```data```: A [dataCell.primaryData](./m_primaryData.md) class. 

* ### ```random```(nTrials, nChannels, nEvents, vars):
    - vars.maxX
    - vars.type 
        - 'times'
        - 'index'
        - 'all'
    - vars.link
        - 'none'
        - 'trials'
        - 'channels'
        - 'both'
    - vars.seed

* ### ```shuffle```(data, vars): 
    - vars.useTrials 
    - vars.useChannels

* ### ```getPpData```(vars.flatten): 


