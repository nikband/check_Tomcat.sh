#!/bin/sh

# Set some defaults
export THE_VERSION="0.3"
export THE_HOSTNAME=localhost
export THE_PORT=8080
export THE_USERNAME=tomcat
export THE_PASSWORD=password
export CHECK_TYPE="mem"
export WARNING_LEVEL=500
export CRITICAL_LEVEL=600
export XMLSTATUS=""
#export TOMCAT_VERSION="7"
export PERFLOG="1" #Sempre attivi i perflog

#Nagios Return Value
export OK_STATUSLEVEL=0
export OK_STATUSSTRING="OK"
export WARNING_STATUSLEVEL=1
export WARNING_STATUSSTRING="WARNING"
export CRITICAL_STATUSLEVEL=2
export CRITICAL_STATUSSTRING="CRITICAL"
export UNKNOWN_STATUSLEVEL=3
export UNKNOWN_STATUSSTRING="UNKNOWN"

export STATUSLEVEL=$OK_STATUSLEVEL
export STATUSSTRING="$OK_STATUSSTRING"

export WGET=`which wget`
if [ -z "$WGET" ]
then
	echo "wget command not found. This plugin depends on it. Please install it and put it in path."
	exit 1
fi

export AWK=`which awk`
if [ -z "$WGET" ]
then
	echo "awk command not found. This plugin depends on it. Please install it and put it in path."
	exit 1
fi

round()
{
echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc))
};

usage ()
{
	echo "Usage: `basename $0` [ -H hostname or IP address ] [ -P port ] [ -u username ] [ -p password ] [ -n check_type ] [ -w warning ] [ -c critical ]" >&2
	echo ""
	
	echo ""
	echo "DEFAULTS" >&2
	echo "hostname=localhost" >&2
	echo "port=8080" >&2
	echo "username=tomcat" >&2
	echo "password=password" >&2
	echo "check_type=[mem(default),app,]" >&2
	echo "warning=500" >&2
	echo "critical=600" >&2
	#echo "tomcat_version=7" >&2

	exit 1
}

version ()
{
	echo "`basename $0` $THE_VERSION"
}


# MAIN

while getopts ":u:p:H:P:s:w:c:V:hv" opt
do
	case "$opt" in
		u)
			THE_USERNAME="$OPTARG"
		;;
		p)
			THE_PASSWORD="$OPTARG"
		;;
		H)
			THE_HOSTNAME="$OPTARG"
		;;
		P)
			THE_PORT="$OPTARG"
		;;
		n)
			CHECK_TYPE="$OPTARG"
		;;
		w)
			WARNING_LEVEL="$OPTARG"
		;;
		c)
			CRITICAL_LEVEL="$OPTARG"
		;;
		h)
			usage
			exit 1
		;;
#		V)
#			TOMCAT_VERSION="$OPTARG"
#		;;
#		f)
#			PERFLOG="1"
#			exit 1
#		;;
		v)
			version
			exit 1
		;;
	esac
done

# Check TOMCAT
# Tomcat Status

XMLSTATUS=`$WGET -o /dev/null -O - "http://$THE_USERNAME:$THE_PASSWORD@$THE_HOSTNAME:$THE_PORT/manager/status?XML=true"`
if [ -z "$XMLSTATUS" -o "$?" -gt 0 ]
then
	STATUSLEVEL=$UNKNOWN_STATUSLEVEL
	STATUSSTRING="$UNKNOWN_STATUSSTRING"
fi

#echo "STATUS XML: " $XMLSTATUS

JVMMEMORY=`echo $XMLSTATUS | grep -oPm1 "(?<=<memory )[^/]+"`
JVMMEM_FREE=`echo $JVMMEMORY | awk '{ print $1 }' | xargs | cut -d "=" -f 2`
JVMMEM_TOT=`echo $JVMMEMORY | awk '{ print $2 }' | xargs | cut -d "=" -f 2`
JVMMEM_MAX=`echo $JVMMEMORY | awk '{ print $3 }' | xargs | cut -d "=" -f 2`

#Convert in MB
JVMMEM_FREE_MB=`echo $JVMMEM_FREE | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
JVMMEM_TOT_MB=`echo $JVMMEM_TOT | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
JVMMEM_MAX_MB=`echo $JVMMEM_MAX | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`

POOLMEMORYAR=`echo $XMLSTATUS | grep -oPm1 "(?<=<memorypool )[^/]+"`

#HEAP MEMORY
  #PS EDEN SPACE
PS_EDEN_INIT=`echo $POOLMEMORYAR | awk '{ print $6 }' | xargs | cut -d "=" -f 2`
PS_EDEN_COM=`echo $POOLMEMORYAR | awk '{ print $7 }' | xargs | cut -d "=" -f 2`
PS_EDEN_MAX=`echo $POOLMEMORYAR | awk '{ print $8 }' | xargs | cut -d "=" -f 2`
PS_EDEN_USED=`echo $POOLMEMORYAR | awk '{ print $9 }' | xargs | cut -d "=" -f 2`
PS_EDEN_INIT_MB=`echo $PS_EDEN_INIT | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_EDEN_COM_MB=`echo $PS_EDEN_COM | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_EDEN_MAX_MB=`echo $PS_EDEN_MAX | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_EDEN_USED_MB=`echo $PS_EDEN_USED | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`

  
  #PS OLD GEN
PS_OLD_INIT=`echo $POOLMEMORYAR | awk '{ print $15 }' | xargs | cut -d "=" -f 2`
PS_OLD_COM=`echo $POOLMEMORYAR | awk '{ print $16 }' | xargs | cut -d "=" -f 2`
PS_OLD_MAX=`echo $POOLMEMORYAR | awk '{ print $17 }' | xargs | cut -d "=" -f 2`
PS_OLD_USED=`echo $POOLMEMORYAR | awk '{ print $18 }' | xargs | cut -d "=" -f 2`
PS_OLD_INIT_MB=`echo $PS_OLD_INIT | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_OLD_COM_MB=`echo $PS_OLD_COM | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_OLD_MAX_MB=`echo $PS_OLD_MAX | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_OLD_USED_MB=`echo $PS_OLD_USED | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
  
  #PS SURVIVOR SPACE
PS_SURV_INIT=`echo $POOLMEMORYAR | awk '{ print $24 }' | xargs | cut -d "=" -f 2`
PS_SURV_COM=`echo $POOLMEMORYAR | awk '{ print $25 }' | xargs | cut -d "=" -f 2`
PS_SURV_MAX=`echo $POOLMEMORYAR | awk '{ print $26 }' | xargs | cut -d "=" -f 2`
PS_SURV_USED=`echo $POOLMEMORYAR | awk '{ print $27 }' | xargs | cut -d "=" -f 2`
PS_SURV_INIT_MB=`echo $PS_SURV_INIT | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_SURV_COM_MB=`echo $PS_SURV_COM | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_SURV_MAX_MB=`echo $PS_SURV_MAX | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_SURV_USED_MB=`echo $PS_SURV_USED | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
  
#NON HEAP MEMORY
  #CODE CACHE
PS_CODE_INIT=`echo $POOLMEMORYAR | awk '{ print $32 }' | xargs | cut -d "=" -f 2`
PS_CODE_COM=`echo $POOLMEMORYAR | awk '{ print $33 }' | xargs | cut -d "=" -f 2`
PS_CODE_MAX=`echo $POOLMEMORYAR | awk '{ print $34 }' | xargs | cut -d "=" -f 2`
PS_CODE_USED=`echo $POOLMEMORYAR | awk '{ print $35 }' | xargs | cut -d "=" -f 2`
PS_CODE_INIT_MB=`echo $PS_CODE_INIT | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_CODE_COM_MB=`echo $PS_CODE_COM | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_CODE_MAX_MB=`echo $PS_CODE_MAX | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_CODE_USED_MB=`echo $PS_CODE_USED | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
   
  #PS PERM GEN
PS_GEN_INIT=`echo $POOLMEMORYAR | awk '{ print $41 }' | xargs | cut -d "=" -f 2`
PS_GEN_COM=`echo $POOLMEMORYAR | awk '{ print $42 }' | xargs | cut -d "=" -f 2`
PS_GEN_MAX=`echo $POOLMEMORYAR | awk '{ print $43 }' | xargs | cut -d "=" -f 2`
PS_GEN_USED=`echo $POOLMEMORYAR | awk '{ print $44 }' | xargs | cut -d "=" -f 2`
PS_GEN_INIT_MB=`echo $PS_GEN_INIT | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_GEN_COM_MB=`echo $PS_GEN_COM | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_GEN_MAX_MB=`echo $PS_GEN_MAX | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`
PS_GEN_USED_MB=`echo $PS_GEN_USED | awk '{ foo = $1 / 1024 / 1024 ; print foo }'`

#the following command have to be chenged
CONNECTORAR=`echo $XMLSTATUS | grep -oPm1 "(?<=<connector )[^/]+"`

if [ `echo "$(round $JVMMEM_TOT_MB 0) - $WARNING_LEVEL" | bc` -ge 0 ]
then
	STATUSLEVEL=$WARNING_STATUSLEVEL
	STATUSSTRING="$WARNING_STATUSSTRING"
	if [ `echo "$(round $JVMMEM_TOT_MB 0) - $CRITICAL_LEVEL" | bc` -ge 0 ]
	then
		STATUSLEVEL=$CRITICAL_STATUSLEVEL
		STATUSSTRING="$CRITICAL_STATUSSTRING"
	fi
fi

heapmem_perf="Heap_PS_Eden=${PS_EDEN_USED}B:0:0:0:${PS_EDEN_MAX}, Heap_PS_OLDGEN=${PS_OLD_USED}B:0:0:0:${PS_OLD_MAX}, Heap_PS_SURVIVOR=${PS_SURV_USED}B:0:0:0:${PS_SURV_MAX}"
nonheap_perf="NoHeap_PS_Code=${PS_CODE_USED}B:0:0:0:${PS_CODE_MAX}, NoHeap_Perm_Gen=${PS_GEN_USED}B:0:0:0:${PS_GEN_MAX}"
jvm_perf="JvmMemoryFree=${JVMMEM_FREE}B:${WARNING_LEVEL}:${CRITICAL_LEVEL}:0:${JVMMEM_MAX}, JvmMemoryTotal=${JVMMEM_TOT}B:${WARNING_LEVEL}:${CRITICAL_LEVEL}:0:${JVMMEM_MAX}"

output="JVM Memory $STATUSSTRING: free=$JVMMEM_FREE_MB MB, total=$JVMMEM_TOT_MB MB, max=$JVMMEM_MAX_MB MB |"$jvm_perf","$heapmem_perf","$nonheap_perf
echo $output
exit $STATUSLEVEL

#End Script

