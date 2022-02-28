import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Vino.Interactions.TriggerUser.TriggerUserComponent;

class UClockworkPlayerFlyBirdCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"ClockworkBirdMounted");

	default CapabilityDebugCategory = n"ClockworkInputCapability";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UTriggerUserComponent TriggerUser;

	AClockworkBird Bird;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TriggerUser = UTriggerUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
        if (MountedBird == nullptr)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		if (MountedBird == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if(!MountedBird.PlayerIsUsingBird(Player))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		Bird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		OutParams.AddObject(n"Bird", Bird);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird = Cast<AClockworkBird>(ActivationParams.GetObject(n"Bird"));

		Player.TriggerMovementTransition(this);
		Player.BlockMovementSyncronization(this);
		Player.AttachToComponent(Bird.AttachComponent);

		TriggerUser.InstigatorsPreventingActivation.AddUnique(this);

		UClockworkBirdFlyingComponent::GetOrCreate(Player).MountedBird = Bird;
		CreateMeshOutlineBasedOnPlayer(Bird.Mesh, Player);

		Bird.SetCapabilityAttributeObject(n"AudioMountedBird", Player);
		Bird.bPlayerStartedAnimating = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		
		Player.StopAllCameraShakes(true);
		Player.DeactivateCameraByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.UnblockMovementSyncronization(this);	

		TriggerUser.InstigatorsPreventingActivation.Remove(this);

		RemoveMeshOutlineFromMesh(Bird.Mesh);

		Bird.PlayerStoppedUsingBird();
		Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdJumping, EHazeActionState::Inactive);
		Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdLaunch, EHazeActionState::Inactive);	
		Bird.bPlayerStartedAnimating = false;

		if (DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
			Player.AddImpulse(Bird.ActorRotation.RotateVector(FVector(0.f, 500.f, 2000.f)));

		UClockworkBirdFlyingComponent::GetOrCreate(Player).MountedBird = nullptr;
		Bird = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData LocomotionReq;
		LocomotionReq.AnimationTag = n"ClockBird";
		Player.RequestLocomotion(LocomotionReq);
	}
}