#!/bin/sh


gawk '
function combine(a, n) {
  if(n<1) return "";
  s = a[1];
  if(a[2]) {
    for(i=2; i<=n; i++) {
      s = s " " a[i];
    }
  }
  return s;
}
function combine_2(a, x1, n) {
  if(n<1) return "";
  s = a[x1, 1];
  if(a[x1, 2]) {
    for(j=2; j<=n; j++) {
      s = s " " a[x1, j];
    }
  }
  return s;
}
function version() {
  return Version[1] "." Version[2] "." Version[3]
}
function setsymbol(sym) {
  Symbol=sym;
  Title=sym;
  sub(".(app|lib|clib)$", "", Title);
  Ident=tolower(sym);
  Final="binaries/" Title
}
function unstring(term) {
  return gensub("^\"", "", 1, gensub("\"$", "", 1, term));
}
function readblock(a) {
  n=0;
  while((getline line) > 0) {
    if(line ~ /^[^\(]*\)/) break;
    n++;
    a[n]=gensub(/;.*$/, "", 1, line);
  }
  return n;
}
function extract(s, regexp, a, b) {
  return substr(s, match(s, regexp)+a, RLENGTH-a-b)
}
function trim(s) {
  return gensub(/[[:space:]]*[[:space:]]$/, "", 1, gensub(/^[[:space:]][[:space:]]*/, "", 1, s));
}
function write_options() {
  print("TITLE=" Title);
  print("VERSION=" version());
  print("CREATOR=" Creator);
  print("IDENT=" Ident);
  print("ABSTRACT=" Abstract);
  print("REQUIRES=" combine(Requires, Requires["n"]));
  print("SOURCES=" combine(Sources, Sources["n"]));
  print("FINAL=" Final);
  print("ENTRYPOINT=" Entrypoint);
}
function write_dependencies() {
  for(i=1; i<=Sources["n"]; i++) {
    dep = Sources[i];
    if(Dependencies[dep]!=0) {
      deps = combine_2(Dependencies, dep, Dependencies[dep])
      print(dep ": " deps);
    } else {
      print("#skipped " dep);
    }
  }
}

BEGIN{
  TEMPLATE="Makefile.template";

  Symbol="";
  Title="";
  Version[1]=0;
  Version[2]=0;
  Version[3]=0;
  Creator="noman";
  Ident="";
  Abstract="";
  Final="";
  Entrypoint="main";
}
/\(define-system/ {
  setsymbol($2);
}
/title:/ {
  Title=unstring($2);
}
/version:/ {
  tver[1] = 0;
  n = split(extract($0, "\x27\\(.*\\)", 2, 1), tver, /[[:space:]]+/);
  Version[1] = (n<1 ? 0 : tver[1]);
  Version[2] = (n<2 ? 0 : tver[2]);
  Version[3] = (n<3 ? 0 : tver[3]);
}
/creator:/ {
  Creator=unstring($2);
}
/ident:/ {
  Ident=unstring($2);
}
/abstract:/ {
  Abstract=unstring(gensub(/^.*abstract:[[:space:]]*/, "", 1, $0));
}
/entry:/ {
  Entrypoint=gensub("^\x27", "", 1, $2);
}
/\(requires/ {
  n=readblock(Requires);
  a=0;
  for(i in Requires) {
    tmp = unstring(trim(Requires[i]));
    tmp = gensub(/\.clib$/, "", 1, tmp);
    if(tmp=="c") {
      n--;
      a++;
    } else {
      Requires[i-a] = "-l" tmp;
    }
  }
  Requires["n"] = n;
}
function filename(x) {
  return extract(x, "#{.*}", 2, 1);
}
/\(sources/ {
  n=readblock(Sources);
  a=0;
  d=0;
  for(i in Sources) {
    d=0;
    tmp=trim(Sources[i]);
    if(tmp ~ /\(/) {
      tmp = extract(tmp, "\\(.*\\)", 1, 1);
      d=split(tmp, adeps, /[[:space:]]+/);
      tmp = "sources/" filename(adeps[1]);
      d--;
      for(j=1; j<=d; j++) {
        Dependencies[tmp,j] = "sources/" filename(adeps[j+1]);
      }
      Dependencies[tmp] = d;
    } else {
      tmp = "sources/" filename(tmp);
    }
    if(tmp ~ /.h$/) {
      Dependencies[tmp]=0;
      n--;
      a++;
    } else {
      Sources[i-a] = tmp;
      Dependencies[tmp] = d;
    }
  }
  Sources["n"] = n;
}
END{
  while((getline line < TEMPLATE)>0) {
    if(line ~ /%OPTIONS%/) {
      write_options();
    } else if(line ~ /%DEPENDENCIES%/) {
      write_dependencies();
    } else {
      print(line);
    }
  }
}' $1 > Makefile
