#include "lib_ex2.h"

/**
* count from 'start' to 'end' (inclusive),
* showing progress on the seven segment displays
*/
void count(int start, int end) {
  
   int i;

    if (0 <= start < 10000 && 0 <= end < 10000) {
        if (start < end) {
            for (i = start; i <= end; ++i) {
               delay();
               writessd(i);
           }
        } else if (start > end) {
            for (i = start; i >= end; --i) {
               delay();
               writessd(i);
            }
        } else if (start == end) {
           return;
        } 
    } else {
       return;
    }
}
