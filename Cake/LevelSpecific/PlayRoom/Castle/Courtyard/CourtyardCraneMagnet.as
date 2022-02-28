import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneAttachedActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneWreckingBall;

event void FOnOverlapWreckingBall();
event void FOnAttachWreckingBall(ACourtyardCraneWreckingBall Actor);

class ACourtyardCraneMagnet : ACourtyardCraneAttachedActor
{
	default SphereTrigger.SetSphereRadius(72);

	FOnOverlapWreckingBall OnOverlapWreckingBall;
	FOnAttachWreckingBall OnAttachWreckingBall;

	ACourtyardCraneWreckingBall BallActor;
}