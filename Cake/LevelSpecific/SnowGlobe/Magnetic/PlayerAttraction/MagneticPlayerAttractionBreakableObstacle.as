import Cake.Environment.Breakable;

event void FBrokenEvent(UBreakableComponent BreakableCmponent);

class AMagneticPlayerAttractionBreakableObstacle : ABreakableActor
{
	UPROPERTY()
	FBrokenEvent OnBrokenEvent;

	void Break(FVector WorldUp)
	{
		if(BreakableComponent.Broken)
			return;

		FBreakableHitData HitData;
		HitData.HitLocation = ActorCenterLocation;
		HitData.ScatterForce = 2000.f;
		HitData.DirectionalForce = WorldUp * 2000.f;
		
		BreakableComponent.Break(HitData);
		OnBrokenEvent.Broadcast(BreakableComponent);
	}

	void PerchHit()
	{
		if(BreakableComponent.Broken)
			return;

		if(!BreakableComponent.BreakablePresetIsValid)
			return;		

		UHazeAkComponent::HazePostEventFireForget(BreakableComponent.BreakablePreset.HitAudioEvent, GetActorTransform());	
	}		
}