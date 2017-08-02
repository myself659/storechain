#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#set -e

CHANNEL_NAME=$1
: ${CHANNEL_NAME:="mychannel"}
echo $CHANNEL_NAME

export FABRIC_ROOT=/opt/fabric
export FABRIC_CFG_PATH=$PWD
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

##  Generates Org certs using cryptogen tool
function generateCerts (){
    CRYPTOGEN=$FABRIC_ROOT/bin/cryptogen

    if [ -f "$CRYPTOGEN" ]; then
            echo "Using cryptogen -> $CRYPTOGEN"
    else
        echo "Downloading fabric cryptogen binaries > /opt/fabric/bin "
    fi

    echo
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"
    ##  生成crypto-config文件夹，包括加密公钥私钥证书等
    $CRYPTOGEN generate --config=$FABRIC_CFG_PATH/cryptogen.yaml
    echo
}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {

    CONFIGTXGEN=$FABRIC_ROOT/bin/configtxgen
    if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
    else
        echo "Downloading fabric configtxgen binaries > /opt/fabric/bin "
    fi

    #mkdir ./channel-artifacts

    echo "##########################################################"
    echo "#########  Generating Orderer Genesis block ##############"
    echo "##########################################################"
    # Note: For some unknown reason (at least for now) the block file can't be
    # named orderer.genesis.block or the orderer will fail to launch!

    ## 生成genesis.block
    $CONFIGTXGEN -profile TwoOrgsOrdererGenesis -outputBlock  genesis.block

    echo
    echo "#################################################################"
    echo "### Generating channel configuration transaction 'channel.tx' ###"
    echo "#################################################################"

    ## 生成channel.tx
    $CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx  mychannel.tx -channelID $CHANNEL_NAME

    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org1MSP   ##########"
    echo "#################################################################"

    ## 生成Org1MSPanchors.tx
    $CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org2MSP   ##########"
    echo "#################################################################"

    ## 生成Org2MSPanchors.tx
    $CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
    echo
}

generateCerts
generateChannelArtifacts