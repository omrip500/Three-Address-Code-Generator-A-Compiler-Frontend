CC = gcc
OBJECTS = lex.yy.o gen.tab.o symboltable.o

#first target is the default target
gen: $(OBJECTS)
	$(CC) $(OBJECTS) -o gen
	
gen.tab.c gen.tab.h: gen.y
	bison -d gen.y
	
	
lex.yy.c: gen.lex
	flex gen.lex

lex.yy.o: lex.yy.c gen.tab.h
	$(CC) -c lex.yy.c
	
gen.tab.o: gen.tab.c gen.tab.h symboltable.h
	$(CC) -c gen.tab.c
	
symboltable.o: symboltable.c symboltable.h
	$(CC) -c symboltable.c

# clean is a 'phony target'  (not a file)	
clean:
	rm -f gen $(OBJECTS) gen.tab.c gen.tab.h lex.yy.c
	
	
	