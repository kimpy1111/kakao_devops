# DevOps

## 1. 개발 환경

### 1-1. 인프라 환경

* CentOS Linux release 7.5

* Docker-ce 1.13.1

* Docker-compose 1.22.0

### 1-2. 어플리케이션 환경

* Java 8

* Spring boot 2.0.4

* Grade 4.9



## 2. 소스코드 Git Repository

* Springboot application(서비스 동작 시 어플리케이션 소스코드는 필요없음)
  https://github.com/kimpy1111/springboot-sample-web

* DevOps container system
  https://github.com/kimpy1111/kakao_devops



## 3. 사전 구성 및 실행 방법

### 3-1. 사전 구성

* 서비스 환경으로 접속하기 위한 호스트 추가(/etc/hosts, IpAddress는 서비스가 기동되고 있는 서버의 IP)

  ```192.168.0.1	spring.application.com```

* docker engine, docker-compose  사전 설치 필요

  * docker-ce: https://docs.docker.com/install/linux/docker-ce/centos/
  * docker-compose: https://docs.docker.com/compose/install/

* docker 명령어 사용을 위한 권한

  * docker 명령어는 root권한이 필요

  * 해당 사용자를 docker 그룹에 추가

    ```sudo usermod -aG docker <user-name>```

  * Docker.io registry 사용을 위한 방화벽 정책 변경 필요

* 소스코드 clone을 위한 git 설치

  * git 설치
  * Devops container system 사용을 위한 git clone
      (Spring boot application은 dockerfile을 통한 자동빌드로 git clone 불필요)
      ```sudo git clone https://github.com/kimpy1111/kakao_devops.git```

* 도커 엔진 실행

  * 도커 서비스 실행
      ```sudo service docker start```
  * 도커 서비스 상태 확인
      ```sudo service docker status```

### 3-2. 실행 방법

* 서비스 시작: 첫 시작시에는 Dockerfile을 토대로 Docker build 후 서비스가 기동

  * 디폴트 (어플리케이션 컨테이너 1개)
      ```bash ./devops.sh start```
  * 스케일 옵션 (어플리케이션 컨테이너 n개)
      ```bash ./devops.sh start scale=n```

* 서비스 스케일링

  * 스케일 조정(어플리케이션 컨테이너 n개)
      ```bash ./devops.sh scale n```

* 서비스 중지

  * 서비스 중지
      ```bash ./devops.sh stop```

* 서비스 재시작

  * 서비스 재시작
      ```bash ./devops.sh restart```

* 서비스 배포

  * Blue-Green 무중단 배포
      ```bash ./devops.sh deploy```



## 4. 서비스 확인

### 4-1. 웹 어플리케이션 확인

* spring.application.com 으로 접속(사전 호스트 설정 필요) -> Thymeleaf message 페이지 확인

* nginx round robin 테스트
  * 테스트 메시지를 생성 후, 컨테이너 스케일 아웃(1개에서 2개) 진행 -> 메시지 등록 -> 번갈아가며 메시지 출력 확인

### 4-2. 서비스 쉘 명령어에 따른 컨테이너 구동 확인

- docker ps를 통한 컨테이너 확인 ```docker ps```

### 4-3. log 및 설정 파일 저장 경로

- 어플리케이션 로그 위치(호스트)
  ```./kakao_devops/logs/```

- nginx upstream 및 proxy_pass 정보 파일 위치(호스트)

  ```./kakao_devops/conf.d/```
