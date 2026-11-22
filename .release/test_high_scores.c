#include <assert.h>
#include <stdio.h>
#include "../source/lindberghrecomp/src/runtime/high_scores.h"
int main(void)
{
    uint32_t words[60]={0};HighScoreState s={0};
    for(int i=0;i<10;i++){words[i*6]=10000-100*i;words[i*6+1]=1;words[i*6+2]=0;words[i*6+3]=26;}
    assert(high_scores_decode(&s,words));assert(s.count==10 && s.rows[0].score==10000 && !strcmp(s.rows[0].initials,"A Z"));
    words[7]=27;assert(!high_scores_decode(&s,words));assert(s.rows[0].score==10000);
    words[7]=2;words[6]=10001;assert(!high_scores_decode(&s,words));
    words[6]=9900;words[0]=1000000000u;assert(!high_scores_decode(&s,words));
    words[0]=999999999u;assert(high_scores_decode(&s,words));
    puts("High scores: original record decoding, initials, ranking order, bounds and invalid data passed.");
}
