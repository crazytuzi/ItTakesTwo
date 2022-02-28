import Vino.Movement.Grinding.UserGrindComponent;

class UUserGrindGrappleComponent : UActorComponent
{
	FGrindSplineData FrameEvaluatedGrappleTarget;

	void ConsumeFrameEvaluation()
	{
		FrameEvaluatedGrappleTarget.Reset();
	}
}
