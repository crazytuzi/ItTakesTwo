import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Actors.Volumes.FollowRotationCameraComponent;
import Vino.Camera.Capabilities.CameraTags;

class UCameraFollowRotationCapability : UHazeCapability
{	
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"CameraFollowRotation");

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

    UCameraUserComponent User;
    UFollowRotationCameraComponent FollowRotationCameraComponent; 
	USceneComponent ComponentToFollow;
	
	FRotator PrevLocalRotation;
	FRotator ActorOffset;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        User = UCameraUserComponent::Get(Owner);
		FollowRotationCameraComponent = UFollowRotationCameraComponent::Get(Owner);

        ensure(User != nullptr);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (!HasControl())
            return EHazeNetworkActivation::DontActivate;

		if (FollowRotationCameraComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (FollowRotationCameraComponent.GetComponentToFollow() == nullptr)
			return EHazeNetworkActivation::DontActivate;	

        return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (FollowRotationCameraComponent.GetComponentToFollow() == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;	

        return EHazeNetworkDeactivation::DontDeactivate;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        User.RegisterDesiredRotationReplication(this);
		ComponentToFollow = FollowRotationCameraComponent.GetComponentToFollow();
		ActorOffset = User.WorldToLocalRotation(ComponentToFollow.GetWorldRotation()).Compose(User.WorldToLocalRotation(ComponentToFollow.Owner.ActorRotation).GetInverse()).GetInverse();
        PrevLocalRotation = User.WorldToLocalRotation(ActorOffset.Compose(ComponentToFollow.GetWorldRotation()));
    }
    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        User.UnregisterDesiredRotationReplication(this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		USceneComponent NewComponentToFollow = FollowRotationCameraComponent.GetComponentToFollow();
		
		if (NewComponentToFollow != ComponentToFollow)
		{
			ComponentToFollow = NewComponentToFollow;
			ActorOffset = User.WorldToLocalRotation(ComponentToFollow.GetWorldRotation()).Compose(User.WorldToLocalRotation(ComponentToFollow.Owner.ActorRotation).GetInverse()).GetInverse();
			PrevLocalRotation = User.WorldToLocalRotation(ActorOffset.Compose(ComponentToFollow.GetWorldRotation()));
			return;
		}	

		// Following the same component as last frame
		FRotator CurRot = ActorOffset.Compose(User.WorldToLocalRotation(ComponentToFollow.GetWorldRotation()));
	    FRotator Delta = (CurRot - PrevLocalRotation).GetNormalized();
        User.AddDesiredRotation(Delta);
        PrevLocalRotation = CurRot;
    }
}