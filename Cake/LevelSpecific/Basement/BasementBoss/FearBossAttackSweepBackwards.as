import Cake.LevelSpecific.Basement.BasementBoss.BasementBoss;
import Cake.LevelSpecific.Basement.BasementBoss.FearBossAttackCapabilityBase;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.RespawnBubble.BasementRespawnBubble;

class UFearBossAttackSweepBackwardsCapability : UFearBossAttackCapabilityBase
{
	default RequiredPhase = EBasementBossPhase::Sweep;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		System::SetTimer(this, n"ApplyPoI", 0.75f, false);
	}

	UFUNCTION()
	void ApplyPoI()
	{
		if (!IsActive())
			return;

		FHazePointOfInterest PoI;
		PoI.FocusTarget.Actor = Owner;
		PoI.FocusTarget.WorldOffset = FVector(0.f, -3000.f, -1500.f);
		PoI.FocusTarget.Socket = n"RightHand";
		PoI.Duration = 3.f;
		PoI.Blend.BlendTime = 2.f;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.ApplyPointOfInterest(PoI, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (ActiveDuration >= 5.f)
			return;

		FTransform TraceTransform = Boss.BossMesh.GetSocketTransform(n"RightHand");
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
		FHitResult Hit;
		System::BoxTraceSingleForObjects(TraceTransform.Location, TraceTransform.Location + FVector::OneVector, FVector(500.f, 2000.f, 5000.f), TraceTransform.Rotator(), ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		if (Hit.bBlockingHit)
		{
			AParentBlob ParentBlob = Cast<AParentBlob>(Hit.Actor);
			if (ParentBlob != nullptr)
			{
				if (ParentBlob.IsAnyCapabilityActive(ULightBubbleCapability::StaticClass()))
					return;

				TArray<ABasementRespawnBubble> RespawnBubbles;
				GetAllActorsOfClass(RespawnBubbles);
				if (!RespawnBubbles[0].bActive)
				{
					RespawnBubbles[0].Activate();
					Boss.OnSweepAttackHit.Broadcast();
				}
			}
		}
	}
}