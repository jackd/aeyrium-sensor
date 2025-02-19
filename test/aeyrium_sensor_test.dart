import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('${AeyriumSensor.sensorEvents} are streamed', () async {
    const String channelName = 'plugins.aeyrium.com/sensor';
    const List<double> sensorData = <double>[1.0, 2.0];

    const StandardMethodCodec standardMethod = StandardMethodCodec();

    void emitEvent(ByteData? event) {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .handlePlatformMessage(
        channelName,
        event,
        (ByteData? reply) {},
      );
    }

    bool isCanceled = false;
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMessageHandler(channelName, (ByteData? message) async {
      final MethodCall methodCall = standardMethod.decodeMethodCall(message);
      if (methodCall.method == 'listen') {
        emitEvent(standardMethod.encodeSuccessEnvelope(sensorData));
        emitEvent(null);
        return standardMethod.encodeSuccessEnvelope(null);
      } else if (methodCall.method == 'cancel') {
        isCanceled = true;
        return standardMethod.encodeSuccessEnvelope(null);
      } else {
        fail('Expected listen or cancel');
      }
    });

    final SensorEvent event = await AeyriumSensor.sensorEvents.first;
    expect(event.pitch, 1.0);
    expect(event.roll, 2.0);

    await Future<Null>.delayed(Duration.zero);
    expect(isCanceled, isTrue);
  });
}
