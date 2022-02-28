import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

UCLASS(Abstract)
class AShadowRespawnTunnel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TunnelRoot;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UStaticMeshComponent TunnelMesh;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UStaticMeshComponent PortalMesh;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UBoxComponent TeleportTrigger;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UBoxComponent ReleaseCameraTrigger;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UHazeCameraComponent TunnelCamera;

	AHazePlayerCharacter MainPlayer;

	FRotator CurrentTunnelRot;

	bool bPlayersInTunnel = false;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpacityTimeLike;
	default OpacityTimeLike.Duration = 0.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MainPlayer = Game::GetMay();
		TeleportTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTeleportTrigger");
		ReleaseCameraTrigger.OnComponentBeginOverlap.AddUFunction(this, n"ReleaseCamera");

		OpacityTimeLike.BindUpdate(this, n"UpdateOpacity");
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpacity(float CurValue)
	{
		float CurOpacity = FMath::Lerp(0.f, 1.f, CurValue);
		TunnelMesh.SetScalarParameterValueOnMaterials(n"Opacity", CurOpacity);
		PortalMesh.SetScalarParameterValueOnMaterials(n"Opacity", CurOpacity);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTeleportTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if (!bPlayersInTunnel)
			return;

		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob == nullptr)
			return;

		ParentBlob.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
		ACheckpoint Checkpoint = GetTargetCheckpoint();
		TeleportActor(Checkpoint.ActorLocation + FVector(0.f, 0.f, 7000.f), Checkpoint.ActorRotation);
		ParentBlob.SetCapabilityActionState(n"Respawning", EHazeActionState::Inactive);
		ParentBlob.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		ParentBlob.MoveComp.SetVelocity(ParentBlob.MoveComp.GetPreviousVelocity());
	}

	UFUNCTION(NotBlueprintCallable)
	void ReleaseCamera(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob == nullptr)
			return;

		MainPlayer.DeactivateCamera(TunnelCamera, 0.75f);
		bPlayersInTunnel = false;
		OpacityTimeLike.SetPlayRate(1.f);
		OpacityTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	void ActivateShadowTunnel()
	{
		OpacityTimeLike.SetPlayRate(1.f);
		OpacityTimeLike.PlayFromStart();
		AParentBlob ParentBlob = GetActiveParentBlobActor();
		ParentBlob.SetCapabilityActionState(n"Respawning", EHazeActionState::Active);
		CurrentTunnelRot = FRotator(0.f, MainPlayer.ViewRotation.Yaw, 0.f);
		TeleportActor(ParentBlob.ActorLocation, CurrentTunnelRot);

		MainPlayer.ActivateCamera(TunnelCamera, FHazeCameraBlendSettings(0.75f), this, EHazeCameraPriority::Maximum);

		TunnelRoot.SetRelativeLocation(FVector(0.f, 0.f, -11000.f));
		bPlayersInTunnel = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bPlayersInTunnel)
			return;

		TunnelRoot.AddWorldOffset(FVector(0.f, 0.f, 10500.f * DeltaTime));
		
		FVector CameraLoc = GetActiveParentBlobActor().ActorLocation + FVector(0.f, 0.f, 1400.f);
		TunnelCamera.SetWorldLocation(CameraLoc);
	}

	ACheckpoint GetTargetCheckpoint()
	{
		TArray<ACheckpoint> AllCheckpoints;
		GetAllActorsOfClass(AllCheckpoints);

		float ClosestDistance = MAX_flt;
		ECheckpointPriority Priority = ECheckpointPriority::Lowest;
		ACheckpoint ClosestCheckpoint = nullptr;
		FTransform ClosestPosition;

		FVector PlayerLocation = MainPlayer.ActorLocation;

		for (ACheckpoint Checkpoint : AllCheckpoints)
		{
			if (int(Checkpoint.RespawnPriority) < int(Priority))
				continue;

			if (!Checkpoint.IsEnabledForPlayer(MainPlayer))
				continue;

			if (int(Checkpoint.RespawnPriority) > int(Priority))
			{
				// Higher priority checkpoint, reset the current
				Priority = Checkpoint.RespawnPriority;
				ClosestCheckpoint = nullptr;
				ClosestDistance = MAX_flt;
			}

			FTransform Position = Checkpoint.GetPositionForPlayer(MainPlayer);
			float Distance = Position.GetLocation().DistSquared(PlayerLocation);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestCheckpoint = Checkpoint;
				ClosestPosition = Position;
			}
		}

		if (ClosestCheckpoint != nullptr)
		{
			return ClosestCheckpoint;
		}
		else
		{
			return nullptr;
		}
	}
}