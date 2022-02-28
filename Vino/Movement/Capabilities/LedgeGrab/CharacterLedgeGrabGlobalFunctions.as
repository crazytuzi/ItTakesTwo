import Vino.Movement.Components.GrabbedCallbackComponent;

void CallLeaveLedgeGrabEvent(AHazePlayerCharacter LeavingPlayer, UPrimitiveComponent PrimitiveComp, ELedgeReleaseType ReleaseType)
{
	if (PrimitiveComp == nullptr)
		return;

	if (!PrimitiveComp.IsNetworked())
		return;

	AHazeActor HazeActor = Cast<AHazeActor>(PrimitiveComp.Owner);
	if (HazeActor == nullptr)
		return;

	UGrabbedCallbackComponent CallbackComp = UGrabbedCallbackComponent::Get(HazeActor);
	if (CallbackComp == nullptr)
		return;

	CallbackComp.LetGoOfActor(LeavingPlayer, PrimitiveComp, ReleaseType);
}
