import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Actors.Volumes.CamVolumeConditions.CameraVolumeWalljumpCondition;

UCLASS(hideCategories="CameraVolume PointOfInterest BrushSettings HLOD Mobile Physics Collision Replication LOD Input Actor Rendering Cooking")
class AWallJumpVolume : AHazeCameraVolume
{
	default CameraSettings.AdvancedConditionClass = UCameraVolumeWalljumpCondition::StaticClass();
	default BrushComponent.RelativeScale3D = FVector(3,3,4);

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;

	UPROPERTY(DefaultComponent, Attach = ArrowComponent)
	UHazeCameraRootComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraKeepInViewComponent KeepInViewComponent;
	default KeepInViewComponent.AxisFreedomFactor = FVector(1.f, 0.f, 1.f);
	default KeepInViewComponent.MinDistance = 1250.f;
	default KeepInViewComponent.AccelerationDuration = 1.25f;

	UPROPERTY(DefaultComponent, Attach = KeepInViewComponent)
	UHazeCameraComponent CameraComp;
	default CameraComp.BlendOutBehaviour = EHazeCameraBlendoutBehaviour::FollowView; // This will make blend out behave nicer with default camera.

    UPROPERTY(Meta = (MakeEditWidget))
	FTransform CameraDirection;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CameraDirection.Location = FVector::ZeroVector;
		ArrowComponent.RelativeRotation = CameraDirection.Rotator();
		CameraSettings.Camera = nullptr;
		ArrowComponent.SetWorldScale3D(FVector::OneVector);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnVolumeActivated.AddUFunction(this, n"VolumeActivated");
		OnVolumeDeactivated.AddUFunction(this, n"VolumeDeactivated");
		OnEntered.AddUFunction(this, n"OnEnteredVolume");
		OnExited.AddUFunction(this, n"OnExitedVolume");
	}

	UFUNCTION()
	private void VolumeActivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		CameraRoot.ActivateCamera(Player, CameraSettings.Blend, this, CameraSettings.Priority);

		// Align controlled camera with wall camera during blend in
		FHazePointOfInterest POI;
		POI.FocusTarget.Component = CameraComp;
		POI.bMatchFocusDirection = true;
		POI.Blend = CameraSettings.Blend;
		POI.Duration = CameraSettings.Blend.BlendTime;
		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION()
	private void VolumeDeactivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		Player.DeactivateCameraByInstigator(this, CameraSettings.BlendOutTimeOverride);
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION()
	void OnEnteredVolume(UHazeCameraUserComponent User)
	{
		UCharacterWallSlideComponent WallSlideComp = UCharacterWallSlideComponent::GetOrCreate(User.Owner);

		if (WallSlideComp != nullptr)
			WallSlideComp.EnteredWallJumpVolume(this);
	}

	UFUNCTION()
	void OnExitedVolume(UHazeCameraUserComponent User)
	{
		UCharacterWallSlideComponent WallSlideComp = UCharacterWallSlideComponent::GetOrCreate(User.Owner);

		if (WallSlideComp != nullptr)
			WallSlideComp.LeftWallJumpVolume(this);
	}
}