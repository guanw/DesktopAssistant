import Foundation
import llmfarm_core

let maxOutputLength = 256
var total_output = 0

class LlamaClient {
    private var ai: AI;
    private var callback: (_ str: String, _ time: Double) -> Bool;

    func query(input_text: String) -> String? {
        return try? self.ai.model?.predict(input_text, self.callback)
    }

    init(withCallback callback: @escaping (_ str: String, _ time: Double) -> Bool) throws {
        self.callback = callback;
        // TODO update gguf location
        self.ai = AI(_modelPath: "/Users/guanw/Downloads/OpenLlama-3B-v2.Q8_0.gguf",_chatName: "chat")
        var params:ModelAndContextParams = .default

        //set custom prompt format
        params.promptFormat = .Custom
        params.custom_prompt_format = """
            SYSTEM: You are a helpful, respectful and honest assistant.
            USER: {prompt}
            ASSISTANT:
        """

        params.use_metal = true

        do {
            let is_model_loaded = try self.ai.loadModel(ModelInference.LLama_gguf,contextParams: params)
            if (!is_model_loaded) {
                print("failed to load model")
            }
        } catch {
            print("failed to load model \(error)")
            return
        }

        if ai.model == nil{
            print( "Model load eror.")
            exit(2)
        }

        ai.model?.sampleParams.mirostat = 2
        ai.model?.sampleParams.mirostat_eta = 0.1
        ai.model?.sampleParams.mirostat_tau = 5.0
    }
}

