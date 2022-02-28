import Peanuts.Spline.SplineComponent;
import Vino.Interactions.TriggerInteraction;
import Vino.Camera.Actors.FocusTrackerCamera;

event void FOnCometReachedEnd(AComet Comet);

class AComet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CometMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerAttachmentPoint;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyAnim;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShakeClass;

	UPROPERTY()
	FOnCometReachedEnd OnReachedEnd;

	UPROPERTY()
	AHazeActor TargetSpline;
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	bool bResetAfterReachingEnd = true;

	UPROPERTY()
	bool bActive = false;

	float DistanceAlongSpline = 0.f;
	float MovementSpeed = 30000.f;

	AHazePlayerCharacter MountedPlayer;
	AFocusTrackerCamera Camera;

	bool bCameraStopped = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetSpline != nullptr)
		{
			SplineComp = UHazeSplineComponent::Get(TargetSpline);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void InteractionActivated(AHazePlayerCharacter Player, ATriggerInteraction Interaction)
	{
		FHazeJumpToData Data;
		Data.AdditionalHeight = 1000.f;
		Data.TargetComponent = PlayerAttachmentPoint;
		FHazeDestinationEvents Events;
		Events.OnDestinationReached.BindUFunction(this, n"Reached");
		JumpTo::ActivateJumpTo(Player, Data, Events);
	}

	UFUNCTION(NotBlueprintCallable)
	void Reached(AHazeActor Actor)
	{
		Actor.AttachToComponent(PlayerAttachmentPoint);
	}

	UFUNCTION()
	void AttachPlayer(AHazePlayerCharacter Player)
	{
		MountedPlayer = Player;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToComponent(PlayerAttachmentPoint);
		Player.ApplyCameraSettings(CamSettings, FHazeCameraBlendSettings(0.f), this);

		UAnimSequence Anim = Player.IsMay() ? MayAnim : CodyAnim;
		Player.PlaySlotAnimation(Animation = Anim, bLoop = true);
		Player.PlayCameraShake(CamShakeClass);
	}

	UFUNCTION()
	void Activate()
	{
		if (IsActorDisabled(this))
			EnableActor(this);

		DistanceAlongSpline = 0.f;
		bCameraStopped = false;
		bActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (SplineComp == nullptr)
			return;

		if (!bActive)
			return;

		FTransform CurTransform = SplineComp.GetTransformAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		SetActorTransform(CurTransform);

		if (DistanceAlongSpline >= SplineComp.SplineLength/2 && !bCameraStopped)
		{
			bCameraStopped = true;
			Camera = AFocusTrackerCamera::Spawn(MountedPlayer.ViewLocation, MountedPlayer.ViewRotation);
			Camera.ActivateCamera(MountedPlayer, FHazeCameraBlendSettings(0.f), this);
			System::SetTimer(this, n"KillMountedPlayer", 1.f, false);
		}

		DistanceAlongSpline += MovementSpeed * DeltaTime;
		if (DistanceAlongSpline >= SplineComp.SplineLength)
		{
			OnReachedEnd.Broadcast(this);
			if (bResetAfterReachingEnd)
				DistanceAlongSpline = 0.f;
			else
				DisableActor(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void KillMountedPlayer()
	{
		MountedPlayer.KillPlayer();
		MountedPlayer.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MountedPlayer.ClearCameraSettingsByInstigator(this);
		MountedPlayer.StopAnimation();
		MountedPlayer.StopAllCameraShakes();
		MountedPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		System::SetTimer(this, n"DeactivateFocusCamera", 1.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void DeactivateFocusCamera()
	{
		MountedPlayer.DeactivateCamera(Camera.Camera, 0.f);
		MountedPlayer = nullptr;
	}
}