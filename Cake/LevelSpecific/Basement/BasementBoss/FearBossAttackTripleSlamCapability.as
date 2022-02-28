import Cake.LevelSpecific.Basement.BasementBoss.BasementBoss;
import Cake.LevelSpecific.Basement.BasementBoss.FearBossAttackCapabilityBase;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.RespawnBubble.BasementRespawnBubble;

class UFearBossAttackTripleSlamCapability : UFearBossAttackCapabilityBase
{
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FTransform TraceTransform = Boss.BossMesh.GetSocketTransform(n"LeftHand");
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
		FHitResult Hit;
		System::BoxTraceSingleForObjects(TraceTransform.Location, TraceTransform.Location + FVector::OneVector, FVector(1000.f, 2000.f, 5000.f), TraceTransform.Rotator(), ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		if (Hit.bBlockingHit)
		{
			AParentBlob ParentBlob = Cast<AParentBlob>(Hit.Actor);
			if (ParentBlob != nullptr)
			{
				TArray<ABasementRespawnBubble> RespawnBubbles;
				GetAllActorsOfClass(RespawnBubbles);
				RespawnBubbles[0].Activate();
			}
		}
	}
}