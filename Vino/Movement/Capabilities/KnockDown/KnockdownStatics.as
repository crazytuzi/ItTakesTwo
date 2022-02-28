UFUNCTION()
void KnockdownActor(AHazeActor Actor, FVector Force, float SlideDuration = 1.0f, float GroundFriction = 0.f)
{
	Actor.SetCapabilityAttributeVector(n"KnockdownDirection", Force);
	Actor.SetCapabilityAttributeValue(n"KnockdownSlideDuration", SlideDuration);
	Actor.SetCapabilityAttributeValue(n"KnockdownGroundFriction", GroundFriction);
	
	Actor.SetCapabilityActionState(n"Knockdown", EHazeActionState::ActiveForOneFrame);
}