#!/bin/bash

logFile=$1
serverName=$2
moduleName=$3
timeLtd=$4
allmobiles=`cat ./allcellphone.ini`
devmobiles=`cat ./devcellphone.ini`
preLine=`wc -l $logFile|awk '{print $1}'`
preIntervalLine=1
preSentTime=`date +%s`
intervalTime=0
hitTimes=0
counter=0

while true
do
    sleep $timeLtd
    currLine=`wc -l $logFile|awk '{print $1}'`
    echo ==============predebug=====================================
    echo 'preLine:'$preLine
    echo 'currLine:'$currLine
    echo ==============centerdebug===========

    if [[ $counter -gt 9 ]];then
	counter=0
    fi

    if [[ $intervalTime -gt 9 ]];then
	intervalTime=0
    fi 
    intervalTime=`expr $intervalTime + 1` 

    if [[ `expr $preLine - $currLine` -eq 1 ]];then
        continue
    fi

    if [[ `expr $preLine - $currLine` -gt 1 ]];then
        preLine=1
		preIntervalLine=1
    fi
    searchNum=`sed -n "$preLine,${currLine}p" $logFile|grep -v 'GlobalExceptionHandler'|grep -v 'KugouLogicException'|grep -v 'createSQLException'|grep -v 'SQLExceptionTranslator'|grep -v 'Duplicate entry'|grep -v "errorCode:"|grep -v "FXCache - 放入BadFuture缓存"|grep -v "HttpRequestMethodNotSupportedException"|grep -v "Broken pipe"|grep -vi "IMsgEnumType Exception"|grep -v "request param is null"|grep -v "NullPointerException: null"|grep -v "InvalidProtocolBufferException"|grep -i -n 'exception'>./temp$moduleName.unl;wc -l ./temp$moduleName.unl|awk '{print $1}'`


    if [[ $searchNum -gt 1 ]];then
		 hitTimes=`expr $hitTimes + 1`
		 cat ./temp$moduleName.unl>>col$moduleName.unl
    fi

    dateStrSec=`date +%s`
    if [[ `expr $dateStrSec - $preSentTime` -gt 299 ]];then
		dateStr=`date +%Y%m%d%H%M%S`
		if [[ $hitTimes -gt 9 ]];then
                expInfo=`head -1 ./col$moduleName.unl`
		lExpInfo=${expInfo%Exception*}
		fExpInfo=${lExpInfo##*[.| |$]}
		
		content="[sh][fatal]$dateStr:$serverName:$moduleName:$preIntervalLine~$currLine(col) hits 2*$hitTimes $fExpInfo"
		jsonContent="[1,\"sendSms\",1,1,{\"1\":{\"rec\":{\"1\":{\"str\":\"$allmobiles\"},\"2\":{\"str\":\"monitor\"},\"3\":{\"str\":\"$content\"}}}}]"
		#curl -H 'protocol:json' -d "$jsonContent" http://soa.fanxing.kgidc.cn/soa/sms/thrift/sendsms
		wget --header="protocol:json" --post-data="$jsonContent" http://soa.fanxing.kgidc.cn/soa/sms/thrift/sendsms
		echo $content >>./SmsUtil.log
		cat ./col$moduleName.unl >>./SmsUtil.log
		rm ./col$moduleName.unl
        fi

        if [[ $hitTimes -gt 0 ]] && [[ $hitTimes -lt 10 ]];then
                expInfo=`head -1 ./col$moduleName.unl`
			lExpInfo=${expInfo%Exception*}
			fExpInfo=${lExpInfo##*[.| |$]}

			content="[sh][normal]$dateStr:$serverName:$moduleName:$preIntervalLine~$currLine(col) hits 2*$hitTimes $fExpInfo"
			jsonContent="[1,\"sendSms\",1,1,{\"1\":{\"rec\":{\"1\":{\"str\":\"$devmobiles\"},\"2\":{\"str\":\"monitor\"},\"3\":{\"str\":\"$content\"}}}}]"
			#curl -H 'protocol:json' -d "$jsonContent" http://soa.fanxing.kgidc.cn/soa/sms/thrift/sendsms

                if [[ $hitTimes -gt 4 ]] && [[ $fExpInfo != 'Timeout' ]];then
					wget --header="protocol:json" --post-data="$jsonContent" http://soa.fanxing.kgidc.cn/soa/sms/thrift/sendsms
                fi

		echo $content >>./SmsUtil.log
		cat ./col$moduleName.unl >>./SmsUtil.log
		rm ./col$moduleName.unl
        fi

		preSentTime=$dateStrSec
		preIntervalLine=`expr $currLine + 1`
        hitTimes=0
        echo 'interval' 
    fi

    preLine=`expr $currLine + 1`
    counter=`expr $counter + 1`
    
    echo 'counter:'$counter
    echo 'hittimes:'$hitTimes 
    echo 'currTime:'`date +%Y%m%d%H%M%S`
    echo ==============enddebug========================================
    echo "***                                                        ***" 
done