import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;
import Peanuts.Animation.Features.ClockWork.LocomotionFeatureClockWorkHorseDerby;

class UDerbyHorseCapability : UHazeCapability
{
	// default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"DerbyHorseCapability");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	ADerbyHorseActor HorseActor;

	UPROPERTY(Category = "Setup")
	TPerPlayer<ULocomotionFeatureClockWorkHorseDerby> RidingFeatures;
	ULocomotionFeatureClockWorkHorseDerby AnimFeature;
	FHazeRequestLocomotionData LocomotionData;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HorseActor = Cast<ADerbyHorseActor>(GetAttributeObject(n"DerbyHorseActor"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HorseActor != nullptr && IsActioning(n"HorseDerby"))
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(HorseActor == nullptr || !IsActioning(n"HorseDerby"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HorseActor.SetCapabilityActionState(n"Crouch", EHazeActionState::Inactive);
		HorseActor.SetCapabilityActionState(n"Jump", EHazeActionState::Inactive);
		HorseActor.SetCapabilityActionState(n"Hit", EHazeActionState::Inactive);
		
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);
		
		if (Player.IsMay())
			Player.BlockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		else
			Player.BlockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);

		if(Player.IsMay())
			AnimFeature = RidingFeatures[0];
		else
			AnimFeature = RidingFeatures[1];

		LocomotionData.AnimationTag = AnimFeature.Tag;
		
		Player.AddLocomotionFeature(AnimFeature);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		if (Player.IsMay())
			Player.UnblockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		else
			Player.UnblockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);

		if(AnimFeature != nullptr)
			Player.RemoveLocomotionFeature(AnimFeature);

		HorseActor.HorseState = EDerbyHorseState::Travelling;
		HorseActor = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(LocomotionData);

		if(WasActionStarted(ActionNames::MovementJump))
			HorseActor.SetCapabilityActionState(n"Jump", EHazeActionState::Active);
		else
			HorseActor.SetCapabilityActionState(n"Jump", EHazeActionState::Inactive);

		float VerticalInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y;

		if(VerticalInput < -0.2f)
			HorseActor.SetCapabilityActionState(n"Crouch", EHazeActionState::Active);
		else
			HorseActor.SetCapabilityActionState(n"Crouch", EHazeActionState::Inactive);
	}
}