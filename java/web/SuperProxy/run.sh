. addtoclasspath $HOME/j/code/javawebtools/CommonUtils/bin
. addtoclasspath $HOME/j/code/javawebtools/SimpleProxy/classes
for JAR in $PWD/lib/*.jar
do . addtoclasspath "$JAR"
done
. addtoclasspath $PWD/bin

java org.neuralyte.superproxy.SuperProxy "$@"
