import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

event void FOnFireTunnelRespawned();

UCLASS(Abstract)
class AFireRespawnTunnel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USceneComponent TunnelRoot;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UStaticMeshComponent TunnelMesh;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UStaticMeshComponent TunnelPortalMesh;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UHazeCameraComponent TunnelCamera;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	USceneComponent PlayerAttachPoint;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike CatchPlayerTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ReleasePlayerTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PlayerAnim;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem FireEffect;
	UNiagaraComponent FireComp;

	UPROPERTY()
	ACheckpoint TargetCheckpoint;

	UPROPERTY()
	FOnFireTunnelRespawned OnFireTunnelRespawned;

	bool bPlayersCaught = false;
	bool bCanCatchPlayers = false;
	bool bMoveCamera = false;
	bool bMoving = false;

	float CurrentTimeInTunnel = 0.f;
	float MaxTimeInTunnel = 2.5f;

	float MovementSpeed = 8000.f;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TunnelMesh.SetScalarParameterValueOnMaterials(n"Fireness", 1.f);
		TunnelPortalMesh.SetScalarParameterValueOnMaterials(n"Fireness", 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CatchPlayerTimeLike.BindUpdate(this, n"UpdateCatchPlayer");
		CatchPlayerTimeLike.BindFinished(this, n"FinishCatchPlayer");
	}

	UFUNCTION(DevFunction)
	void ActivateTunnel()
	{
		if (bActive)
			return;

		bActive = true;
		// FireComp = Niagara::SpawnSystemAttached(FireEffect, GetActiveParentBlobActor().RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		MovementSpeed = 8000.f;
		bMoving = true;
		bMoveCamera = true;
		bCanCatchPlayers = true;
		CatchPlayerTimeLike.PlayFromStart();
		FRotator TargetRot = Game::GetMay().ViewRotation;
		FVector CameraLoc = Game::GetMay().ViewLocation;
		FVector TargetLoc = CameraLoc + (TargetRot.ForwardVector * 1000.f);
		TeleportActor(TargetLoc, TargetRot);
		TunnelCamera.SetWorldLocation(CameraLoc);
		Game::GetMay().ActivateCamera(TunnelCamera, FHazeCameraBlendSettings(0.f), this, EHazeCameraPriority::Maximum);
		GetActiveParentBlobActor().BlockCapabilities(CapabilityTags::Movement, this);
		GetActiveParentBlobActor().PlaySlotAnimation(Animation = PlayerAnim, bLoop = true);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateCatchPlayer(float CurValue)
	{
		float CurOpacity = FMath::Lerp(0.f, 1.f, CurValue);
		TunnelMesh.SetScalarParameterValueOnMaterials(n"Opacity", CurOpacity);
		TunnelPortalMesh.SetScalarParameterValueOnMaterials(n"Opacity", CurOpacity);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishCatchPlayer()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// if (bMoving)
		AddActorLocalOffset(FVector(-MovementSpeed * DeltaTime, 0.f, 0.f));

		if (GetActiveParentBlobActor() == nullptr)
			return;

		if (bMoveCamera)
		{
			float NewCameraLoc = TunnelCamera.RelativeLocation.X + (MovementSpeed * DeltaTime);
			NewCameraLoc = FMath::Clamp(NewCameraLoc, -500000.f, 1000.f);
			TunnelCamera.SetRelativeLocation(FVector(NewCameraLoc, TunnelCamera.RelativeLocation.Y, TunnelCamera.RelativeLocation.Z));
		}

		if (bPlayersCaught)
		{
			CurrentTimeInTunnel += DeltaTime;
			if (CurrentTimeInTunnel >= MaxTimeInTunnel)
			{
				ReleasePlayersFromTunnel();
			}
			return;
		}

		if (!bCanCatchPlayers)
			return;

		FVector PlayerDistance = GetActiveParentBlobActor().ActorLocation - PlayerAttachPoint.WorldLocation;
		float DistanceToPlayers = PlayerDistance.Size2D();
		if (DistanceToPlayers < 200.f)
		{
			bPlayersCaught = true;
			bCanCatchPlayers = false;
			GetActiveParentBlobActor().AttachToComponent(PlayerAttachPoint, AttachmentRule = EAttachmentRule::KeepWorld);
			GetActiveParentBlobActor().SmoothSetLocationAndRotation(PlayerAttachPoint.WorldLocation, PlayerAttachPoint.WorldRotation, 1250.f, 12.f);
		}
	}

	UFUNCTION()
	void UpdateTargetCheckpoint(ACheckpoint Checkpoint)
	{
		TargetCheckpoint = Checkpoint;
	}

	void ReleasePlayersFromTunnel()
	{
		// FireComp.Deactivate();
		bActive = false;
		bMoving = false;
		MovementSpeed = 4000.f;
		OnFireTunnelRespawned.Broadcast();
		bMoveCamera = false;
		bPlayersCaught = false;
		CurrentTimeInTunnel = 0.f;
		TeleportActor(TargetCheckpoint.ActorLocation, FRotator(-90.f, -90.f, 0.f));
		GetActiveParentBlobActor().DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		GetActiveParentBlobActor().UnblockCapabilities(CapabilityTags::Movement, this);
		GetActiveParentBlobActor().StopAllSlotAnimations();
		Game::GetMay().SnapCameraBehindPlayer(FRotator(89.f, 0.f, 0.f));
		Game::GetMay().DeactivateCamera(TunnelCamera, 0.5f);
	}
}