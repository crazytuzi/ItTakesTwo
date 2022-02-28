import Peanuts.Visualization.DummyVisualizationComponent;
import Vino.Camera.Actors.Volumes.FollowRotationCameraComponent;

UCLASS(hideCategories="CameraVolume PointOfInterest BrushSettings HLOD Mobile Physics Collision Replication LOD Input Actor Rendering Cooking")
class AFollowRotationCameraVolume : AHazeCameraVolume
{
	UPROPERTY()
	AActor ActorToFollow;

	UPROPERTY()
	FName ComponentName = NAME_None;

	UPROPERTY(DefaultComponent, NotVisible, BlueprintHidden)
	UDummyVisualizationComponent DummyVisualizationComp;
	default DummyVisualizationComp.Color = FLinearColor::Yellow;
	default DummyVisualizationComp.DashSize = 20.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (ActorToFollow != nullptr)
			DummyVisualizationComp.ConnectedActors.Add(ActorToFollow);
		else
			DummyVisualizationComp.ConnectedActors.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnVolumeActivated.AddUFunction(this, n"VolumeActivated");
		OnVolumeDeactivated.AddUFunction(this, n"VolumeDeactivated");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		OnVolumeActivated.Unbind(this, n"VolumeActivated");
		OnVolumeDeactivated.Unbind(this, n"VolumeDeactivated");
	}

	UFUNCTION()
	private void VolumeActivated(UHazeCameraUserComponent User)
	{
		if (ActorToFollow == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		if (Player == nullptr)
			return;
		if (!Player.HasControl())
			return;

		NetStartFollowRotation(Player);
	}

	UFUNCTION(NetFunction)
	void NetStartFollowRotation(AHazePlayerCharacter Player)
	{
		UFollowRotationCameraComponent FollowRotationCameraComponent = UFollowRotationCameraComponent::GetOrCreate(Player);

		// Note that if script sets ActorToFollow or ComponentName this might differ in network
		// This is fine since any capability handling rotation should only run on control side 
		// and replicate desired rotation.
		USceneComponent ComponentToFollow = ActorToFollow.RootComponent; 
		if (ComponentName != NAME_None)
		{
			ComponentToFollow = USceneComponent::Get(ActorToFollow, ComponentName);
			
			if (!ensure(ComponentToFollow != nullptr))
				ComponentToFollow = ActorToFollow.RootComponent;
		}

		FollowRotationCameraComponent.Follow(ComponentToFollow, CameraSettings.Priority, this);

		Capability::AddPlayerCapabilityRequest(n"CameraFollowRotationCapability", Player.IsMay() ? EHazeSelectPlayer::May : EHazeSelectPlayer::Cody);
	}


	UFUNCTION()
	private void VolumeDeactivated(UHazeCameraUserComponent User)
	{
		if (ActorToFollow == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(User.Owner);
		if (Player == nullptr)
			return;
		if (!Player.HasControl())
			return;
		
		NetStopFollowRotation(Player);
	}

	UFUNCTION(NetFunction)
	void NetStopFollowRotation(AHazePlayerCharacter Player)
	{
		UFollowRotationCameraComponent FollowRotationCameraComponent = UFollowRotationCameraComponent::Get(Player);
		if (FollowRotationCameraComponent != nullptr) // Can be null when we e.g. exit a volume which we did not meet conditions to activate
			FollowRotationCameraComponent.UnfollowByInstigator(this);

		Capability::RemovePlayerCapabilityRequest(n"CameraFollowRotationCapability", Player.IsMay() ? EHazeSelectPlayer::May : EHazeSelectPlayer::Cody);
	}
}
