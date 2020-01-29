#! /usr/bin/env gawk -f

{
    for(i=1;i<=NF;i++) cols[$i]++;
    for(i=255; i>=0; i--) if(i in cols) { topal[i]=c++; }
    for (i=1;i<=NF;i+=8) {
        h=0;l=0;
        for(j=0;j<8;j++) {
            c=topal[$(i+j)];
            h = 2*h + (int(c / 2)%2);
            l=2*l + (c % 2);
        }
        printf "%02x %02x\n", l, h;
    }
}
