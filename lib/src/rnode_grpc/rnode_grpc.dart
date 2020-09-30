library rnode_grpc;

import 'package:rnode_grpc_dart/src/generated_protoc_files/CasperMessage.pb.dart';
import 'package:rnode_grpc_dart/src/generated_protoc_files/DeployServiceCommon.pb.dart';
import 'package:rnode_grpc_dart/src/generated_protoc_files/DeployServiceV1.pbgrpc.dart';
import 'package:rnode_grpc_dart/src/rsign/rsign.dart' as rSign;
import 'package:flutter/cupertino.dart';
import 'package:grpc/grpc.dart';
import 'package:hex/hex.dart';

class RNodeDeployGRPCService {
  String host;
  int port;
  DeployServiceClient _deployService;

  static final RNodeDeployGRPCService shared =
      RNodeDeployGRPCService._internal();
  final ChannelOptions options =
      const ChannelOptions(credentials: const ChannelCredentials.insecure());

  RNodeDeployGRPCService._internal();

  void setDeployChannelHost({@required String host, int port = 40401}) {
    this.host = host;
    this.port = port;
    ClientChannel channel = ClientChannel(host, port: port, options: options);
    _deployService = DeployServiceClient(channel);
  }

  Future<Map> sendDeploy(
      {@required String deployCode, @required String privateKey}) async {
    final blocksQuery = BlocksQuery();
    blocksQuery.depth = 1;
    final blocks = await _deployService.getBlocks(blocksQuery).first;
    final blockNumber = blocks.blockInfo.blockNumber;

    final data = DeployDataProto();
    data.term = deployCode;
    final DeployDataProto signedData = rSign.sign(
        blockNumber: blockNumber, unSignData: data, privateKey: privateKey);
    DeployResponse response = await _deployService.doDeploy(signedData);
    return {"deployID": HEX.encode(signedData.sig), "response": response};
  }
}

class RNodeExploratoryDeployGRPCService {
  String host;
  int port;
  DeployServiceClient _exploratoryDeployService;

  static final RNodeExploratoryDeployGRPCService shared =
      RNodeExploratoryDeployGRPCService._internal();
  final ChannelOptions options =
      const ChannelOptions(credentials: const ChannelCredentials.insecure());

  RNodeExploratoryDeployGRPCService._internal();

  void setDeployChannelHost({@required String host, int port = 40401}) {
    this.host = host;
    this.port = port;
    ClientChannel channel = ClientChannel(host, port: port, options: options);
    _exploratoryDeployService = DeployServiceClient(channel);
  }

  Future<ExploratoryDeployResponse> sendExploratoryDeploy(
      {@required String deployCode}) async {
    var params = ExploratoryDeployQuery();
    params.term = deployCode;
    var response = await _exploratoryDeployService.exploratoryDeploy(params);
    return response;
  }
}
