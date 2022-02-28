import Cake.SlotCar.SlotCarActor;
import Cake.SlotCar.SlotCarTrackActor;
class USlotCarPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SlotCar");
	default CapabilityTags.Add(n"SlotCarInput");

	default CapabilityDebugCategory = n"SlotCar";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASlotCarActor SlotCar;
	ASlotCarTrackActor SlotCarTrack;
	UHazeSmoothSyncFloatComponent FloatSyncComp;

	float OldFloatSyncCompValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SlotCar = Cast<ASlotCarActor>(GetAttributeObject(n"SlotCarActor"));

		FloatSyncComp = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"SlotCarSync");		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SlotCarTrack == nullptr)
			SlotCarTrack = Cast<ASlotCarTrackActor>(GetAttributeObject(n"SlotCarInteraction"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SlotCar == nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		Player.SetBlendSpaceValues(0.f, 0.f, true);

		if (SlotCarTrack != nullptr)
			SlotCarTrack.GetControllerMeshForPlayer(Player).SetBlendSpaceValues(0.f, 0.f, true);

		Player.ShowCancelPrompt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		SlotCar.PlayerInput = 0.f;
		FloatSyncComp.Value = 0.f;

		Player.SetBlendSpaceValues(0.f, 0.f);
		if (SlotCarTrack != nullptr)
			SlotCarTrack.GetControllerMeshForPlayer(Player).SetBlendSpaceValues(0.f, 0.f, false);

		Player.RemoveCancelPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		OldFloatSyncCompValue = FloatSyncComp.Value;
		if (HasControl())	
		{
			FloatSyncComp.Value = GetAttributeValue(AttributeNames::PrimaryLevelAbilityAxis);
		
			if (WasActionStarted(ActionNames::Cancel) && SlotCarTrack.bEnterAnimationComplete[Player] == true)
				SlotCarTrack.NetRequestCancel(Player);
		}

		SlotCar.PlayerInput = FloatSyncComp.Value;
		Player.SetBlendSpaceValues(0.f, FloatSyncComp.Value * 100.f);

		if (SlotCarTrack != nullptr)
			SlotCarTrack.GetControllerMeshForPlayer(Player).SetBlendSpaceValues(0.f, FloatSyncComp.Value * 100.f, false);	

		// Throttle / Brake audio events
		const float ThrottleThreshold = 0.1f;
		const float BrakeThreshold = 0.5f;
		if (OldFloatSyncCompValue < ThrottleThreshold && FloatSyncComp.Value >= ThrottleThreshold)
			SlotCar.HazeAkComp.HazePostEvent(SlotCar.ThrottleEvent);
		else if (OldFloatSyncCompValue > BrakeThreshold && FloatSyncComp.Value <= BrakeThreshold)
			SlotCar.HazeAkComp.HazePostEvent(SlotCar.BrakeEvent);

		SlotCar.HazeAkComp.SetRTPCValue("Rtpc_World_Shared_SideContent_SlotCars_Load", FloatSyncComp.Value);
	}
}