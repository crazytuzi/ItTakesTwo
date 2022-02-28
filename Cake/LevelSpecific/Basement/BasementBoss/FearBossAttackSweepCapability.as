import Cake.LevelSpecific.Basement.BasementBoss.BasementBoss;
import Cake.LevelSpecific.Basement.BasementBoss.FearBossAttackCapabilityBase;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.RespawnBubble.BasementRespawnBubble;
import Cake.LevelSpecific.Basement.BasementBoss.ShadowWallShelter;
import Cake.LevelSpecific.Basement.ParentBlob.Health.ParentBlobHealthComponent;

class UFearBossAttackSweepCapability : UFearBossAttackCapabilityBase
{
	default RequiredPhase = EBasementBossPhase::Sweep;

	bool bLeft = false;
	bool bParentBlobProtected = false;

	default AttackDuration = 6.5f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		Boss.bLeftSweep = !Boss.bLeftSweep;
		bLeft = Boss.bLeftSweep;
		bParentBlobProtected = false;

		System::SetTimer(this, n"ApplyPoI", 2.f, false);

		// Boss.TriggerAttack();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION()
	void ApplyPoI()
	{
		if (!IsActive())
			return;

		FHazePointOfInterest PoI;
		PoI.FocusTarget.Actor = Owner;
		PoI.FocusTarget.WorldOffset = FVector(0.f, -10000.f, -1500.f);
		PoI.FocusTarget.Socket = bLeft ? n"RightHand" : n"Lefthand";
		PoI.Duration = 3.5f;
		PoI.Blend.BlendTime = 3.f;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.ApplyPointOfInterest(PoI, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FName Socket = bLeft ? n"RightHand" : n"Lefthand";
		FTransform TraceTransform = Boss.BossMesh.GetSocketTransform(Socket);
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
		FHitResult Hit;
		// System::BoxTraceSingleForObjects(TraceTransform.Location, TraceTransform.Location + FVector::OneVector, FVector(500.f, 2000.f, 5000.f), TraceTransform.Rotator(), ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::ForOneFrame, Hit, true);

		TArray<FHitResult> Hits;
		System::BoxTraceMulti(TraceTransform.Location, TraceTransform.Location + FVector::OneVector, FVector(500.f, 2000.f, 8000.f), TraceTransform.Rotator(), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, true);

		bool bParentBlobHit = false;
		for (FHitResult CurHit : Hits)
		{
			AParentBlob ParentBlob = Cast<AParentBlob>(CurHit.Actor);
			if (ParentBlob != nullptr)
			{
				bParentBlobHit = true;
				if (ParentBlob.IsAnyCapabilityActive(ULightBubbleCapability::StaticClass()))
				{
					bParentBlobProtected = true;
				}
			}

			AShadowWallShelter Shelter = Cast<AShadowWallShelter>(CurHit.Actor);
			if (Shelter != nullptr && Shelter.bSafeZoneActive)
			{
				if (Shelter.bPlayersInShelter)
					bParentBlobProtected = true;

				Shelter.ShelterHitByAttack();
			}
		}

		if (bParentBlobHit)
		{
			if (!bParentBlobProtected)
			{
				TArray<ABasementRespawnBubble> RespawnBubbles;
				GetAllActorsOfClass(RespawnBubbles);
				KillAndRespawnParentBlob();
				Boss.OnSweepAttackHit.Broadcast();
			}
			else
			{
				
			}
		}
	}
}