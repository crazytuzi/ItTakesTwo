import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

event void FFearBatEvent(AFearBat FearBat);

UCLASS(Abstract)
class AFearBat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase ShadowMesh;

	UPROPERTY()
	ACheckpoint TargetCheckpoint;

	UPROPERTY()
	FFearBatEvent OnFearBatSpawned;

	UPROPERTY()
	FFearBatEvent OnFearBatDestroyed;

	UPROPERTY()
	FFearBatEvent OnPlayersDroppedOff;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DestroyEffect;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ParentBlobGrabAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ParentBlobFlyAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ParentBlobDropAnim;

	UPROPERTY()
	EFearBatState CurrentState;

	float HomingSpeed = 2500.f;

	bool bHoming = false;
	bool bHoldingPlayers = false;
	bool bDeparting = false;
	bool bPlayersDropped = false;
	FVector DropLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (GetActiveParentBlobActor() == nullptr)
			return;

		if (bHoming)
		{
			FVector DirToPlayers = (GetActiveParentBlobActor().ActorLocation + FVector(0.f, 0.f, 250.f)) - ActorLocation;
			DirToPlayers.Normalize();

			float HorizontalDistanceToPlayers = GetHorizontalDistanceTo(GetActiveParentBlobActor());
			if (HorizontalDistanceToPlayers < 3000.f && CurrentState != EFearBatState::Target)
				CurrentState = EFearBatState::Target;

			if (HorizontalDistanceToPlayers <= 250.f)
				GrabPlayers();

			FRotator Rot = FMath::RInterpTo(ActorRotation, DirToPlayers.Rotation(), DeltaTime, 5.f);

			SetActorRotation(Rot);
			AddActorWorldOffset(DirToPlayers * HomingSpeed * DeltaTime);

			TArray<AActor> DownActorsToIgnore;
			FHitResult DownHit;
			System::LineTraceSingle(ActorLocation, ActorLocation - FVector::UpVector * 10000.f, ETraceTypeQuery::Visibility, false, DownActorsToIgnore, EDrawDebugTrace::None, DownHit, true);
			if (DownHit.bBlockingHit)
			{
				float VerticalLoc = FMath::FInterpTo(ActorLocation.Z, DownHit.Location.Z + 161.4f, DeltaTime, 0.5f);
				FVector Loc = ActorLocation;
				Loc.Z = VerticalLoc;
				SetActorLocation(Loc);
			}

			FVector TraceStartLoc = ActorLocation + FVector(100.f, 0.f, 20.f);
			TArray<AActor> ActorsToIgnore;
			ActorsToIgnore.Add(GetActiveParentBlobActor());
			ActorsToIgnore.Add(Game::GetMay());
			ActorsToIgnore.Add(Game::GetCody());
			FHitResult Hit;
			System::SphereTraceSingle(TraceStartLoc, TraceStartLoc + FVector(0.f, 0.f, 0.1f), 100.f, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
			if (Hit.bBlockingHit)
			{
				DestroyFearBat();
			}
		}
		else if (bHoldingPlayers)
		{
			FVector DirToDropPoint = DropLocation - ActorLocation;
			DirToDropPoint.Normalize();

			FRotator Rot = FMath::RInterpTo(ActorRotation, DirToDropPoint.Rotation(), DeltaTime, 5.f);

			SetActorRotation(Rot);
			AddActorWorldOffset(DirToDropPoint * 2000.f * DeltaTime);

			FVector Dif = DropLocation - ActorLocation;
			if (Dif.IsNearlyZero(50.f))
				DropPlayers();
		}
		else if (bDeparting)
		{
			if (bPlayersDropped)
				AddActorWorldOffset(ActorForwardVector * 1500.f * DeltaTime);
		}
	}
	UFUNCTION()
	void DestroyFearBat()
	{
		CurrentState = EFearBatState::Crashing;
		bHoming = false;
		bDeparting = false;
		bHoldingPlayers = false;
		Niagara::SpawnSystemAtLocation(DestroyEffect, ActorLocation);
		OnFearBatDestroyed.Broadcast(this);

		System::SetTimer(this, n"HideBat", 1.5f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void HideBat()
	{
		SetActorHiddenInGame(true);
		CurrentState = EFearBatState::Flying;
	}

	UFUNCTION()
	void SpawnFearBat(FVector Loc)
	{
		CurrentState = EFearBatState::Flying;
		SetActorHiddenInGame(false);

		TeleportActor(Loc, FRotator::ZeroRotator);

		StartFollowingPlayers();
		
		OnFearBatSpawned.Broadcast(this);
	}

	UFUNCTION()
	void StartFollowingPlayers()
	{
		CurrentState = EFearBatState::Flying;
		bHoming = true;
	}

	UFUNCTION()
	void GrabPlayers()
	{
		AParentBlob ParentBlob = GetActiveParentBlobActor();
		if (ParentBlob == nullptr)
			return;

		if (!bHoming)
			return;

		CurrentState = EFearBatState::GrabPlayers;
		bHoming = false;
		bHoldingPlayers = true;

		ParentBlob.BlockCapabilities(CapabilityTags::Movement, this);
		ParentBlob.AttachToComponent(ShadowMesh, n"Align", EAttachmentRule::KeepWorld);

		FHazeAnimationDelegate AnimFinishedDelegate;
		AnimFinishedDelegate.BindUFunction(this, n"PlayGrabMh");
		GetActiveParentBlobActor().PlaySlotAnimation(OnBlendingOut = AnimFinishedDelegate, Animation = ParentBlobGrabAnim);

		FVector AlignLocation = ShadowMesh.GetSocketLocation(n"Align");
		FRotator AlignRotation = ShadowMesh.GetSocketRotation(n"Align");
		ParentBlob.SmoothSetLocationAndRotation(AlignLocation, AlignRotation);
		
		DropLocation = TargetCheckpoint.ActorLocation + FVector(0.f, 0.f, 750.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayGrabMh()
	{
		GetActiveParentBlobActor().PlaySlotAnimation(Animation = ParentBlobFlyAnim, bLoop = true);
	}

	void DropPlayers()
	{
		bPlayersDropped = false;
		CurrentState = EFearBatState::DropPlayers;
		bHoldingPlayers = false;
		bDeparting = true;
		bPlayersDropped = true;

		GetActiveParentBlobActor().PlaySlotAnimation(Animation = ParentBlobDropAnim);
		OnPlayersDroppedOff.Broadcast(this);

		System::SetTimer(this, n"PlayersFullyDropped", 0.4f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersFullyDropped()
	{
		bPlayersDropped = true;
		GetActiveParentBlobActor().DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		GetActiveParentBlobActor().UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void Respawn()
	{
		bDeparting = false;
	}
}

enum EFearBatState
{
	Flying,
	Target,
	Crashing,
	GrabPlayers,
	GrabPlayersFly,
	DropPlayers
}