import Vino.Movement.Grinding.GrindSpline;
import Vino.Movement.Grinding.UserGrindComponent;

UFUNCTION()
void ForceGrappleToDistanceAlongGrindSpline(AHazePlayerCharacter Player, AGrindspline GrindSpline, float DistanceAlongSpline)
{
	UUserGrindComponent GrindComp = UUserGrindComponent::Get(Player);
	if (GrindComp.HasTargetGrindSpline())
		return;
	if (GrindComp.HasActiveGrindSpline())
		return;
		
	Player.SetCapabilityAttributeValue(n"GrindForceGrappleDistance", DistanceAlongSpline);
	Player.SetCapabilityAttributeObject(n"GrindForceGrappleGrindSpline", GrindSpline);
	Player.SetCapabilityActionState(n"GrindForceActivate", EHazeActionState::Active);
	Player.SetCapabilityActionState(GrindingActivationEvents::GrappledForced, EHazeActionState::ActiveForOneFrame);
}
