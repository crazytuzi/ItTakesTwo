import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Vino.Movement.MovementSystemTags;

class UBoatsledStartLightCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledStartLight);

	default TickGroupOrder = 102;
	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	const int MarksNum = 4;
	int CurrentMark;

	float CurrentElapsedTime;

	bool bGoGoGo;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsWaitingForStartLight())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		// Focus on start light and gate
		FHazePointOfInterest PointOfInterest;
		PointOfInterest.Blend = 2.f;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.FocusTarget.WorldOffset = PlayerOwner.ActorLocation + BoatsledComponent.SplineVector * 1500.f + PlayerOwner.MovementWorldUp * 850.f;

		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);
		PlayerOwner.ApplyFieldOfView(50.f, 4.f, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentElapsedTime += DeltaTime;
		if(CurrentElapsedTime >= 1.f)
			Mark();

		BoatsledComponent.RequestPlayerBoatsledLocomotion();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bGoGoGo)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		// Activate locally since we deactivated through network
		BoatsledComponent.SetStateLocal(EBoatsledState::PushStart);

		// Fire event!
		BoatsledComponent.BoatsledEventHandler.OnGreenStartLight.Broadcast();

		// Clear camera stuff
		PlayerOwner.ClearPointOfInterestByInstigator(this);
		PlayerOwner.ClearFieldOfViewByInstigator(this);

		// Cleanup
		CurrentMark = 0;
		CurrentElapsedTime = 0.f;
		bGoGoGo = false;
	}

	void Mark()
	{
		CurrentElapsedTime = 0.f;
		if(++CurrentMark == 4)
			bGoGoGo = true;

		BoatsledComponent.BoatsledEventHandler.OnStartLightMark.Broadcast(CurrentMark);
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementAction, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::AirMovement, this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementAction, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::AirMovement, this);
	}
}