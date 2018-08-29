# /bin/bash

isGreen=-1
function func_createNetwork() {
  nwCnt=$(docker network ls | grep nginx-proxy -c)
  if [ $nwCnt == 0 ]; then
    echo "Create docker network"
    docker network create nginx-proxy
  fi
}

function func_createProxy() {
  proxyCnt=$(${docker_proxy} ps | grep proxy -c)
  if [ $proxyCnt -lt 1 ]; then
    echo "Create nginx proxy"
    docker-compose -f ./docker-compose-proxy.yml up -d
  fi
}

function func_start() {
  func_createNetwork
  func_checkBlueGreen
  if [ $isGreen -ge 0 ]; then
    echo "Already Started"
    return 0;
  fi
  if [[ $1 == *"scale"* ]]; then
    docker-compose -f ./docker-compose-blue.yml up -d --scale app_blue=${1#*=}
  else
    docker-compose -f ./docker-compose-blue.yml up -d
  fi
  container_ids=$(docker ps | grep app_blue | grep -o -e '^\S*')
  func_containerHealthCheck $container_ids
  func_createProxy
  echo "Start"
}

function func_stop() {
  docker-compose -f ./docker-compose-proxy.yml down
  greenCnt=$(docker-compose -f ./docker-compose-green.yml ps | grep app_green -c)
  blueCnt=$(docker-compose -f ./docker-compose-blue.yml ps | grep app_blue -c)
  func_checkBlueGreen
  if [ $greenCnt -gt 0 ]; then
    docker-compose -f ./docker-compose-green.yml down
  fi
  if [ $blueCnt -gt 0 ]; then
    docker-compose -f ./docker-compose-blue.yml down
  fi
}

function func_restart() {
  func_createNetwork
  func_checkBlueGreen
  if [ $isGreen = -1 ]; then
    func_start
  elif [ $isGreen = 1 ]; then
    docker-compose -f ./docker-compose-green.yml restart
  else
    docker-compose -f ./docker-compose-blue.yml restart
  fi
  container_ids=$(docker ps | grep app_blue | grep -o -e '^\S*')
  func_containerHealthCheck $container_ids
  docker-compose -f ./docker-compose-proxy.yml restart
}

function func_deploy() {
  if [ "$isGreen" = -1 ]; then
    func_start
  elif [ "$isGreen" = 1 ]; then
    docker-compose -f ./docker-compose-blue.yml pull
    docker-compose -f ./docker-compose-blue.yml up -d
    container_ids=$(docker ps | grep app_blue | grep -o -e '^\S*')
    func_containerHealthCheck $container_ids
    docker-compose -f ./docker-compose-green.yml down
  else
    docker-compose -f ./docker-compose-green.yml pull
    docker-compose -f ./docker-compose-green.yml up -d
    container_ids=$(docker ps | grep app_green | grep -o -e '^\S*')
    func_containerHealthCheck $container_ids
    docker-compose -f ./docker-compose-blue.yml down
  fi
  echo "Complete Deploy"
}

function func_scale() {
  size=$1
  func_checkBlueGreen
  if [ $isGreen = -1 ]; then
    echo "Container service is not started"
    return 0
  elif [ $isGreen = 1 ]; then
    docker-compose -f ./docker-compose-green.yml up -d --scale app_green=$1
  else
    docker-compose -f ./docker-compose-blue.yml up -d --scale app_blue=$1
  fi
}

function func_containerHealthCheck() {
  containerIds=($@)
  containerCnt=${#containerIds[@]}
  failCount=0
  echo "Checking containers health...."
  while [ $containerCnt -gt 0 -a $failCount -le 60 ]
  do
    for ((i=0; i<$containerCnt; i++))
    do
      id=${containerIds[$i]}
      ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $id)
      result=$(curl -s $ip:8080/health | grep -Po '(?<="health":")[^"]+')
      if [ "$result" = "up" ]; then
        containerCnt=$((containerCnt-1))
        echo "Container " $id " is status up"
        containerIds=( "${containerIds[@]:0:$i}" "${containerIds[@]:$((i+1))}" )
      fi
    done
    sleep 1
    failCount=$((failCount+1))
    echo "Waiting ... " $failCount/60
    printf "\033[A"
  done
}

function func_checkBlueGreen() {
  greenCnt=$(docker-compose -f ./docker-compose-green.yml ps | grep app_green -c)
  blueCnt=$(docker-compose -f ./docker-compose-blue.yml ps | grep app_blue -c)
  if [ $greenCnt -gt 0 ]; then
    isGreen=1
  fi
  if [ $blueCnt -gt 0 ]; then 
    isGreen=0
  fi
}

if [ "$1" = "start" ]; then
  echo "Devops Springboot Application Up"
  func_start $2
elif [ "$1" = "stop" ]; then
  echo "DevOps Springboot Application Down"
  func_stop
elif [ "$1" = "restart" ]; then
  echo "DevOps Springboot Application Restart"
  func_restart
elif [ "$1" = "deploy" ]; then
  echo "DevOps Springboot Application Deploy"
  func_checkBlueGreen
  func_deploy
elif [ "$1" = "scale" ]; then
  func_scale $2
else
  echo "This command is not defined"
fi

