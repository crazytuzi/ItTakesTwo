import Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingPlayerComponent;

class UGardenSwingPlayerAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GardenSwings");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	UGardenSwingPlayerComponent SwingComp;
	AGardenSwingsActor Swings;

	UGardenSingleSwingComponent PlayerSwing;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingComp = UGardenSwingPlayerComponent::Get(Owner);

		Swings = SwingComp.Swings;
		PlayerSwing = SwingComp.CurrentSwing;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerSwing.bPlayerIsOnSwing)
			return EHazeNetworkActivation::DontActivate;
		if(!PlayerSwing.bRequestLocomotionFromPlayer)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerSwing.bRequestLocomotionFromPlayer)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazePointOfInterest POI;
		POI.FocusTarget.Actor = Player;
		POI.bMatchFocusDirection = true;
		POI.Blend = CameraBlend::Normal(5.f);
		POI.Duration = 5.f;
		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::Medium);

		Player.BlockCapabilities(n"CameraControl", Swings);
		
		
		FName SocketName;

		if(Player.IsMay())
			SocketName = n"LeftSwing";
		else
			SocketName = n"RightSwing";

		Player.AttachToComponent(Swings.GardenSwing, SocketName, EAttachmentRule::SnapToTarget);
		Player.AddLocomotionFeature(SwingComp.AnimFeature);

		if(Player.IsMay())
			Player.ActivateCamera(Swings.MaySwingCamera, CameraBlend::Normal(), Swings, EHazeCameraPriority::High);
		else
			Player.ActivateCamera(Swings.CodySwingCamera, CameraBlend::Normal(), Swings, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveLocomotionFeature(SwingComp.AnimFeature);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"SwingingMinigame";
			Player.RequestLocomotion(Request);
		}
	}
}