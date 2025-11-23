import 'package:dialog_flowtter/dialog_flowtter.dart';

class DialogflowService {
  DialogFlowtter? _dialogFlowtter;

  Future<void> initialize() async {
    final sessionClient = await DialogFlowtter.fromFile(path: 'assets/dialogflow_key.json');
    _dialogFlowtter = sessionClient;
  }

  Future<String>getResponse(String message) async {
    if (_dialogFlowtter == null) {
      await initialize();
    }

    try {
      final DetectIntentResponse response = await _dialogFlowtter!.detectIntent(
        queryInput: QueryInput(text: TextInput(text: message)),
      );

      if (response.message == null || response.message!.text == null) {
        return "I'm sorry, I don't understand. Can you please rephrase?";
      }

      return response.message!.text!.text![0];
    } catch (e) {
      return "I'm having trouble connecting. Please try again later.";
    }
  }
}
