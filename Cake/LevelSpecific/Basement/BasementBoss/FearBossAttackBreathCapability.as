import Cake.LevelSpecific.Basement.BasementBoss.BasementBoss;
import Cake.LevelSpecific.Basement.BasementBoss.FearBossAttackCapabilityBase;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.ParentBlob.Health.ParentBlobHealthComponent;

class UFearBossAttackBreathCapability : UFearBossAttackCapabilityBase
{
	UPROPERTY()
	UNiagaraSystem BreathSystem;

	bool bBreathing = false;

	UNiagaraComponent BreathSystemComp;

	default AttackDuration = 8.f;

	default RequiredPhase = EBasementBossPhase::Breath;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		// BreathSystemComp.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		bBreathing = false;
		System::SetTimer(this, n"StartBreathing", 2.f, false);
		System::SetTimer(this, n"StopBreathing", 9.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void StartBreathing()
	{
		if (IsActive())
		{
			bBreathing = true;
			BreathSystemComp = Niagara::SpawnSystemAtLocation(BreathSystem, Owner.ActorLocation);
			BreathSystemComp.Activate(true);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StopBreathing()
	{
		bBreathing = false;
		BreathSystemComp.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bBreathing = false;
		Super::OnDeactivated(DeactivationParams);
		BreathSystemComp.Deactivate();

		GetActiveParentBlobActor().SetCapabilityActionState(n"Breath", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (!bBreathing)
		{
			GetActiveParentBlobActor().SetCapabilityActionState(n"Breath", EHazeActionState::Inactive);
			return;
		}

		FTransform HeadTransform = Boss.BossMesh.GetSocketTransform(n"Head");
		FVector ForwardDirection = HeadTransform.Rotation.ForwardVector;
		ForwardDirection = Math::ConstrainVectorToPlane(ForwardDirection, FVector::UpVector);
		FVector TraceStart = HeadTransform.Location + (ForwardDirection * 12000.f) - FVector(0.f, 0.f, 2500.f);
		TArray<FHitResult> Hits;
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
			System::BoxTraceMultiForObjects(TraceStart, TraceStart + FVector(0.f, 0.f, 1.f), FVector(12500.f, 2000.f, 4000.f), ForwardDirection.Rotation(), ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, true);

		if (BreathSystemComp != nullptr)
		{
			FVector BreathMeshLoc = HeadTransform.Location - FVector(0.f, 0.f, 3000.f);
			BreathMeshLoc += ForwardDirection * 3000.f;
			BreathSystemComp.SetWorldLocation(BreathMeshLoc);
			BreathSystemComp.SetWorldRotation(FQuat(ForwardDirection.Rotation() - FRotator(3.f, 0.f, 0.f)));
		}

		bool bPlayersInRange = false;
		for (FHitResult CurHit : Hits)
		{
			if (CurHit.Actor != nullptr && CurHit.Actor == GetActiveParentBlobActor())
			{
				bPlayersInRange = true;
				break;
			}
		}

		if (!bPlayersInRange)
		{
			GetActiveParentBlobActor().SetCapabilityActionState(n"Breath", EHazeActionState::Inactive);
			return;
		}

		FHitResult Hit;
		System::LineTraceSingle(HeadTransform.Location, GetActiveParentBlobActor().ActorLocation + FVector(0.f, 0.f, 100.f), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);
		if (Hit.Actor != nullptr && Hit.Actor == GetActiveParentBlobActor())
			KillAndRespawnParentBlob();
	}
}