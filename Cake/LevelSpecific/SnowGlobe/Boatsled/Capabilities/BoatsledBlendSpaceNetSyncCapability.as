import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class BoatsledBlendSpaceNetSyncCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledBlendSpaceNetSync);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	UHazeSmoothSyncFloatComponent NetSmoothInput;

	FHazeAcceleratedFloat InputAccelerator;

	const float BlendInTime = 0.6f;
	const float BlendOutTime = 0.4f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);

		NetSmoothInput = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"BoatsledBlendSpaceSync");
		NetSmoothInput.NumberOfSyncsPerSecond = 5.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!BoatsledComponent.IsSledding())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float HorizontalInput = BoatsledComponent.IsAligningBeforeTunnelEnd() ? 0.f : GetAttributeVector(AttributeVectorNames::LeftStickRaw).X;
		if(HasControl() && HorizontalInput != InputAccelerator.Value)
		{
			float BlendTime = HorizontalInput == 0.f ? BlendOutTime : BlendInTime;
			NetSmoothInput.Value = InputAccelerator.AccelerateTo(HorizontalInput, BlendTime, DeltaTime);
		}

		BoatsledComponent.SleddingBlendSpaceValue = NetSmoothInput.Value;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(BoatsledComponent.IsSledding())
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParms)
	{
		BoatsledComponent.SleddingBlendSpaceValue = 0.f;
		NetSmoothInput.Value = 0.f;
	}

	// float GetBlendSpaceValue()
	// {
	// 	return -FMath::Clamp(Boatsled.MeshOffsetComponent.GetRelativeRotation().Roll / 80.f, -1.f, 1.f);
	// }
}