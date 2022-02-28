import Cake.LevelSpecific.SnowGlobe.Boatsled.Boatsled;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

// This capability is attached to the boatsled and updates its SplineFollowComponent based on its location
class UBoatsledSplineFollowPositioningCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledSplineFollowPositioning);

	default TickGroup = ECapabilityTickGroups::LastMovement;

	ABoatsled BoatsledOwner;
	UBoatsledComponent PlayerBoatsledComponent;
	UHazeSplineComponent SplineComponent;
	UHazeSplineRegionContainerComponent SplineRegionContainer;

	float PreviousDistanceAlongSpline;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BoatsledOwner = Cast<ABoatsled>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BoatsledOwner.BoatsledTrack == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(BoatsledOwner.CurrentBoatsledder == nullptr)
			return EHazeNetworkActivation::DontActivate;

		UBoatsledComponent BoatsledComponent = UBoatsledComponent::Get(BoatsledOwner.CurrentBoatsledder);
		if(BoatsledComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!BoatsledComponent.IsSledding())
			return EHazeNetworkActivation::DontActivate;

		if(BoatsledComponent.IsJumping())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerBoatsledComponent = UBoatsledComponent::Get(BoatsledOwner.CurrentBoatsledder);
		SplineComponent = PlayerBoatsledComponent.TrackSpline;
		SplineRegionContainer = UHazeSplineRegionContainerComponent::Get(BoatsledOwner.BoatsledTrack);

		PreviousDistanceAlongSpline = SplineComponent.GetDistanceAlongSplineAtWorldLocation(BoatsledOwner.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Dont update regions if for some reason bobsled went a bit back on spline
		float DistanceAlongSpline = SplineComponent.GetDistanceAlongSplineAtWorldLocation(BoatsledOwner.ActorLocation);
		if(DistanceAlongSpline > PreviousDistanceAlongSpline)
			SplineRegionContainer.UpdateRegionActivity(BoatsledOwner, DistanceAlongSpline, PreviousDistanceAlongSpline, true);

		// Update previous distance
		PreviousDistanceAlongSpline = DistanceAlongSpline;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Will happen when loading next level after ride end
		if(PlayerBoatsledComponent == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SplineRegionContainer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BoatsledOwner.BoatsledTrack == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
	
		if(!PlayerBoatsledComponent.IsSledding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(PlayerBoatsledComponent.IsJumping())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerBoatsledComponent = nullptr;
		SplineComponent = nullptr;
		SplineRegionContainer = nullptr;
	}
}