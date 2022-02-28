import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Vino.Movement.SplineLock.SplineLockComponent;
import Cake.LevelSpecific.Tree.Wasps.Movement.WaspFlyAlongSplineMovementCapability;
import Cake.LevelSpecific.Tree.Wasps.Health.WaspHealthComponent;

class UWaspBeetleRunSplineMovementCapability : UWaspFlyAlongSplineMovementCapability
{
	default TickGroupOrder = 12.f; // Must run before regular spline movement
	FHazeAcceleratedVector SapOffset;
	UWaspHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		HealthComp = UWaspHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
    		return EHazeNetworkActivation::DontActivate;
		if (BehaviourComp.MovingAlongSpline == nullptr)
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();
		if (BehaviourComp.MovingAlongSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"SplineFlying", true);
		Super::OnActivated(ActivationParams);
		SapOffset.SnapTo(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"SplineFlying", false);
		Super::OnDeactivated(DeactivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		float TargetSapOffset = HealthComp.SapMass * -200.f;
		SapOffset.AccelerateTo(FVector(0.f, 0.f, TargetSapOffset), 0.5f, DeltaSeconds); 
		Super::TickActive(DeltaSeconds);
	}

	FVector GetLocationAlongSpline(float Dist)
	{
		FVector SplineLoc = Super::GetLocationAlongSpline(Dist);
		SplineLoc += SapOffset.Value;
		return SplineLoc;
	}

	void DisableCollision()
	{
		// Do not disable collision
	}

	bool CheckCapture(const FVector& EntryLoc, float DeltaSeconds)
	{
		// Always follow spline
		return true;
	}
};
