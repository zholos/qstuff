/ oop.q: A simple object system

new:{x:$[100=t:type x;x,count[get[x]1]#(::);104=t;x,(count[x]-1+count
    get[first x:get x]1)#(::);'`type];c:$[null c:d first where
    {()~get x}each` sv/:`,/:d:d where like[;"closure_*"]d:inv`;
    c:"closure_",string count d;string c];d:string system"d";
    system "d .",c;get[last get x 0]. 1_x;system["d ",d];
    k!v k:except[;`]where 100<=type each v:get `$".",c};

collect:{count[d]-count set[;()]each` sv/:`,/:{n:{$[0=type x;x where
    not(::)~/:x;x]};$[0=t:type y;.z.s/[x;n y;z];(99=t)|t within
    104 111;.z.s/[x;n get y;z];100=t;x where not(x<>z)&x in\:get[y]3;
    x]}/[d:d where like[;"closure_*"]d;(get')` sv/:`,/:d;d:`,inv`]};


/ example object constructor
accum:{val_::0; val::{val_}; add::{val_+:x};}

/ make two instances
a1:new accum
a2:new accum
a3:a2   / a2 and a3 reference the same object

/ call mutator methods
a1.add 5
a2.add 11
a3.add 31

/ examine states
a1.val[]   / 5
a2.val[]   / 42
a3.val[]   / 42

/ remove some references and collect unused instances
collect[]  / 2 referenced instances
a1:()
a2:()
collect[]  / 1 referenced instance remaining a3.val[]
