import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Actors.Volumes.CamVolumeConditions.CameraVolumeWalljumpCondition;

UCLASS(hideCategories="CameraVolume PointOfInterest BrushSettings HLOD Mobile Physics Collision Replication LOD Input Actor Rendering Cooking")
class AWallJumpCameraVolume : AHazeCameraVolume
{
	default CameraSettings.AdvancedConditionClass = UCameraVolumeWalljumpCondition::StaticClass();
	default BrushComponent.RelativeScale3D = FVector(3,3,4);

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;

	UPROPERTY(DefaultComponent, Attach = ArrowComponent)
	UHazeCameraRootComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraKeepInViewComponent KeepInViewComponent;

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
	}

	UFUNCTION()
	private void VolumeActivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		CameraRoot.ActivateCamera(Player, CameraSettings.Blend, this, CameraSettings.Priority);
	}

	UFUNCTION()
	private void VolumeDeactivated(UHazeCameraUserComponent User)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		Player.DeactivateCameraByInstigator(this, CameraSettings.BlendOutTimeOverride);
	}
}