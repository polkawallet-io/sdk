import { SubmittableExtrinsic } from "@polkadot/api/types";
import { SignerPayloadJSON } from "@polkadot/types/types";

export type QRSigner = {
  completedFramesCount: number;
  multipartData: any[];
  multipartComplete: boolean;
  totalFrameCount: number;
  latestFrame: number;
  missedFrames: any[];
  unsignedData: any;
};

export type QRSubmittable = {
  tx: SubmittableExtrinsic<"promise">;
  payload: SignerPayloadJSON;
};
