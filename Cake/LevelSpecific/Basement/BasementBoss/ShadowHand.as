import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.RespawnBubble.BasementRespawnBubble;

event void FShadowHandEvent(AShadowHand Hand);

UCLASS(Abstract)
class AShadowHand : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	UHazeSkeletalMeshComponentBase HandMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent WarningEffectComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent BreachEffectComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> BreachCamShake;

	UPROPERTY()
	FShadowHandEvent OnShadowHandDespawned;

	UPROPERTY()
	FShadowHandEvent OnShadowHandGrabbedPlayers;

	float TimeUntilSpawn = 2.5f;
	float TimeUntilDespawn = 1.f;

	FVector SpawnLocation;

	bool bSpawning = false;

	bool bHoldingPlayers = false;

	FTimerHandle SpawnTimerHandle;

	FTransform SpawnGroundTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(NotBlueprintCallable)
	void FinishSpawnHand()
	{
		if (!bSpawning)
			OnShadowHandDespawned.Broadcast(this);
	}

	UFUNCTION()
	void PrepareShadowHand(bool bOffsetLocation = true)
	{
		FVector DecalLoc;
		FVector GroundNormal;
		if (bOffsetLocation)
		{
			float PlayerMoveSpeed = GetActiveParentBlobActor().ActorVelocity.Size();
			float ForwardOffsetSpeedModifier = FMath::Lerp(0.f, 1.f, PlayerMoveSpeed/400.f);
			float ForwardOffset = FMath::RandRange(150.f, 1000.f) * ForwardOffsetSpeedModifier;
			float SideOffset = FMath::RandRange(-175.f, 175.f);
			FVector2D Offset = FVector2D(ForwardOffset, SideOffset);

			FVector PlayerLoc = GetPlayerGroundLocation(Offset, GroundNormal);

			DecalLoc = PlayerLoc;

			SpawnLocation = DecalLoc;
		}
		else
		{
			SpawnLocation = ActorLocation;
			DecalLoc = ActorLocation + FVector(0.f, 0.f, 3200.f);
			GroundNormal = FVector::UpVector;
		}
		
		SetActorLocation(SpawnLocation);

		SpawnGroundTransform.Location = DecalLoc;
		SpawnGroundTransform.Rotation = FQuat(Math::MakeRotFromZ(GroundNormal));
		BreachEffectComp.SetWorldLocation(SpawnGroundTransform.Location);
		BreachEffectComp.SetWorldRotation(SpawnGroundTransform.Rotator());

		WarningEffectComp.SetWorldLocation(DecalLoc);
		WarningEffectComp.SetWorldRotation(SpawnGroundTransform.Rotator());
		WarningEffectComp.Activate(true);

		SpawnTimerHandle = System::SetTimer(this, n"SpawnShadowHand", TimeUntilSpawn, false);
	}

	UFUNCTION()
	void SpawnShadowHand()
	{
		TArray<AShadowHand> AllShadowHands;
		GetAllActorsOfClass(AllShadowHands);

		WarningEffectComp.Deactivate();
		BreachEffectComp.Activate(true);
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(BreachCamShake, 0.35f);
		}

		for (AShadowHand CurShadowHand : AllShadowHands)
		{
			if (CurShadowHand.bHoldingPlayers && GetHorizontalDistanceTo(CurShadowHand) < 700.f)
			{
				OnShadowHandDespawned.Broadcast(this);
				return;
			}
		}

		bSpawning = true;

		FVector HandDir = Game::GetMay().ViewRotation.Vector();
		HandDir = Math::ConstrainVectorToPlane(HandDir, FVector::UpVector);
		HandDir *= -1;
		FRotator HandRot = HandDir.Rotation();
		SetActorRotation(HandRot);

		HandMesh.SetAnimBoolParam(n"Attack", true);

		float DistanceToPlayers = GetHorizontalDistanceTo(GetActiveParentBlobActor());
		
		if (DistanceToPlayers < 400.f && !GetActiveParentBlobActor().IsAnyCapabilityActive(n"ShadowHandGrab")  && !GetActiveParentBlobActor().IsAnyCapabilityActive(n"BeingOfLight"))
		{
			OnShadowHandGrabbedPlayers.Broadcast(this);
		}
		else
		{

		}

		System::SetTimer(this, n"DespawnShadowHand", TimeUntilDespawn, false);
	}

	UFUNCTION()
	void DespawnShadowHand()
	{
		bSpawning = false;
		OnShadowHandDespawned.Broadcast(this);
	}

	FVector GetPlayerGroundLocation(FVector2D Offset, FVector& Normal)
	{
		AParentBlob ParentBlob = GetActiveParentBlobActor();
		FVector TraceStartLoc = ParentBlob.ActorLocation + (ParentBlob.ActorForwardVector * Offset.X) + (ParentBlob.ActorRightVector * Offset.Y) + FVector(0.f, 0.f, 1000.f);
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(GetActiveParentBlobActor());
		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());
		FHitResult DownHit;
		System::LineTraceSingle(TraceStartLoc, TraceStartLoc - FVector(0.f, 0.f, 4000.f), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, DownHit, true, DrawTime = 100.f);
		bool bValidGroundHit = DownHit.bBlockingHit;
		if (bValidGroundHit)
		{
			Normal = DownHit.ImpactNormal;
			return DownHit.Location;
		}
		else
		{
			Normal = FVector::UpVector;
			return ParentBlob.ActorLocation;
		}

	}
}