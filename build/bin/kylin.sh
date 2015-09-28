#!/bin/bash

dir=$(dirname ${0})
source ${dir}/check-env.sh
mkdir -p ${KYLIN_HOME}/logs

# start command
if [ $1 == "start" ]
then

    tomcat_root=${dir}/../tomcat
    export tomcat_root


    #The location of all hadoop/hbase configurations are difficult to get.
    #Plus, some of the system properties are secretly set in hadoop/hbase shell command.
    #For example, in hdp 2.2, there is a system property called hdp.version,
    #which we cannot get until running hbase or hadoop shell command.
    #
    #To save all these troubles, we use hbase runjar to start tomcat.
    #In this way we no longer need to explicitly configure hadoop/hbase related classpath for tomcat,
    #hbase command will do all the dirty tasks for us:



    useSandbox=`sh ${dir}/get-properties.sh kylin.sandbox`
    spring_profile="default"
    if [ "$useSandbox" = "true" ]
        then spring_profile="sandbox"
    fi

    #retrive $hive_dependency and $hbase_dependency
    source ${dir}/find-hive-dependency.sh
    source ${dir}/find-hbase-dependency.sh
    #retrive $KYLIN_EXTRA_START_OPTS
    if [ -f "${dir}/setenv.sh" ]
        then source ${dir}/setenv.sh
    fi

    export HBASE_CLASSPATH_PREFIX=${tomcat_root}/bin/bootstrap.jar:${tomcat_root}/bin/tomcat-juli.jar:${tomcat_root}/lib/*:$HBASE_CLASSPATH_PREFIX
    export HBASE_CLASSPATH=$hive_dependency:${HBASE_CLASSPATH}

    #debug if encounter NoClassDefError
    #hbase classpath

    # KYLIN_EXTRA_START_OPTS is for customized settings, checkout bin/setenv.sh
    hbase ${KYLIN_EXTRA_START_OPTS} \
    -Djava.util.logging.config.file=${tomcat_root}/conf/logging.properties \
    -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
    -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true \
    -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true \
    -Djava.endorsed.dirs=${tomcat_root}/endorsed  \
    -Dcatalina.base=${tomcat_root} \
    -Dcatalina.home=${tomcat_root} \
    -Djava.io.tmpdir=${tomcat_root}/temp  \
    -Dkylin.hive.dependency=${hive_dependency} \
    -Dkylin.hbase.dependency=${hbase_dependency} \
    -Dspring.profiles.active=${spring_profile} \
    org.apache.hadoop.util.RunJar ${tomcat_root}/bin/bootstrap.jar  org.apache.catalina.startup.Bootstrap start >> ${KYLIN_HOME}/logs/kylin.log 2>&1 & echo $! > ${KYLIN_HOME}/pid &
    echo "A new Kylin instance is started by $USER, stop it using \"kylin.sh stop\""
    if [ "$useSandbox" = "true" ]
        then echo "Please visit http://<your_sandbox_ip>:7070/kylin to play with the cubes! (Useranme: ADMIN, Password: KYLIN)"
    else
        echo "Please visit http://<ip>:7070/kylin"
    fi
    echo "You can check the log at ${KYLIN_HOME}/logs/kylin.log"
    exit 0

# stop command
elif [ $1 == "stop" ]
then
    if [ ! -f "${KYLIN_HOME}/pid" ]
    then
        echo "kylin is not running, please check"
        exit 1
    fi
    pid=`cat ${KYLIN_HOME}/pid`
    if [ "$pid" = "" ]
    then
        echo "kylin is not running, please check"
        exit 1
    else
        echo "stopping kylin:$pid"
        kill $pid
    fi
    rm ${KYLIN_HOME}/pid
    exit 0

# streaming command
elif [ $1 == "streaming" ]
then
    if [ $# -lt 4 ]
    then
        echo "invalid input args $@"
        exit -1
    fi
    if [ $2 == "start" ]
    then
        useSandbox=`sh ${dir}/get-properties.sh kylin.sandbox`
        spring_profile="default"
        if [ "$useSandbox" = "true" ]
            then spring_profile="sandbox"
        fi

        #retrive $hive_dependency and $hbase_dependency
        source ${dir}/find-hive-dependency.sh
        source ${dir}/find-hbase-dependency.sh
        #retrive $KYLIN_EXTRA_START_OPTS
        if [ -f "${dir}/setenv.sh" ]
            then source ${dir}/setenv.sh
        fi

        mkdir -p ${KYLIN_HOME}/ext
        export HBASE_CLASSPATH=$hive_dependency:${KYLIN_HOME}/lib/*:${KYLIN_HOME}/ext/*:${HBASE_CLASSPATH}

        # KYLIN_EXTRA_START_OPTS is for customized settings, checkout bin/setenv.sh
        hbase ${KYLIN_EXTRA_START_OPTS} \
        -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
        -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true \
        -Dkylin.hive.dependency=${hive_dependency} \
        -Dkylin.hbase.dependency=${hbase_dependency} \
        -Dspring.profiles.active=${spring_profile} \
        org.apache.kylin.engine.streaming.cli.StreamingCLI $@ > ${KYLIN_HOME}/logs/streaming_$3_$4.log 2>&1 & echo $! > ${KYLIN_HOME}/logs/$3_$4 &
        echo "streaming started name: $3 id: $4"
        exit 0
    elif [ $2 == "stop" ]
    then
        if [ ! -f "${KYLIN_HOME}/$3_$4" ]
        then
            echo "streaming is not running, please check"
            exit 1
        fi
        pid=`cat ${KYLIN_HOME}/$3_$4`
        if [ "$pid" = "" ]
        then
            echo "streaming is not running, please check"
            exit 1
        else
            echo "stopping streaming:$pid"
            kill $pid
        fi
        rm ${KYLIN_HOME}/$3_$4
        exit 0
    else
        echo
    fi

# monitor command
elif [ $1 == "monitor" ]
then
    echo "monitor job"
    tomcat_root=${dir}/../tomcat
    export tomcat_root
    useSandbox=`sh ${dir}/get-properties.sh kylin.sandbox`
    spring_profile="default"
    if [ "$useSandbox" = "true" ]
        then spring_profile="sandbox"
    fi

    #retrive $hive_dependency and $hbase_dependency
    source ${dir}/find-hive-dependency.sh
    source ${dir}/find-hbase-dependency.sh
    #retrive $KYLIN_EXTRA_START_OPTS
    if [ -f "${dir}/setenv.sh" ]
        then source ${dir}/setenv.sh
    fi

    mkdir -p ${KYLIN_HOME}/ext
    export HBASE_CLASSPATH_PREFIX=${tomcat_root}/bin/bootstrap.jar:${tomcat_root}/bin/tomcat-juli.jar:${tomcat_root}/lib/*:$HBASE_CLASSPATH_PREFIX
    export HBASE_CLASSPATH=$hive_dependency:${KYLIN_HOME}/lib/*:${KYLIN_HOME}/ext/*:${HBASE_CLASSPATH}

    # KYLIN_EXTRA_START_OPTS is for customized settings, checkout bin/setenv.sh
    hbase ${KYLIN_EXTRA_START_OPTS} \
    -Djava.util.logging.config.file=${tomcat_root}/conf/logging.properties \
    -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
    -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true \
    -Dkylin.hive.dependency=${hive_dependency} \
    -Dkylin.hbase.dependency=${hbase_dependency} \
    -Dspring.profiles.active=${spring_profile} \
    org.apache.kylin.engine.streaming.cli.MonitorCLI $@ > ${KYLIN_HOME}/logs/monitor.log 2>&1
    exit 0

# tool command
elif [[ $1 = org.apache.kylin.* ]]
then
    #retrive $hive_dependency and $hbase_dependency
    source ${dir}/find-hive-dependency.sh
    source ${dir}/find-hbase-dependency.sh
    #retrive $KYLIN_EXTRA_START_OPTS
    if [ -f "${dir}/setenv-tool.sh" ]
        then source ${dir}/setenv-tool.sh
    fi

    export HBASE_CLASSPATH=${KYLIN_HOME}/lib/*:$hive_dependency:${HBASE_CLASSPATH}

    exec hbase "$@"

else
    echo "usage: kylin.sh start or kylin.sh stop"
    exit 1
fi
