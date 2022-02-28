import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;

// Handle player-positioning in swing after physics have ticked
class UTrapezeSwingPostPhysicsCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::PostPhysicsSwing);

    default TickGroup = ECapabilityTickGroups::AfterPhysics;

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	UTrapezeComponent TrapezeComponent;
	ATrapezeActor TrapezeActor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(Owner);
		TrapezeActor = Cast<ATrapezeActor>(TrapezeComponent.GetTrapezeActor());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return TrapezeComponent.IsSwinging() ?
			EHazeNetworkActivation::ActivateLocal :
			EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Glue player character to trapeze (using attach messes up the collision shape)
		PlayerOwner.SetActorLocation(TrapezeActor.SwingMesh.GetWorldLocation());
		PlayerOwner.MeshOffsetComponent.OffsetRotationWithTime(TrapezeActor.PlayerPositionInSwing.GetWorldRotation());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return TrapezeComponent.IsSwinging() ?
			EHazeNetworkDeactivation::DontDeactivate :
			EHazeNetworkDeactivation::DeactivateLocal;
	}
}