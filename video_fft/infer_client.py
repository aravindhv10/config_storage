#!/usr/bin/env python3
import grpc
# These names are derived directly from "infer.proto"
import infer_pb2
import infer_pb2_grpc

def run_inference(video_path, server_address):
    # Set maximum message size to 100MB
    MAX_MESSAGE_LENGTH = 100 * 1024 * 1024
    options = [
        ('grpc.max_send_message_length', MAX_MESSAGE_LENGTH),
        ('grpc.max_receive_message_length', MAX_MESSAGE_LENGTH),
    ]

    # Use the 'with' statement to ensure the channel closes properly
    with grpc.insecure_channel(server_address, options=options) as channel:
        # The Stub class name is: [ServiceName]Stub
        stub = infer_pb2_grpc.RdvideoinferStub(channel)

        try:
            print(f"Loading {video_path}...")
            with open(video_path, 'rb') as f:
                raw_bytes = f.read()

            # Create the request message
            # The message class name is: infer_pb2.Grpcvideodata
            request = infer_pb2.Grpcvideodata(data=raw_bytes)

            print(f"Sending to {server_address}...")
            # Perform the RPC call
            response = stub.Doinfer(request)

            print("Inference successful. Results:")
            for i, pred in enumerate(response.preds):
                print(f"Prediction {i}: pa={pred.pa:.3f}, pb={pred.pb:.3f}, pc={pred.pc:.3f}")

        except grpc.RpcError as e:
            print(f"gRPC Error: {e.code()} - {e.details()}")
        except FileNotFoundError:
            print(f"Error: File '{video_path}' not found.")

if __name__ == "__main__":
    run_inference("./video.mp4", "10.10.8.17:8001")
