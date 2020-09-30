library rsign;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:rnode_grpc_dart/src/generated_protoc_files/CasperMessage.pb.dart';
// import 'package:capo_core_dart/src/utils/numbers.dart';
// import 'package:capo_core_dart/src/utils/utils.dart';
import 'package:fixnum/fixnum.dart';
import "package:pointycastle/export.dart";

final ECDomainParameters _params = ECCurve_secp256k1();
final BigInt _halfCurveOrder = _params.n >> 1;

List<int> encodeToDER(ECSignature signature) {
  ASN1Sequence seq = new ASN1Sequence();
  seq.add(new ASN1Integer(signature.r));
  seq.add(new ASN1Integer(signature.s));
  return seq.encodedBytes;
}

DeployDataProto sign(
    {@required Int64 blockNumber,
    @required DeployDataProto unSignData,
    @required String privateKey}) {
  final privateKeyInt = hexToBigInt(privateKey);
  ECPrivateKey ecPrivateKey = ECPrivateKey(privateKeyInt, _params);
  DeployDataProto signData = unSignData.clone();
  final timestamp = signData.timestamp != 0
      ? signData.timestamp
      : Int64(DateTime.now().millisecondsSinceEpoch);
  signData.clearSigAlgorithm();
  signData.timestamp = timestamp;
  signData.phloLimit = Int64(50e4.toInt());
  signData.phloPrice = Int64(1);
  if (blockNumber != 0) {
    signData.validAfterBlockNumber = blockNumber;
  }

  final blake2b = Blake2bDigest(digestSize: 32);
  blake2b.reset();
  var messageHash = blake2b.process(signData.writeToBuffer());
  final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));

  signer.init(true, PrivateKeyParameter(ecPrivateKey));
  ECSignature signature = signer.generateSignature(messageHash);
  if (signature.s.compareTo(_halfCurveOrder) > 0) {
    final canonicalSedS = _params.n - signature.s;
    signature = ECSignature(signature.r, canonicalSedS);
  }
  final sig = encodeToDER(signature);

  final puk = privateKeyToPublicUint8List(ecPrivateKey.d);
  signData.deployer = puk;
  signData.sig = sig;
  signData.sigAlgorithm = "secp256k1";
  return signData;
}

Uint8List privateKeyToPublicUint8List(BigInt privateKey) {
  final p = _params.G * privateKey;
  return Uint8List.view(p.getEncoded(false).buffer, 0);
}

BigInt hexToBigInt(String hex) {
  return BigInt.parse(strip0x2String(hex), radix: 16);
}

String strip0x2String(String hex) {
  if (hex.startsWith("0x")) return hex.substring(2);
  return hex;
}
