# Custom Classes

Below are the list of custom classes which we have developed to streamline the SDO Analysis Pipeline. 

### [xtDataCell.m](./m_xtDataCell.md)

_A class for manipulating time series data_


### [ppDataCell.m](./m_ppDataCell.md)

_A class for manipulating point process (spike) data_

### [pxtDataCell.m](./m_pxtDataCell.md)

_A class for manipulating a series of sampled probability distributions_

!!! warning
    This class is not as well maintained, and is superceded by direct calls to [```sdoMultiMat```](./m_sdoMultiMat.md). Likely, end-users will not need to directly interact with this class and its methods. 

### [sdoMat.m](./m_sdoMat.md)

_A class for containing an SDO matrix, background distribution, and null-shuffles_

!!! warning
    This class is partially deprecated. The _sdoMultiMat_ class overshadows most of the utilties of this class.

### [sdoMultiMat.m](./m_sdoMultiMat.md)

_A class for calculating and containg all of the SDO matrices, including descriptions of the background, null shuffles, and hypothesis testing_

---
## Support Classes
### [predictionError.m](m_predictionError.md)
_A support class containing the measured predicted errors between an observed and predicted stochastic realization. Includes plotting methods for visualizing errors_


## Object-Oriented Programming (OOP) Overview


## Usage Notes: 
!!! note
     All  custom  classes  are  handle  classes  (i.e.,  inherit  properties  from  the  MATLAB-defined  [handle  class](https://www.mathworks.com/help/matlab/handle-classes.html )).  

Briefly,  handle  classes  operate  on  references to a  data  object  (i.e., provide a  ‘handle’ on),  such  that  calls  to  and  manipulations  of,  the  object  refer  to  the  same, singular  object. Effectively, this means that class methods return the _same_ instance of the MATLAB class called, rather than returning a new instance of the class. 

~~~
A = handleClass
A.Method
~~~

_Class Method ```Method``` has now been applied to handleClass instance ```A```_

~~~
# No change
A = nonHandleClass
A.Method
performedMethod(A, 'Method')
false; 

# Change
A = A.Method
performedMethod(A, 'Method')
true; 
~~~

_Class Method ```Method``` has operated on nonHandleClass instance ```A```, but because the output was not captured to a new variable, the underlying instance was not updated._

~~~
If A = handleClass;  
B = A;  
Then if  A = [  ] →  B = [  ]. 
~~~

!!! note
    - To produce a (deep) copy of a given data class (e.g., to separately manipulate), they must use the ```.copy```  method, else the reference variable used for the ‘copy’ (B, inexample) will point to the same object. 

    - When calling a method which is part of a class, the method  may be called by appending the suffix .methodName(params)  (i.e., the name of the function/method) to the variable of that data class. Alternatively, these can be called as methodNames(variableOfClassType, params). 