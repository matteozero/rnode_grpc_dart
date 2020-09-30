import 'package:flutter_test/flutter_test.dart';

import 'package:rnode_grpc_dart/rnode_grpc_dart.dart';
import 'package:rnode_grpc_dart/src/generated_protoc_files/DeployServiceCommon.pb.dart';
import 'package:rnode_grpc_dart/src/generated_protoc_files/DeployServiceV1.pb.dart';
import 'package:rnode_grpc_dart/src/rnode_grpc/rnode_grpc.dart';

String checkBalanceRho(String revAddress) {
  String rho = """
  new return, rl(\`rho:registry:lookup\`), RevVaultCh, vaultCh in {
    rl!(\`rho:rchain:revVault\`, *RevVaultCh) |
    for (@(_, RevVault) <- RevVaultCh) {
      @RevVault!("findOrCreate", "$revAddress", *vaultCh) |
      for (@maybeVault <- vaultCh) {
        match maybeVault {
          (true, vault) => @vault!("balance", *return)
          (false, err)  => return!(err)
        }
      }
    }
  }
  """;
  return rho;
}

void main() {
  test('test', () async {
    RNodeExploratoryDeployGRPCService.shared.setDeployChannelHost(
        host: "observer-asia.services.mainnet.rchain.coop");
    print("host:${RNodeExploratoryDeployGRPCService.shared.host}");

    String term = checkBalanceRho(
        "11112mmfnqD3UgtpEAmFxVfU6g26W7fdyFgS6dNUpk9ycS2GXYU3pL");
    final ExploratoryDeployResponse result =
        await RNodeExploratoryDeployGRPCService.shared
            .sendExploratoryDeploy(deployCode: term);
    print("result: ${result.result.postBlockData.first.exprs.first.gInt}");
  });
}
